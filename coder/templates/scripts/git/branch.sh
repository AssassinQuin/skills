#!/usr/bin/env bash
# branch.sh — 项目级 git 分支管理统一入口
#
# 由 coder init 生成。强制分支命名规范 + 安全检查 + experiment 备份。
#
# Usage:
#   bash branch.sh new <type> <slug> [--from <base>]   # 创建分支
#   bash branch.sh switch <name>                       # 安全切换
#   bash branch.sh merge <branch> [--no-ff|--squash]   # 合并（默认 --no-ff）
#   bash branch.sh cleanup [--remote]                  # 清理已合并分支
#   bash branch.sh status                              # 分支健康检查
#   bash branch.sh save <label>                        # 备份当前状态（branch + tag + stash）
#   bash branch.sh restore <label>                     # 从备份恢复
#   bash branch.sh list                                # 列出所有分支（含未合并）
#
# Branch types: feature / fix / hotfix / release / experiment
# Naming: {type}/{issue-id-or-version}-{slug}
#   例: feature/PROJ-123-add-login
#       fix/456-null-pointer
#       hotfix/security-patch
#       release/v2.0
#       experiment/try-new-lib

set -euo pipefail

# ---- helpers ----
red()    { printf '\033[31m%s\033[0m\n' "$*"; }
yellow() { printf '\033[33m%s\033[0m\n' "$*"; }
green()  { printf '\033[32m%s\033[0m\n' "$*"; }
gray()   { printf '\033[90m%s\033[0m\n' "$*"; }

die() { red "ERROR: $*" >&2; exit 1; }
warn() { yellow "WARN: $*" >&2; }
info() { printf '%s\n' "$*"; }

require_clean_worktree() {
  if ! git diff --quiet || ! git diff --cached --quiet; then
    die "工作区有未提交改动。请先 commit / stash / discard。
  当前 diff:
$(git status --short | head -20)"
  fi
}

current_branch() { git rev-parse --abbrev-ref HEAD; }

ensure_git_repo() {
  git rev-parse --git-dir > /dev/null 2>&1 || die "不在 git 仓库里（$(pwd)）"
}

validate_branch_type() {
  local t="$1"
  case "$t" in
    feature|fix|hotfix|release|experiment) return 0 ;;
    *) die "无效分支类型: ${t}。可用: feature / fix / hotfix / release / experiment" ;;
  esac
}

# ---- subcommands ----

cmd_new() {
  [[ $# -ge 2 ]] || die "Usage: branch.sh new <type> <slug> [--from <base>]"
  local type="$1" slug="$2"; shift 2
  validate_branch_type "$type"

  local base=""
  while [[ $# -gt 0 ]]; do
    case "$1" in
      --from) base="$2"; shift 2 ;;
      *) die "未知参数: $1" ;;
    esac
  done

  # 默认 base：main 或 master
  if [[ -z "$base" ]]; then
    if git show-ref --verify --quiet refs/heads/main; then base="main"
    elif git show-ref --verify --quiet refs/heads/master; then base="master"
    else die "找不到 main / master，请用 --from 指定 base"
    fi
  fi

  local branch="${type}/${slug}"
  if git show-ref --verify --quiet refs/heads/"$branch"; then
    die "分支已存在: $branch"
  fi

  require_clean_worktree

  info "→ 从 $base 创建 $branch"
  git fetch origin "$base" 2>/dev/null || true
  git checkout -b "$branch" "$base"
  green "✅ 已创建并切到 ${branch}（基于 ${base}）"
}

cmd_switch() {
  [[ $# -ge 1 ]] || die "Usage: branch.sh switch <name>"
  local target="$1"

  require_clean_worktree

  # 如果是简写（如 123），尝试匹配 feature/* fix/* 等
  if ! git show-ref --verify --quiet refs/heads/"$target"; then
    local matches=()
    for t in feature fix hotfix release experiment; do
      if git show-ref --verify --quiet refs/heads/"$t/$target"; then
        matches+=("$t/$target")
      fi
    done
    # 模糊匹配（slug contains）
    if [[ ${#matches[@]} -eq 0 ]]; then
      while IFS= read -r line; do
        [[ "$line" == *"$target"* ]] && matches+=("$line")
      done < <(git branch --format='%(refname:short)')
    fi
    if [[ ${#matches[@]} -eq 1 ]]; then
      target="${matches[0]}"
    elif [[ ${#matches[@]} -gt 1 ]]; then
      die "多个分支匹配 '$target':\n$(printf '  %s\n' "${matches[@]}")\n请用完整名字"
    fi
  fi

  git checkout "$target"
  green "✅ 切到 $target"
}

cmd_merge() {
  [[ $# -ge 1 ]] || die "Usage: branch.sh merge <branch> [--no-ff|--squash]"
  local source="$1"; shift
  local mode="--no-ff"  # 默认保留 merge commit
  while [[ $# -gt 0 ]]; do
    case "$1" in
      --no-ff) mode="--no-ff"; shift ;;
      --squash) mode="--squash"; shift ;;
      --ff-only) mode="--ff-only"; shift ;;
      *) die "未知参数: $1" ;;
    esac
  done

  require_clean_worktree

  local target; target=$(current_branch)
  if [[ "$target" == "main" || "$target" == "master" ]]; then
    warn "⚠️ 当前在 $target 上，合并到主干。建议先切到测试分支。"
    printf "继续？[y/N] " && read -r ans
    [[ "$ans" == "y" || "$ans" == "Y" ]] || die "已取消"
  fi

  git show-ref --verify --quiet refs/heads/"$source" || die "源分支不存在: $source"

  # 检查 source 是否已合并
  if git merge-base --is-ancestor "$source" HEAD; then
    warn "$source 已经在 $target 的历史里（已合并或 fast-forward）。"
  fi

  info "→ 合并 $source 到 ${target}（${mode}）"
  git merge $mode "$source" || {
    red "❌ 合并冲突！请手动解决：
  git status
  # 编辑冲突文件
  git add <files>
  git commit
  # 或放弃合并: git merge --abort"
    exit 1
  }
  green "✅ 合并完成：$source → $target"
}

cmd_cleanup() {
  local include_remote=false
  [[ "${1:-}" == "--remote" ]] && include_remote=true

  local target_base
  if git show-ref --verify --quiet refs/heads/main; then target_base="main"
  else target_base="master"; fi

  info "→ 清理已合并到 $target_base 的本地分支..."
  local cleaned=0
  while IFS= read -r branch; do
    [[ -z "$branch" ]] && continue
    [[ "$branch" == "$target_base" || "$branch" == "main" || "$branch" == "master" || "$branch" == "develop" ]] && continue
    if git merge-base --is-ancestor "$branch" "$target_base" 2>/dev/null; then
      printf "  删除 %s? [y/N] " "$branch" && read -r ans </dev/tty
      if [[ "$ans" == "y" || "$ans" == "Y" ]]; then
        git branch -d "$branch"
        green "  ✅ 已删除 $branch"
        cleaned=$((cleaned + 1))
      fi
    fi
  done < <(git branch --format='%(refname:short)')

  if $include_remote; then
    info "→ 清理已合并的 remote 分支（git fetch --prune）..."
    git fetch --prune
    green "  ✅ remote 引用已同步"
  fi

  if [[ $cleaned -eq 0 ]]; then
    gray "  没有已合并的本地分支可清理"
  fi
}

cmd_status() {
  local target_base
  if git show-ref --verify --quiet refs/heads/main; then target_base="main"
  else target_base="master"; fi

  info "📊 Git 分支健康检查"
  printf "  当前: %s\n" "$(current_branch)"
  printf "  主干: %s\n\n" "$target_base"

  printf "  %s\n" "本地分支（与 $target_base 的关系）："
  while IFS= read -r branch; do
    [[ -z "$branch" ]] && continue
    [[ "$branch" == "$target_base" ]] && { printf "  * %s (主干)\n" "$branch"; continue; }
    local ahead=0 behind=0 merged="🔴"
    if git merge-base --is-ancestor "$branch" "$target_base" 2>/dev/null; then
      merged="🟢 已合并"
    else
      ahead=$(git rev-list --count "$target_base".."$branch" 2>/dev/null || echo 0)
      behind=$(git rev-list --count "$branch".."$target_base" 2>/dev/null || echo 0)
      if [[ $ahead -gt 0 && $behind -eq 0 ]]; then
        merged="🟡 ahead $ahead"
      elif [[ $ahead -gt 0 && $behind -gt 0 ]]; then
        merged="🟠 ahead $ahead / behind $behind"
      elif [[ $ahead -eq 0 && $behind -gt 0 ]]; then
        merged="⚪ behind ${behind}（需 rebase/merge）"
      fi
    fi
    printf "    %-40s %s\n" "$branch" "$merged"
  done < <(git branch --format='%(refname:short)')
  echo

  # 未提交改动
  if ! git diff --quiet || ! git diff --cached --quiet; then
    yellow "  ⚠️ 工作区有未提交改动："
    git status --short | head -10 | sed 's/^/    /'
    echo
  fi

  # stash
  local stash_count; stash_count=$(git stash list | wc -l | tr -d ' ')
  if [[ $stash_count -gt 0 ]]; then
    gray "  📦 stash: $stash_count 条"
  fi
}

cmd_save() {
  [[ $# -ge 1 ]] || die "Usage: branch.sh save <label>"
  local label="$1"
  local ts; ts=$(date +%Y%m%d-%H%M%S)
  local branch; branch=$(current_branch)
  local backup_tag="backup/${branch}/${label}-${ts}"

  info "→ 创建备份标签: $backup_tag"
  git tag -a "$backup_tag" -m "backup before experiment: $label" || die "tag 创建失败"

  # 同时 stash 未提交改动（如果有的话）
  if ! git diff --quiet || ! git diff --cached --quiet; then
    local stash_name="backup/${branch}/${label}-${ts}"
    git stash push -u -m "$stash_name" > /dev/null
    green "  ✅ 未提交改动已 stash: $stash_name"
  fi

  green "✅ 备份完成: $backup_tag"
  gray "  恢复: bash branch.sh restore ${label}"
  gray "  列出所有备份: git tag -l 'backup/${branch}/*'"
  gray "  删除备份: git tag -d $backup_tag"
}

cmd_restore() {
  [[ $# -ge 1 ]] || die "Usage: branch.sh restore <label>"
  local label="$1"
  local branch; branch=$(current_branch)

  # 模糊匹配 backup tag
  local pattern="backup/${branch}/${label}*"
  local matches=()
  while IFS= read -r tag; do
    [[ -n "$tag" ]] && matches+=("$tag")
  done < <(git tag -l "$pattern")

  if [[ ${#matches[@]} -eq 0 ]]; then
    die "找不到匹配 '$label' 的备份（pattern: ${pattern}）"
  elif [[ ${#matches[@]} -gt 1 ]]; then
    die "多个备份匹配 '$label':\n$(printf '  %s\n' "${matches[@]}")\n请用更精确的 label"
  fi

  local tag="${matches[0]}"

  require_clean_worktree

  warn "⚠️ 这会 reset 当前分支到 ${tag}（覆盖当前 commits）"
  printf "继续？[y/N] " && read -r ans
  [[ "$ans" == "y" || "$ans" == "Y" ]] || die "已取消"

  git reset --hard "$tag"
  green "✅ 已恢复到 $tag"

  # 恢复对应的 stash
  local stash_pattern="backup/${branch}/${label}"
  local stash_ref; stash_ref=$(git stash list | grep -F "$stash_pattern" | head -1 | cut -d: -f1)
  if [[ -n "$stash_ref" ]]; then
    printf "找到对应 stash %s，恢复？[y/N] " "$stash_ref" && read -r ans </dev/tty
    if [[ "$ans" == "y" || "$ans" == "Y" ]]; then
      git stash pop "$stash_ref"
      green "  ✅ stash 已恢复"
    fi
  fi
}

cmd_list() {
  local target_base
  if git show-ref --verify --quiet refs/heads/main; then target_base="main"
  else target_base="master"; fi

  info "📂 所有本地分支"
  while IFS= read -r branch; do
    [[ -z "$branch" ]] && continue
    local marker=" "
    [[ "$branch" == "$(current_branch)" ]] && marker="*"
    local merged=""
    git merge-base --is-ancestor "$branch" "$target_base" 2>/dev/null && merged=" (merged)"
    printf "  %s %s%s\n" "$marker" "$branch" "$merged"
  done < <(git branch --format='%(refname:short)')

  echo
  info "🏷️ 备份 tags（backup/*）"
  local backup_count; backup_count=$(git tag -l 'backup/*' | wc -l | tr -d ' ')
  if [[ $backup_count -gt 0 ]]; then
    git tag -l 'backup/*' | head -10 | sed 's/^/  /'
    [[ $backup_count -gt 10 ]] && gray "  ...（共 $backup_count 个，仅显示前 10）"
  else
    gray "  （无备份）"
  fi
}

# ---- main ----

main() {
  ensure_git_repo

  [[ $# -ge 1 ]] || {
    cat <<'EOF'
Usage: branch.sh <command> [args...]

Commands:
  new <type> <slug> [--from <base>]   创建分支（type: feature/fix/hotfix/release/experiment）
  switch <name>                       安全切换（支持简写 / 模糊匹配）
  merge <branch> [--no-ff|--squash]   合并分支（默认 --no-ff 保留 history）
  cleanup [--remote]                  清理已合并分支
  status                              分支健康检查
  save <label>                        备份当前状态（tag + stash）
  restore <label>                     从备份恢复
  list                                列出所有分支 + 备份

Branch naming: {type}/{slug}
  feature/PROJ-123-add-login
  fix/456-null-pointer
  hotfix/security-patch
  release/v2.0
  experiment/try-new-lib
EOF
    exit 0
  }

  local cmd="$1"; shift
  case "$cmd" in
    new) cmd_new "$@" ;;
    switch) cmd_switch "$@" ;;
    merge) cmd_merge "$@" ;;
    cleanup) cmd_cleanup "$@" ;;
    status) cmd_status "$@" ;;
    save) cmd_save "$@" ;;
    restore) cmd_restore "$@" ;;
    list) cmd_list "$@" ;;
    -h|--help|help) main ;;
    *) die "未知命令: ${cmd}（用 --help 查看）" ;;
  esac
}

main "$@"
