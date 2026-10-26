import importlib.util
import json
from pathlib import Path
import tomllib

import pytest

ROOT = Path(__file__).resolve().parents[1]
spec = importlib.util.spec_from_file_location("sync_mcp", ROOT / "scripts" / "sync_mcp.py")
sync_mcp = importlib.util.module_from_spec(spec)
spec.loader.exec_module(sync_mcp)


INVENTORY = {
    "schema_version": 1,
    "servers": {
        "codebase-memory-mcp": {
            "transport": "stdio",
            "command": "codebase-memory-mcp",
            "args": [],
            "env": {},
        },
        "context7": {
            "transport": "http",
            "url": "https://mcp.context7.com/mcp",
            "headers": {"CONTEXT7_API_KEY": {"credential_ref": "CONTEXT7_API_KEY"}},
            "codex_header_key": "http_headers",
        },
    },
}
SECRETS = {"CONTEXT7_API_KEY": "test-key"}


def test_inventory_has_no_literal_credentials():
    text = json.dumps(INVENTORY)
    assert "test-key" not in text
    for server in INVENTORY["servers"].values():
        for value in server.get("headers", {}).values():
            assert set(value) == {"credential_ref"}


def test_render_claude_adapter_resolves_credential_refs():
    out = sync_mcp.render_server("claude", "context7", INVENTORY["servers"]["context7"], SECRETS)
    assert out == {
        "type": "http",
        "url": "https://mcp.context7.com/mcp",
        "headers": {"CONTEXT7_API_KEY": "test-key"},
    }


def test_render_codex_adapter_preserves_source_header_style():
    out = sync_mcp.render_server("codex", "context7", INVENTORY["servers"]["context7"], SECRETS)
    assert out["http_headers"] == {"CONTEXT7_API_KEY": "test-key"}
    assert "headers" not in out


def test_missing_credential_ref_fails_closed():
    with pytest.raises(sync_mcp.MissingCredential):
        sync_mcp.render_server("claude", "context7", INVENTORY["servers"]["context7"], {})


def test_semantic_equality_ignores_compatible_type_and_header_key_spelling():
    live_codex = {
        "http_headers": {"CONTEXT7_API_KEY": "test-key"},
        "url": "https://mcp.context7.com/mcp",
    }
    generated = sync_mcp.render_server("codex", "context7", INVENTORY["servers"]["context7"], SECRETS)
    assert sync_mcp.semantic_server("codex", live_codex) == sync_mcp.semantic_server("codex", generated)


def test_update_json_preserves_non_mcp_state(tmp_path):
    p = tmp_path / "claude.json"
    p.write_text(json.dumps({"mcpServers": {}, "projects": {"keep": True}}))
    generated = sync_mcp.render_inventory("claude", INVENTORY, SECRETS)
    sync_mcp.update_json(p, INVENTORY, generated)
    data = json.loads(p.read_text())
    assert set(data["mcpServers"]) == {"codebase-memory-mcp", "context7"}
    assert data["projects"] == {"keep": True}
    assert not list(tmp_path.glob("*.tmp"))


def test_update_toml_preserves_non_mcp_tables(tmp_path):
    p = tmp_path / "config.toml"
    p.write_text('[model_providers.custom]\nname = "keep"\n\n[mcp_servers.old]\ncommand = "old"\n')
    generated = sync_mcp.render_inventory("codex", INVENTORY, SECRETS)
    sync_mcp.update_toml(p, INVENTORY, generated)
    data = tomllib.loads(p.read_text())
    assert data["model_providers"]["custom"]["name"] == "keep"
    assert {"codebase-memory-mcp", "context7", "old"} <= set(data["mcp_servers"])


def test_update_json_preserves_unmanaged_servers(tmp_path):
    p = tmp_path / "claude.json"
    p.write_text(json.dumps({"mcpServers": {"node_repl": {"command": "host-only"}}, "other": 1}))
    generated = sync_mcp.render_inventory("claude", INVENTORY, SECRETS)
    sync_mcp.update_json(p, INVENTORY, generated)
    data = json.loads(p.read_text())
    assert data["mcpServers"]["node_repl"] == {"command": "host-only"}
    assert "codebase-memory-mcp" in data["mcpServers"]


def test_update_toml_preserves_unmanaged_servers(tmp_path):
    p = tmp_path / "config.toml"
    p.write_text('[mcp_servers.node_repl]\ncommand = "host-only"\n')
    generated = sync_mcp.render_inventory("codex", INVENTORY, SECRETS)
    sync_mcp.update_toml(p, INVENTORY, generated)
    data = tomllib.loads(p.read_text())
    assert data["mcp_servers"]["node_repl"] == {"command": "host-only"}
    assert "context7" in data["mcp_servers"]


def test_live_servers_parses_codex_toml(tmp_path):
    p = tmp_path / "config.toml"
    p.write_text('[mcp_servers.context7]\nurl = "https://example.test/mcp"\n')
    assert sync_mcp.live_servers("codex", p)["context7"]["url"] == "https://example.test/mcp"
