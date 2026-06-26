#!/usr/bin/env bash
# init-project.sh — coder 项目初始化（bash wrapper，主实现在 init-project.py）
#
# 在用户项目生成 .claude/ 配置：
#   - agents/{lang}-coder-project.md  项目语言 agent（继承通用版）
#   - agents/project-reviewer.md      项目特定 reviewer
#   - hooks/{edit-guard,spawn-trace,session-load}.sh  强制流程 hook
#   - settings.json（智能合并 hooks）
#   - CLAUDE.md（智能合并 project-context markers）
#   - .coder-initialized.json（init 元数据）
#
# 智能合并策略（参考 oh-story-claude）：
#   - markers 之间的内容由 init 管理
#   - markers 之外的内容保留用户改动
#   - settings.json 走 JSON patch
#   - 已有文件先 backup
#
# 用法：
#   bash init-project.sh                  # 智能合并 init
#   bash init-project.sh --force          # 强制覆盖 managed section
#   bash init-project.sh --dry-run        # 只打印 diff，不写文件
#   bash init-project.sh --lang=python    # 覆盖语言检测
#   bash init-project.sh /path/to/project # 指定项目目录

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
exec python3 "$SCRIPT_DIR/init-project.py" "$@"
