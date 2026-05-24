#!/usr/bin/env bash
# mcp-probe.sh v2 — MCP 服务器可用性探测（纯 MCP 协议，跨平台）
# 用法: bash mcp-probe.sh [--tool <name>] [cache_dir]
#
# --tool <name>: 工具名（opencode|claude|cursor|trae|agents），默认 opencode
#               决定了读取哪个工具的 MCP 配置，以及缓存文件名
#
# 原理: 读取工具的 MCP 配置 → 对每个 server 发 tools/list JSON-RPC → 缓存
#       不依赖任何平台 CLI 或平台命名规范
#       结果仅标记服务器级别可用性，工具名以 AI 实际接收到的为准
#
# v2: 纯 MCP 协议探测，跨平台，无 CLI 依赖
# 支持 {file:path} 模板变量，1 小时 TTL 缓存
# SSE-Session 两阶段握手，Docker 容器预检

set -euo pipefail

# ---- 参数解析 ----
TOOL="opencode"
_ARGS=()
while [[ $# -gt 0 ]]; do
    case "$1" in
        --tool) TOOL="$2"; shift 2 ;;
        *) _ARGS+=("$1"); shift ;;
    esac
done
set -- "${_ARGS[@]+"${_ARGS[@]}"}"

# ---- 工具 → 配置文件映射 ----
case "$TOOL" in
    opencode) OPCODE_CONFIG="${OPCODE_CONFIG:-$HOME/.config/opencode/opencode.jsonc}" ;;
    claude)   OPCODE_CONFIG="${OPCODE_CONFIG:-$HOME/.claude/claude.json}" ;;
    cursor)   OPCODE_CONFIG="${OPCODE_CONFIG:-$HOME/.cursor/settings.json}" ;;
    trae)     OPCODE_CONFIG="${OPCODE_CONFIG:-$HOME/.trae/settings.json}" ;;
    agents)   OPCODE_CONFIG="${OPCODE_CONFIG:-$HOME/.agents/settings.json}" ;;
    *)        echo "WARN: 未知工具 '$TOOL'，默认 opencode" >&2
              TOOL="opencode"
              OPCODE_CONFIG="${OPCODE_CONFIG:-$HOME/.config/opencode/opencode.jsonc}" ;;
esac

CACHE_DIR="${1:-$(dirname "$0")/../data}"
CACHE_FILE="$CACHE_DIR/.mcp-cache-${TOOL}.json"
mkdir -p "$CACHE_DIR"

export CACHE_DIR CACHE_FILE OPCODE_CONFIG PROBE_TIMEOUT=12 MCP_TOOL="$TOOL"

exec python3 << 'PYEOF'
import json, hashlib, subprocess, sys, re, os, time, urllib.request, select
from pathlib import Path
from datetime import datetime, timezone
from collections import namedtuple
from contextlib import contextmanager

PostResult = namedtuple('PostResult', ['ok', 'status', 'raw', 'headers'])
_NOT_DOCKER = object()  # probe_docker_container 哨兵值，表示「非 docker 命令」
MCP_PROTOCOL_VERSION = "2024-11-05"
MCP_CLIENT_INFO = {"name": "mcp-probe", "version": "2.0"}

def _init_request(req_id=1):
    """构建 MCP initialize 请求"""
    return {
        "jsonrpc": "2.0", "id": req_id,
        "method": "initialize",
        "params": {
            "protocolVersion": MCP_PROTOCOL_VERSION,
            "capabilities": {},
            "clientInfo": MCP_CLIENT_INFO,
        },
    }

CACHE_DIR = Path(os.environ['CACHE_DIR'])
CACHE_FILE = Path(os.environ['CACHE_FILE'])
OPCODE_CONFIG = Path(os.environ['OPCODE_CONFIG'])
PROBE_TIMEOUT = int(os.environ.get("PROBE_TIMEOUT", "12"))  # shell 侧统一来源
CACHE_TTL = 3600    # 缓存有效期（秒）


def resolve_secrets(value):
    """解析字符串中任意位置的 {file:path} 模板变量"""
    if not isinstance(value, str):
        return str(value)

    def _replace(m):
        path = os.path.expanduser(m.group(1).strip())
        try:
            return Path(path).read_text().strip()
        except Exception:
            return m.group(0)  # 保留原文

    return re.sub(r'\{file:(.+?)\}', _replace, value)


def resolve_env(env_dict):
    """递归解析环境变量字典中的 {file:path}"""
    resolved = {}
    for k, v in (env_dict or {}).items():
        resolved[k] = resolve_secrets(v)
    return resolved


def resolve_headers(headers_dict):
    """解析 HTTP 请求头中的 {file:path}"""
    resolved = {
        "Content-Type": "application/json",
        "Accept": "application/json, text/event-stream",
    }
    for k, v in (headers_dict or {}).items():
        resolved[k] = resolve_secrets(v)
    return resolved


def parse_config(path):
    """解析 opencode.jsonc（去注释 + 去尾部逗号）"""

    def strip_jsonc(text):
        """去除 JSONC 注释（// 和 /* */），正确处理字符串内的特殊字符"""
        out, i, n = [], 0, len(text)
        in_str = False
        while i < n:
            c = text[i]
            if c == '"' and (i == 0 or text[i-1] != '\\'):
                in_str = not in_str
                out.append(c); i += 1
            elif not in_str and c == '/':
                if i + 1 < n and text[i+1] == '/':
                    i = text.index('\n', i) + 1 if '\n' in text[i:] else n
                elif i + 1 < n and text[i+1] == '*':
                    end = text.find('*/', i + 2)
                    i = end + 2 if end != -1 else n
                else:
                    out.append(c); i += 1
            else:
                out.append(c); i += 1
        return ''.join(out)

    txt = path.read_text()
    txt = strip_jsonc(txt)
    txt = re.sub(r',\s*}', '}', txt)     # 去尾部逗号 }
    txt = re.sub(r',\s*]', ']', txt)     # 去尾部逗号 ]
    return json.loads(txt, strict=False)


def get_config_hash(mcp_cfg):
    """MCP 配置段 hash，用于缓存失效判断"""
    raw = json.dumps(mcp_cfg, sort_keys=True, default=str)
    return hashlib.md5(raw.encode()).hexdigest()[:12]


def send_line(proc, msg):
    """向 stdio server 发送一行 JSON"""
    proc.stdin.write(json.dumps(msg) + "\n")
    proc.stdin.flush()


def recv_line(proc, timeout_s=6, expected_id=None):
    """从 stdio server 读取指定 id 的 JSON-RPC 响应（跳过通知消息和非 JSON 行）"""
    deadline = time.time() + timeout_s
    while time.time() < deadline:
        r, _, _ = select.select([proc.stdout], [], [], 0.2)
        if r:
            line = proc.stdout.readline()
            if not line:
                continue
            line = line.strip()
            if not line:
                continue
            try:
                msg = json.loads(line)
            except json.JSONDecodeError:
                continue
            # 跳过 notifications（无 id 字段）
            if "id" not in msg:
                continue
            # 跳过服务端主动发送的注册通知
            if msg.get("method") in ("notifications/initialized",):
                continue
            # 如果指定了 expected_id，跳过不匹配的响应
            if expected_id is not None and msg.get("id") != expected_id:
                continue
            return msg
    return None


@contextmanager
def _managed_proc(cmd, env):
    """子进程生命周期管理 — 退出时确保 kill"""
    proc = subprocess.Popen(
        cmd, stdin=subprocess.PIPE, stdout=subprocess.PIPE,
        stderr=subprocess.DEVNULL, env=env, text=True,
    )
    try:
        yield proc
    finally:
        try:
            proc.kill()
        except Exception:
            pass


def probe_stdio(name, cfg):
    """探测 stdio MCP server — 走完整初始化 + tools/list"""
    cmd = cfg.get("command", [])
    if not cmd:
        return False, [], "no command"

    env = os.environ.copy()
    env.update(resolve_env(cfg.get("environment", {})))

    try:
        with _managed_proc(cmd, env) as proc:
            # 1. 发 initialize
            send_line(proc, _init_request(1))

            # 2. 收 initialize 响应（id=1）
            resp = recv_line(proc, PROBE_TIMEOUT / 2, expected_id=1)
            if not resp:
                return False, [], "initialize: no response"
            if "error" in resp:
                return False, [], f"initialize: {resp['error']}"

            # 3. 发 initialized 通知
            send_line(proc, {"jsonrpc": "2.0", "method": "notifications/initialized"})

            # 4. 发 tools/list
            send_line(proc, {"jsonrpc": "2.0", "id": 2, "method": "tools/list"})

            # 5. 收 tools/list 响应（id=2）
            tools_resp = recv_line(proc, PROBE_TIMEOUT / 2, expected_id=2)
            if not tools_resp:
                return False, [], "tools/list: no response"
            if "error" in tools_resp:
                return False, [], f"tools/list: {tools_resp['error'].get('message', str(tools_resp['error']))}"
            if "result" in tools_resp:
                tools = [t["name"] for t in tools_resp["result"].get("tools", [])]
                return True, tools, None
            return False, [], "tools/list: unexpected response"

    except FileNotFoundError:
        return False, [], "command not found"
    except Exception as e:
        return False, [], str(e)[:80]


def _do_post(url, headers, body, extra_headers=None):
    """发送 POST 请求，返回 PostResult(ok, status, raw, headers)"""
    h = dict(headers)
    if extra_headers:
        h.update(extra_headers)
    req = urllib.request.Request(url, data=body, method="POST", headers=h)
    try:
        resp = urllib.request.urlopen(req, timeout=PROBE_TIMEOUT)
        return PostResult(True, resp.status, resp.read().decode(), resp.headers)
    except urllib.error.HTTPError as e:
        detail = e.read().decode()
        return PostResult(False, e.code, detail, e.headers)


def _ensure_session(url, headers, body):
    """确保存在 MCP session，返回 tools/list 请求结果。

    策略:
    1. 直接请求（标准 JSON-RPC / Streamable HTTP）
    2. 被拒则发 initialize (Accept: text/event-stream) 创建 session → 带上 session ID 重试
    """
    # 尝试 1: 标准请求
    result = _do_post(url, headers, body)
    if result.ok:
        return result

    # 尝试 2: 发 initialize 创建 session（会返回 mcp-session-id header）
    init_headers = dict(headers)
    init_headers["Accept"] = "text/event-stream"
    init_body = json.dumps(_init_request(0)).encode()

    sid = None
    init_req = urllib.request.Request(url, data=init_body, method="POST", headers=init_headers)
    try:
        init_resp = urllib.request.urlopen(init_req, timeout=PROBE_TIMEOUT)
        sid = init_resp.headers.get("mcp-session-id") or init_resp.headers.get("MCP-Session-Id")
    except urllib.error.HTTPError as e:
        sid = e.headers.get("mcp-session-id") or e.headers.get("MCP-Session-Id")

    if sid:
        retry = _do_post(url, headers, body, extra_headers={"MCP-Session-Id": sid})
        if retry.ok:
            return retry

    return result  # 全部失败，返原来结果


def _parse_sse(raw):
    """从 SSE 文本中解析 JSON messages"""
    msgs = []
    for line in raw.split("\n"):
        ls = line.strip()
        if ls.startswith("data:"):
            content = ls[5:].lstrip()
            if content:
                try:
                    msgs.append(json.loads(content))
                except json.JSONDecodeError:
                    continue
    return msgs


def probe_remote(name, cfg):
    """探测 remote MCP server — HTTP POST tools/list
    支持标准 JSON-RPC、Streamable HTTP（SSE）和 SSE-Session 三种传输"""
    url = cfg.get("url", "")
    if not url:
        return False, [], "no url"

    headers = resolve_headers(cfg.get("headers", {}))

    try:
        body = json.dumps({
            "jsonrpc": "2.0", "id": 1, "method": "tools/list",
        }).encode()

        result = _ensure_session(url, headers, body)

        if not result.ok:
            try:
                err = json.loads(result.raw).get("message", result.raw[:80])
            except json.JSONDecodeError:
                err = f"HTTP {result.status}" if result.status else result.raw[:80]
            return False, [], err

        # ---- 解析响应（JSON 或 SSE）----
        # 标准 JSON-RPC
        try:
            data = json.loads(result.raw)
            if isinstance(data.get("result"), dict) and "tools" in data["result"]:
                tools = [t["name"] for t in data["result"]["tools"]]
                return True, tools, None
            if "error" in data:
                return False, [], data["error"].get("message", str(data["error"]))
            return False, [], "unexpected response"
        except json.JSONDecodeError:
            pass

        # SSE 格式
        sse_messages = _parse_sse(result.raw)
        for msg in sse_messages:
            if isinstance(msg.get("result"), dict) and "tools" in msg["result"]:
                tools = [t["name"] for t in msg["result"]["tools"]]
                return True, tools, None
        if sse_messages:
            return False, [], "no tools/list in SSE stream"

        return False, [], "unparseable response"

    except urllib.error.URLError as e:
        return False, [], "connection failed"
    except Exception as e:
        return False, [], str(e)[:60]


def probe_docker_container(name, cfg):
    """探测已运行的 Docker container。返回 (bool, tools, err) 或 _NOT_DOCKER。"""
    cmd = cfg.get("command", [])
    if not cmd or cmd[0] != "docker":
        return _NOT_DOCKER

    container_name = None
    for i, arg in enumerate(cmd):
        if arg == "--name" and i + 1 < len(cmd):
            container_name = cmd[i + 1]
            break

    if not container_name:
        return _NOT_DOCKER

    try:
        result = subprocess.run(
            ["docker", "ps", "--filter", f"name={container_name}",
             "--format", "{{.Names}}"],
            capture_output=True, text=True, timeout=5
        )
        if result.stdout.strip() == container_name:
            print(f"  ⚡ {name}: docker container '{container_name}' 已在运行", file=sys.stderr)
            return True, ["(running container)"], None
    except Exception:
        pass

    return _NOT_DOCKER  # 未找到运行容器，让 probe_stdio 处理


def read_mcp_config():
    """读取 MCP 配置，返回 (tool_name, mcp_cfg, config_hash)"""
    mcp_tool = os.environ.get("MCP_TOOL", "opencode")
    if not OPCODE_CONFIG.exists():
        print(f"WARN: 未找到 {mcp_tool} 的 MCP 配置文件 {OPCODE_CONFIG}", file=sys.stderr)
        CACHE_FILE.write_text(json.dumps({
            "updated": datetime.now(timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ"),
            "tool": mcp_tool,
            "config_hash": "no-config",
            "servers": {}, "available_servers": [], "unavailable_servers": [],
            "count": {"total": 0, "available": 0},
            "fallback": "WebSearch + WebFetch",
        }, indent=2, ensure_ascii=False))
        sys.exit(0)
    conf = parse_config(OPCODE_CONFIG)
    mcp_cfg = conf.get("mcp", {})
    config_hash = get_config_hash(mcp_cfg)
    return mcp_tool, mcp_cfg, config_hash


def check_cache(mcp_tool, config_hash):
    """缓存命中则 exit。返回 True=命中退出，False=继续探测。"""
    if not CACHE_FILE.exists():
        return False
    try:
        cached = json.loads(CACHE_FILE.read_text())
        age = (datetime.now(timezone.utc) - datetime.fromisoformat(cached.get("updated", "2000-01-01"))).total_seconds()
        if cached.get("config_hash") == config_hash and age < CACHE_TTL:
            print(f"[{mcp_tool}] 缓存命中: {CACHE_FILE.name} ({config_hash}, {(age/60):.0f}min old)", file=sys.stderr)
            sys.exit(0)
    except Exception:
        pass
    return False


def probe_single(name, cfg):
    """探测单个 MCP server，返回服务器状态字典"""
    if not isinstance(cfg, dict):
        return {"status": "unavailable", "type": "unknown", "tools": [], "error": "invalid config"}

    cfg_type = cfg.get("type", "local")
    if cfg_type == "remote":
        ok, tools, err = probe_remote(name, cfg)
    else:
        docker_result = probe_docker_container(name, cfg)
        if docker_result is not _NOT_DOCKER:
            ok, tools, err = docker_result
        else:
            ok, tools, err = probe_stdio(name, cfg)

    result = {"type": cfg_type, "status": "available" if ok else "unavailable", "tools": tools}
    if err:
        result["error"] = err
    return result


def probe_all(mcp_cfg):
    """探测全部 MCP server"""
    return {name: probe_single(name, mcp_cfg[name]) for name in sorted(mcp_cfg.keys())}


def write_cache_and_report(mcp_tool, servers, mcp_cfg, config_hash):
    """写缓存文件 + stderr 输出摘要"""
    available = sorted(n for n, s in servers.items() if s["status"] == "available")
    cache = {
        "updated": datetime.now(timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ"),
        "tool": mcp_tool,
        "tool_config": str(OPCODE_CONFIG),
        "config_hash": config_hash,
        "servers": servers,
        "available_servers": available,
        "unavailable_servers": sorted(n for n in servers if n not in available),
        "count": {"total": len(mcp_cfg), "available": len(available)},
        "fallback": "WebSearch + WebFetch",
        "note": "服务器级别可用性。工具名以 AI 系统提示中的实际名称为准。",
    }
    CACHE_FILE.write_text(json.dumps(cache, indent=2, ensure_ascii=False))

    for name in sorted(servers.keys()):
        s = servers[name]
        icon = "✅" if s["status"] == "available" else "❌"
        detail = f" ({s['type']}, {len(s['tools'])} tools)"
        if s.get("error"):
            detail += f" — {s['error']}"
        print(f"  {icon} {name}{detail}", file=sys.stderr)
    print(f"\n缓存已写入: {CACHE_FILE}", file=sys.stderr)


def main():
    mcp_tool, mcp_cfg, config_hash = read_mcp_config()
    check_cache(mcp_tool, config_hash)

    n = len(mcp_cfg)
    print(f"[{mcp_tool}] 探测 {n} 个 MCP 服务器..." if n else f"[{mcp_tool}] 无 MCP 服务器配置", file=sys.stderr)

    servers = probe_all(mcp_cfg)
    write_cache_and_report(mcp_tool, servers, mcp_cfg, config_hash)


main()
PYEOF