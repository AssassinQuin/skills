#!/usr/bin/env bash
# ledger.sh — 全局 skill token 账本 + 健康诊断（skill-stats 管理中心组件）
# 由 scripts/token-ledger.sh 移植（2026-09-04），默认 repo = skill-stats/scripts 上两级
# 用法: ledger.sh [repo路径] [--json]
# 判据（reports/research/skill-improve/ 2026-09-04 调研）:
#   OVER5K     SKILL.md bytes/4 >5,000（官方建议值）
#   DESC_OVER  frontmatter description >1,024 字符（官方硬限制）
#   NO_DESC    description 缺失
#   ZOMBIE     目录年龄 >60 天 且 0 使用，或最后使用 >60 天
#   ZERO_TRIGGER_SUSPECT 目录年龄 >30 天 且 0 使用（触发失败嫌疑，观察级）
#   NEW_UNVERIFIED ≤60 天龄且 0 使用（新建待验证）
# 退出: 0 正常；2 用法/IO 错误（stderr 显式说明，R12）
set -u
REPO=""
JSON=0
for a in "$@"; do
  case "$a" in
    --json) JSON=1 ;;
    -h|--help) sed -n '2,13p' "$0"; exit 0 ;;
    *) REPO="$a" ;;
  esac
done
REPO="$(cd "$(dirname "$0")/.." && pwd)"
[ -d "$REPO" ] || { echo "ledger.sh: repo 不存在: $REPO" >&2; exit 2; }

REPO="$REPO" JSON="$JSON" TODAY="$(date +%F)" python3 - <<'PYEOF'
import json, os, re, subprocess, sys

repo = os.environ['REPO']; json_mode = os.environ['JSON'] == '1'; today = os.environ['TODAY']

def birth_date(p):
    try:
        out = subprocess.run(['stat', '-f', '%SB', '-t', '%Y-%m-%d', p], capture_output=True, text=True).stdout.strip()
        import datetime; datetime.date.fromisoformat(out); return out
    except Exception:
        return None

usage = {}
upath = os.path.join(repo, '.stats', 'usage.jsonl')
if os.path.exists(upath):
    for line in open(upath, encoding='utf-8'):
        line = line.strip()
        if not line: continue
        try: u = json.loads(line)
        except json.JSONDecodeError: continue
        name = u.get('skill') or u.get('name')
        if not name: continue
        name = name.split(':')[-1]  # 命名空间归一
        d = usage.setdefault(name, {'count': 0, 'last': None})
        d['count'] += 1
        ts = str(u.get('ts') or u.get('timestamp') or '')[:10]
        if ts and (not d['last'] or ts > d['last']): d['last'] = ts

def days(dstr):
    if not dstr: return None
    import datetime
    return (datetime.date.fromisoformat(today) - datetime.date.fromisoformat(dstr)).days

def parse_desc(content):
    m = re.match(r'^---\n(.*?)\n---', content, re.S)
    if not m: return ''
    desc, in_desc = '', False
    for l in m.group(1).split('\n'):
        if l.startswith('description:'):
            rest = l[len('description:'):].strip()
            if rest in ('>', '>-', '|', '|-'): in_desc = True; continue
            if (rest.startswith('"') and rest.endswith('"')) or (rest.startswith("'") and rest.endswith("'")):
                desc = rest[1:-1]; in_desc = False
            elif rest: desc = rest; in_desc = False
            else: in_desc = True
            continue
        if in_desc and (l.startswith('  ') or l.startswith('\t')) and l.strip():
            desc += ('\n' if desc else '') + l.strip()
        elif in_desc: in_desc = False
    return desc.strip()

rows = []
for d in sorted(os.listdir(repo)):
    skill_md = os.path.join(repo, d, 'SKILL.md')
    if d.startswith('.') or not os.path.isfile(skill_md): continue
    if os.path.islink(os.path.join(repo, d)): continue  # symlink（跨 repo 项目 skill）不属管辖
    content = open(skill_md, encoding='utf-8').read()
    nbytes = len(content.encode('utf-8'))
    tokens = (nbytes + 3) // 4
    desc = parse_desc(content)
    u = usage.get(d, {'count': 0, 'last': None})
    age = days(birth_date(os.path.join(repo, d)))
    idle = days(u['last']) if u['last'] else None
    flags = []
    if tokens > 5000: flags.append('OVER5K')
    if not desc: flags.append('NO_DESC')
    elif len(desc) > 1024: flags.append('DESC_OVER')
    if u['count'] == 0 and age is not None:
        if age > 60: flags.append('ZOMBIE')
        elif age > 30: flags.append('ZERO_TRIGGER_SUSPECT')
        else: flags.append('NEW_UNVERIFIED')
    elif idle is not None and idle > 60:
        flags.append('ZOMBIE')
    rows.append({'skill': d, 'bytes': nbytes, 'tokens': tokens, 'desc_chars': len(desc),
                 'uses': u['count'], 'last_use': u['last'], 'age_days': age, 'flags': flags})

if json_mode:
    print(json.dumps(rows, ensure_ascii=False, indent=1)); sys.exit(0)

rows.sort(key=lambda r: -r['tokens'])
print(f"{'skill':32} {'tokens':>7} {'uses':>4} {'last_use':11} {'age':>4}  flags")
print('-' * 84)
for r in rows:
    print(f"{r['skill']:32} {r['tokens']:>7} {r['uses']:>4} {r['last_use'] or '-':11} {str(r['age_days'] if r['age_days'] is not None else '-'):>4}  {','.join(r['flags'])}")
body = sum(r['tokens'] for r in rows)
desc_on = sum((r['desc_chars'] + 3) // 4 for r in rows)
zomb = [r for r in rows if 'ZOMBIE' in r['flags']]
suspect = [r for r in rows if 'ZERO_TRIGGER_SUSPECT' in r['flags']]
newu = [r for r in rows if 'NEW_UNVERIFIED' in r['flags']]
over = [r for r in rows if 'OVER5K' in r['flags']]
dov = [r for r in rows if 'DESC_OVER' in r['flags'] or 'NO_DESC' in r['flags']]
print('-' * 84)
print(f"合计 {len(rows)} 全局 skill：body 按需 ≈{body}t；description 常驻 ≈{desc_on}t")
print(f"僵尸(>60天龄0用/超60天未用): {len(zomb)}{'' if zomb else '（无）'}")
print(f"触发失败嫌疑(31-60天龄0用，观察级): {len(suspect)}{'' if suspect else '（无）'}")
print(f"新建待验证(≤30天龄0用): {len(newu)}{'' if newu else '（无）'}")
print(f"超5K建议值: {len(over)}{'' if over else '（无）'}；description 违规: {len(dov)}{'' if dov else '（无）'}")
if suspect:
    print("建议: ZERO_TRIGGER_SUSPECT 的 skill 检查 description 触发词是否覆盖用户实际说法")
PYEOF
