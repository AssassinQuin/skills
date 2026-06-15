#!/usr/bin/env bash
# setup-agents.sh — 统一管理 skill agents → ~/.claude/agents/ 的反向 symlink
# 用法:
#   bash setup-agents.sh          # 同步所有 skill agents
#   bash setup-agents.sh --check  # 只检查，不修改
#   bash setup-agents.sh --clean  # 同步 + 删除孤立 symlink
#
# 原理: 扫描 skills/agents/*.md → 在 ~/.claude/agents/ 创建同名 symlink
#       真正的文件统一放在 skills/agents/，全局通过 symlink 发现
#       设计：subagent 是全局基础设施，不属于任何 skill，跟 skill 解耦

set -euo pipefail

SKILLS_DIR="$(cd "$(dirname "$0")/.." && pwd -P)"
AGENTS_DIR="$HOME/.claude/agents"
MODE="${1:-sync}"

RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[0;33m'; CYAN='\033[0;36m'; NC='\033[0m'
created=0; updated=0; skipped=0; orphaned=0

mkdir -p "$AGENTS_DIR"

echo -e "${CYAN}扫描 skills/agents/*.md ...${NC}"

skill_agents=()
while IFS= read -r -d '' file; do
    skill_agents+=("$file")
done < <(find "$SKILLS_DIR/agents" -maxdepth 1 -name '*.md' -print0 2>/dev/null | sort -z)

if [ ${#skill_agents[@]} -eq 0 ]; then
    echo -e "${YELLOW}未找到任何 skill agent 文件${NC}"
    exit 0
fi

for src_file in "${skill_agents[@]}"; do
    name="$(basename "$src_file")"
    link="$AGENTS_DIR/$name"

    # 解析 frontmatter name（去掉 .md 后缀比较）
    fm_name=$(grep '^name:' "$src_file" | head -1 | sed 's/name: *//' | tr -d '"' | tr -d "'")
    bare_name="${name%.md}"
    if [ "$fm_name" != "$bare_name" ] && [ -n "$fm_name" ]; then
        echo -e "${YELLOW}⚠️  ${name}: frontmatter name='${fm_name}' != filename '${bare_name}'${NC}"
    fi

    if [ ! -e "$link" ]; then
        if [ "$MODE" = "--check" ]; then
            echo -e "${RED}MISSING${NC}  $name ← ${src_file#$SKILLS_DIR/}"
            ((created++)) || true
        else
            ln -sf "$src_file" "$link"
            echo -e "${GREEN}✅ CREATED${NC} $name ← ${src_file#$SKILLS_DIR/}"
            ((created++)) || true
        fi
    elif [ -L "$link" ]; then
        current_target="$(readlink "$link")"
        if [ "$current_target" != "$src_file" ]; then
            if [ "$MODE" = "--check" ]; then
                echo -e "${YELLOW}STALE${NC}     $name (→$(readlink "$link" | sed "s|$SKILLS_DIR/||"), 应→${src_file#$SKILLS_DIR/})"
                ((updated++)) || true
            else
                ln -sf "$src_file" "$link"
                echo -e "${YELLOW}🔄 UPDATED${NC} $name ← ${src_file#$SKILLS_DIR/}"
                ((updated++)) || true
            fi
        else
            echo -e "   ${GREEN}ok${NC}       $name"
            ((skipped++)) || true
        fi
    else
        echo -e "${RED}❌ CONFLICT${NC} $name — $link 是真实文件，非 symlink"
    fi
done

echo ""
echo -e "${CYAN}检查孤立 symlink ...${NC}"
for link in "$AGENTS_DIR"/*.md; do
    [ ! -f "$link" ] && continue
    [ ! -L "$link" ] && continue
    target="$(readlink "$link")"
    if [ ! -f "$target" ]; then
        if [ "$MODE" != "--check" ]; then
            rm "$link"
            echo -e "${RED}🗑  REMOVED${NC} $(basename "$link") — 源已删除"
        else
            echo -e "${RED}ORPHAN${NC}   $(basename "$link") — 源已删除"
        fi
        ((orphaned++)) || true
    fi
done

echo ""
echo -e "${CYAN}─── Summary ───${NC}"
echo "  Agents: ${#skill_agents[@]} found | $created created | $updated updated | $skipped ok | $orphaned orphaned"
