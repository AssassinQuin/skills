#!/usr/bin/env bash
# github-search.sh — GitHub lane 的 gh CLI 搜索入口
# 用法: github-search.sh "<query>" [repos|issues|code] [limit]
# 说明: 输出 {"kind":"...","results":[...]}；GitHub 认证与凭证全部交给 gh keyring 管理。
set -euo pipefail

query="${1:-}"
kind="${2:-repos}"
limit="${3:-10}"
usage() { echo "usage: github-search.sh <query> [repos|issues|code] [limit]" >&2; exit 2; }
[ -n "$query" ] || usage
case "$kind" in repos|issues|code) ;; *) usage ;; esac
case "$limit" in ''|*[!0-9]*) usage ;; esac
[ "$limit" -ge 1 ] && [ "$limit" -le 50 ] || usage

case "$kind" in
  repos)
    raw=$(gh search repos "$query" --limit "$limit" --sort stars \
      --json fullName,description,stargazersCount,url,updatedAt,language)
    ;;
  issues)
    raw=$(gh search issues "$query" --limit "$limit" \
      --json title,url,repository,state,updatedAt)
    ;;
  code)
    raw=$(gh search code "$query" --limit "$limit" --json path,repository,url)
    ;;
esac

jq -cn --arg kind "$kind" --argjson results "$raw" '{kind:$kind,results:$results}'
