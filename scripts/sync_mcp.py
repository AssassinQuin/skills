#!/usr/bin/env python
"""Generate Claude/Codex/Trae MCP adapters from one redacted inventory.

The inventory never stores credentials.  Credential values live in a local,
0600 secrets file and are referenced by ``credential_ref``.
"""
from __future__ import annotations

import argparse
import datetime as dt
import json
import os
import tempfile
import tomllib
from pathlib import Path
from typing import Any

import tomlkit


HOME = Path.home()
REPO = Path(__file__).resolve().parents[1]
INVENTORY_PATH = REPO / "config" / "mcp" / "inventory.json"
SECRETS_PATH = Path(
    os.environ.get("AGENT_STACK_SECRETS_FILE", HOME / ".config/agent-stack/mcp-secrets.json")
)
TARGETS = {
    "claude": HOME / ".claude.json",
    "codex": HOME / ".codex/config.toml",
    "trae": HOME / "Library/Application Support/Trae/User/mcp.json",
}
CODEX_SERVER_KEY = "mcp_servers"
JSON_SERVER_KEY = "mcpServers"


class MissingCredential(Exception):
    pass


def load_json(path: Path) -> dict[str, Any]:
    with path.open(encoding="utf-8") as f:
        return json.load(f)


def dump_json_atomic(path: Path, data: dict[str, Any]) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    old_mode = path.stat().st_mode & 0o777 if path.exists() else 0o600
    fd, name = tempfile.mkstemp(prefix=f".{path.name}.", dir=path.parent)
    try:
        with os.fdopen(fd, "w", encoding="utf-8") as f:
            json.dump(data, f, ensure_ascii=False, indent=2)
            f.write("\n")
        os.chmod(name, old_mode)
        os.replace(name, path)
    except Exception:
        try:
            os.unlink(name)
        except FileNotFoundError:
            pass
        raise


def resolve_header(header: Any, secrets: dict[str, str]) -> str:
    if isinstance(header, dict):
        if set(header) != {"credential_ref"}:
            raise ValueError(f"credential header must contain only credential_ref: {header!r}")
        ref = header["credential_ref"]
        if ref not in secrets:
            raise MissingCredential(ref)
        return secrets[ref]
    if not isinstance(header, str):
        raise ValueError(f"credential header must be a credential_ref, got {type(header).__name__}")
    raise ValueError("inventory credentials must use credential_ref, not literal values")


def render_server(client: str, name: str, server: dict[str, Any], secrets: dict[str, str]) -> dict[str, Any]:
    transport = server["transport"]
    if transport == "stdio":
        out: dict[str, Any] = {
            "type": "stdio",
            "command": server["command"],
            "args": server.get("args", []),
        }
        env = server.get("env", {})
        if env:
            out["env"] = env
        return out
    if transport == "http":
        headers = {
            key: resolve_header(value, secrets)
            for key, value in server.get("headers", {}).items()
        }
        out = {"type": "http", "url": server["url"]}
        if client == "codex":
            out[server.get("codex_header_key", "headers")] = headers
        elif headers:
            out["headers"] = headers
        return out
    raise ValueError(f"unsupported transport for {name}: {transport}")


def render_inventory(client: str, inventory: dict[str, Any], secrets: dict[str, str]) -> dict[str, Any]:
    return {
        name: render_server(client, name, server, secrets)
        for name, server in inventory["servers"].items()
    }


def semantic_server(client: str, server: dict[str, Any]) -> tuple[Any, ...]:
    if server.get("type") == "http" or "url" in server:
        headers = server.get("headers", {})
        if client == "codex":
            headers = server.get("headers") or server.get("http_headers") or {}
        return ("http", server["url"], headers)
    return ("stdio", server["command"], server.get("args", []), server.get("env", {}))


def live_servers(client: str, path: Path) -> dict[str, Any]:
    if client == "codex":
        with path.open("rb") as f:
            return tomllib.load(f).get(CODEX_SERVER_KEY, {})
    data = load_json(path)
    return data.get(JSON_SERVER_KEY, {})


def update_json(path: Path, inventory: dict[str, Any], generated: dict[str, Any]) -> None:
    data = load_json(path)
    servers = data.setdefault(JSON_SERVER_KEY, {})
    servers.update(generated)
    # Preserve unmanaged/host-only servers such as Codex desktop node_repl.
    data[JSON_SERVER_KEY] = servers
    dump_json_atomic(path, data)


def update_toml(path: Path, inventory: dict[str, Any], generated: dict[str, Any]) -> None:
    with path.open(encoding="utf-8") as f:
        doc = tomlkit.parse(f.read())
    servers = doc.get(CODEX_SERVER_KEY)
    if servers is None:
        servers = tomlkit.table()
    for name, value in generated.items():
        servers[name] = value
    doc[CODEX_SERVER_KEY] = servers
    text = tomlkit.dumps(doc)
    path.parent.mkdir(parents=True, exist_ok=True)
    old_mode = path.stat().st_mode & 0o777 if path.exists() else 0o600
    fd, name = tempfile.mkstemp(prefix=f".{path.name}.", dir=path.parent)
    try:
        with os.fdopen(fd, "w", encoding="utf-8") as f:
            f.write(text)
        os.chmod(name, old_mode)
        os.replace(name, path)
    except Exception:
        try:
            os.unlink(name)
        except FileNotFoundError:
            pass
        raise


def assert_inventory_redacted(inventory: dict[str, Any]) -> None:
    for name, server in inventory["servers"].items():
        if server["transport"] != "http":
            continue
        for key, value in server.get("headers", {}).items():
            if not (isinstance(value, dict) and set(value) == {"credential_ref"}):
                raise ValueError(f"{name}.{key} must use credential_ref")


def backup(path: Path, stamp: str) -> Path:
    root = Path(os.environ.get("AGENT_STACK_BACKUP_ROOT", HOME / "backups"))
    out = root / f"mcp-sync-{stamp}" / path.relative_to(HOME)
    out.parent.mkdir(parents=True, mode=0o700, exist_ok=True)
    if path.exists():
        data = path.read_bytes()
        out.write_bytes(data)
        os.chmod(out.parent, 0o700)
        os.chmod(out, 0o600)
    return out


def check(inventory: dict[str, Any], secrets: dict[str, str]) -> list[str]:
    errors: list[str] = []
    for client, path in TARGETS.items():
        generated = render_inventory(client, inventory, secrets)
        live = live_servers(client, path)
        for name, server in inventory["servers"].items():
            if name not in live:
                errors.append(f"{client}/{name}: missing")
            elif semantic_server(client, live[name]) != semantic_server(client, generated[name]):
                errors.append(f"{client}/{name}: differs")
    return errors


def bootstrap_secrets(inventory: dict[str, Any], source_path: Path) -> None:
    source = live_servers("codex", source_path)
    fallbacks = [live_servers("claude", TARGETS["claude"]), live_servers("trae", TARGETS["trae"])]
    secrets: dict[str, str] = load_json(SECRETS_PATH) if SECRETS_PATH.exists() else {}
    found: list[str] = []
    for name, server in inventory["servers"].items():
        for header_name, spec in server.get("headers", {}).items():
            ref = spec["credential_ref"]
            if ref in secrets:
                continue
            candidates = [source.get(name, {})]
            candidates.extend(app.get(name, {}) for app in fallbacks)
            for candidate in candidates:
                value = candidate.get("headers", {}).get(header_name) or candidate.get(
                    "http_headers", {}
                ).get(header_name)
                if isinstance(value, str) and value:
                    secrets[ref] = value
                    found.append(ref)
                    break
    SECRETS_PATH.parent.mkdir(parents=True, mode=0o700, exist_ok=True)
    dump_json_atomic(SECRETS_PATH, secrets)
    os.chmod(SECRETS_PATH, 0o600)
    print(f"bootstrap complete; resolved={len(found)}; refs={','.join(found) if found else 'none'}")


def main() -> int:
    global SECRETS_PATH
    parser = argparse.ArgumentParser()
    parser.add_argument("--check", action="store_true", help="compare inventory with live adapters")
    parser.add_argument("--apply", action="store_true", help="write managed adapters")
    parser.add_argument("--bootstrap-secrets", action="store_true", help="seed missing credential refs from live configs")
    parser.add_argument("--inventory", type=Path, default=INVENTORY_PATH)
    parser.add_argument("--secrets", type=Path, default=SECRETS_PATH)
    args = parser.parse_args()

    SECRETS_PATH = args.secrets
    inventory = load_json(args.inventory)
    assert_inventory_redacted(inventory)

    if args.bootstrap_secrets:
        bootstrap_secrets(inventory, TARGETS["codex"])
        return 0

    if not SECRETS_PATH.exists():
        print(f"missing secrets file: {SECRETS_PATH}", file=__import__("sys").stderr)
        print("run: sync_mcp.py --bootstrap-secrets", file=__import__("sys").stderr)
        return 2
    secrets = load_json(SECRETS_PATH)

    if args.check:
        errors = check(inventory, secrets)
        if errors:
            print("MCP drift:")
            print("\n".join(f"- {e}" for e in errors))
            return 1
        print(f"PASS: {len(inventory['servers'])} managed MCP servers match Claude/Codex/Trae")
        return 0

    if args.apply:
        stamp = dt.datetime.now().strftime("%Y%m%d-%H%M%S")
        for client, path in TARGETS.items():
            backup(path, stamp)
            generated = render_inventory(client, inventory, secrets)
            if client == "codex":
                update_toml(path, inventory, generated)
            else:
                update_json(path, inventory, generated)
            print(f"updated {client}: {path}")
        errors = check(inventory, secrets)
        if errors:
            print("\n".join(errors), file=__import__("sys").stderr)
            return 1
        print("PASS: post-apply check")
        return 0

    parser.print_help()
    return 2


if __name__ == "__main__":
    raise SystemExit(main())
