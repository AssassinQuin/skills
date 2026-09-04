#!/usr/bin/env bash
# deploy.sh — 全局 skill 部署审计：symlink 拓扑 / 断链 / 自引用环
# 原则（用户 2026-09-04 拍板）：全局 skill 统一在本 repo 维护，各处以软链接消费；项目 skill 留在项目 repo
# 退出: 0 正常；1 发现断链/自引用环；2 用法错误
set -u
REPO="$(cd "$(dirname "$0")/.." && pwd)"
DEPLOYED="${HOME}/.claude/skills"
FAIL=0

echo "═══ Skill 部署审计 ═══"
echo "实体源: $REPO"
echo ""

echo "─── 部署入口 ───"
if [ -L "$DEPLOYED" ]; then
  TARGET=$(readlink "$DEPLOYED")
  if [ "$TARGET" = "$REPO" ]; then
    echo "  ✓ $DEPLOYED → ${REPO}（symlink 直连，单实体源）"
  else
    echo "  ⚠ $DEPLOYED → ${TARGET}（指向非本 repo！预期 ${REPO}）"
    FAIL=1
  fi
elif [ -d "$DEPLOYED" ] && [ "$(cd "$DEPLOYED" && pwd -P)" = "$REPO" ]; then
  echo "  ✓ $DEPLOYED 与 repo 同一存储（hardlink/同 inode）"
else
  echo "  ⚠ $DEPLOYED 是独立目录（非链接）——存在双实体漂移风险"
fi
echo ""

echo "─── repo 内指向外部的 symlink（项目 skill 依赖，正常形态）───"
EXT=0
for d in "$REPO"/*/; do
  [ -L "${d%/}" ] || continue
  NAME="${d%/}"; NAME="${NAME##*/}"
  LINK=$(readlink "${d%/}")
  if [ -e "${d%/}" ]; then
    echo "  → ${NAME} → $LINK"
  else
    echo "  ✗ ${NAME} → $LINK （断链！）"
    FAIL=1
  fi
  EXT=$((EXT+1))
done
[ "$EXT" -eq 0 ] && echo "  （无外部依赖）"
echo ""

echo "─── SKILL.md 完整性（实体 skill 目录缺 SKILL.md = 哑目录）───"
MISS=0
for d in "$REPO"/*/; do
  [ -d "$d" ] || continue
  [ -L "${d%/}" ] && continue  # symlink 已在上节审计
  case "${d%/}" in
    */scripts|*/reports|*/datastore|*/data|*/dockerfile|*/docs|*/node_modules) continue ;;  # 功能目录非 skill
  esac
  [ -f "$d/SKILL.md" ] || { echo "  ✗ ${d%/}/ 缺 SKILL.md"; MISS=$((MISS+1)); FAIL=1; }
done
[ "$MISS" -eq 0 ] && echo "  ✓ 全部完整"
echo ""

if [ "$FAIL" -eq 0 ]; then
  echo "结论: 部署健康（单实体源 + symlink 分发）"
else
  echo "结论: 发现问题（见 ✗ 行），exit 1"
fi
exit $FAIL
