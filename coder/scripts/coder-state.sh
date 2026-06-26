#!/usr/bin/env bash
# coder-state.sh — v6.0 跨 session 状态管理（bash wrapper）
# 主实现在 coder-state.py
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
exec python3 "$SCRIPT_DIR/coder-state.py" "$@"
