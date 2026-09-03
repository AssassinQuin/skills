# deep-research skill 实施计划

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 实现通用深度调研 skill：六阶段编排（感知→拆分→并行搜集→补搜→对抗核实→落盘记忆），三层信息源递进（本地记忆→查询缓存→网页搜索），多子 agent 并行 + 任务内查询去重。

**Architecture:** SKILL.md（prompt 编排，内嵌 agent 模板）+ 3 个确定性 bash/jq 脚本（route-lane 缓存查表与路由 / save-memory 写回 / validate-findings 校验）+ 报告模板。产物落盘 `reports/research/<topic-slug>/`，查询级缓存在 `datastore/search-memory.json`。

**Tech Stack:** bash 3.2（macOS 自带）、jq 1.7（/usr/bin/jq，已验证）、Claude Code Agent 工具（model 显式指定）、MCP 搜索工具（websearch-cn/global、zhihu 三件套、web-search-prime、web-reader）、ctx_index/ctx_search。

**Spec:** `docs/superpowers/specs/2026-09-03-deep-research-skill-design.md`

## Global Constraints

- macOS darwin + bash 3.2：禁用 bash 4 特性（关联数组、`${var,,}`、`mapfile`）
- 子 agent 显式 model（coding-rules R5.1）：搜索员 sonnet / 读取员 haiku / 核实员 opus
- 限额：prime ≤3 次且仅 deep 模式、主会话直调；zhihu MCP ≤4 次/任务
- 停止（R6）：quick 单 wave 硬停；deep ≤2 wave + 1 gap 轮；连续低效用提前停
- 失败显性化（R12）：脚本错误 exit 2 + stderr 说明；JSON 校验失败 = 任务失败
- 脚本输出与注释用中文（对齐 repo 风格）
- 本计划所有 git commit 只 add 明确列出的文件（repo 有大量无关未跟踪文件，禁止 `git add -A`）

---

### Task 1: 脚手架 + route-lane.sh（缓存查表与 lane 路由）

**Files:**
- Create: `deep-research/scripts/route-lane.sh`
- Create: `deep-research/tests/test-route-lane.sh`

**Interfaces:**
- Consumes: `datastore/search-memory.json`（可被环境变量 `SEARCH_MEMORY_FILE` 覆盖，测试用）
- Produces: `route-lane.sh "<query>" --lane <cn|glb|zhihu|prime> [--refresh]`
  - stdout JSON：命中未过期 → `{"action":"reuse","key":"<q>|<lane>","fetched_at":...,"ttl_class":...,"results":[...],"task":...}`；未命中/过期/refresh → `{"action":"search","lane":...,"tool":"<MCP工具名>","tool_params":{...},"fallback":{...},"note":"..."}`
  - exit 0 正常；exit 2 用法错误（stderr 中文说明）
  - TTL：short=7 天 / long=90 天 / permanent=永不过期（用 jq `now`/`strptime` 计算，平台无关）

- [ ] **Step 1: 建目录骨架**

```bash
mkdir -p deep-research/scripts deep-research/tests deep-research/templates
```

- [ ] **Step 2: 写失败测试**

创建 `deep-research/tests/test-route-lane.sh`：

```bash
#!/usr/bin/env bash
# route-lane.sh 单元测试（6 用例）
set -u
DIR="$(cd "$(dirname "$0")/.." && pwd)"
SCRIPT="$DIR/scripts/route-lane.sh"
TMP=$(mktemp -d); MEM="$TMP/mem.json"
pass=0; fail=0
ok()  { pass=$((pass+1)); echo "PASS: $1"; }
bad() { fail=$((fail+1)); echo "FAIL: $1"; }

# Case 1: 空缓存 → search + cn 工具
echo '{}' > "$MEM"
out=$(SEARCH_MEMORY_FILE="$MEM" "$SCRIPT" "赛力斯 财报" --lane cn 2>/dev/null)
echo "$out" | jq -e '.action=="search" and .lane=="cn" and .tool=="mcp__websearch-cn__search"' >/dev/null \
  && ok "空缓存返回 search+cn 工具" || bad "Case1 输出: $out"

# Case 2: 命中未过期 → reuse
today=$(date +%F)
jq --arg d "$today" '{("老查询|cn"): {fetched_at:$d, ttl_class:"short", results:[{title:"t",url:"u",snippet:"s"}], task:"x/"}}' '{}' > "$MEM"
out=$(SEARCH_MEMORY_FILE="$MEM" "$SCRIPT" "老查询" --lane cn 2>/dev/null)
echo "$out" | jq -e '.action=="reuse" and .key=="老查询|cn" and (.results|length)==1' >/dev/null \
  && ok "缓存命中返回 reuse" || bad "Case2 输出: $out"

# Case 3: short 过期（40 天前）→ search
old=$(jq -n 'now - 40*86400 | strftime("%Y-%m-%d")')
jq --arg d "$old" '{("旧闻|glb"): {fetched_at:$d, ttl_class:"short", results:[], task:"x/"}}' '{}' > "$MEM"
out=$(SEARCH_MEMORY_FILE="$MEM" "$SCRIPT" "旧闻" --lane glb 2>/dev/null)
echo "$out" | jq -e '.action=="search"' >/dev/null && ok "short 过期重搜" || bad "Case3 输出: $out"

# Case 4: permanent 永不过期
jq --arg d "$old" '{("史实|glb"): {fetched_at:$d, ttl_class:"permanent", results:[{title:"t",url:"u",snippet:"s"}], task:"x/"}}' '{}' > "$MEM"
out=$(SEARCH_MEMORY_FILE="$MEM" "$SCRIPT" "史实" --lane glb 2>/dev/null)
echo "$out" | jq -e '.action=="reuse"' >/dev/null && ok "permanent 不过期" || bad "Case4 输出: $out"

# Case 5: --refresh 强制重搜
out=$(SEARCH_MEMORY_FILE="$MEM" "$SCRIPT" "史实" --lane glb --refresh 2>/dev/null)
echo "$out" | jq -e '.action=="search"' >/dev/null && ok "refresh 强制重搜" || bad "Case5 输出: $out"

# Case 6: 非法 lane → exit 2 + stderr
SEARCH_MEMORY_FILE="$MEM" "$SCRIPT" "q" --lane badlane >/dev/null 2>"$TMP/err"; rc=$?
[ "$rc" -eq 2 ] && [ -s "$TMP/err" ] && ok "非法 lane 报错 exit2" || bad "Case6 rc=$rc"

echo "----"; echo "pass=$pass fail=$fail"
rm -rf "$TMP"
[ "$fail" -eq 0 ]
```

- [ ] **Step 3: 跑测试确认失败**

```bash
chmod +x deep-research/tests/test-route-lane.sh
bash deep-research/tests/test-route-lane.sh
```

Expected: 6 个 FAIL（script 不存在），末行 `pass=0 fail=6`，退出码非 0。

- [ ] **Step 4: 实现 route-lane.sh**

创建 `deep-research/scripts/route-lane.sh`：

```bash
#!/usr/bin/env bash
# route-lane.sh — 查询级缓存查表 + lane 工具路由（确定性逻辑，R5）
# 用法: route-lane.sh "<query>" --lane <cn|glb|zhihu|prime> [--refresh]
# 输出: stdout JSON，action=reuse（带缓存结果）或 action=search（带工具配置）
# 退出: 0 正常；2 用法/内部错误（stderr 显式说明，R12）
# TTL: short=7天 long=90天 permanent=永不过期；--refresh 强制 bypass
set -u
DIR_ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
MEM_FILE="${SEARCH_MEMORY_FILE:-$DIR_ROOT/datastore/search-memory.json}"

query=""; lane=""; refresh=0
while [ $# -gt 0 ]; do
  case "$1" in
    --lane)     lane="$2"; shift 2 ;;
    --refresh)  refresh=1; shift ;;
    *)          query="$1"; shift ;;
  esac
done

usage_err() { echo "route-lane.sh: $1" >&2; echo "用法: route-lane.sh \"<query>\" --lane <cn|glb|zhihu|prime> [--refresh]" >&2; exit 2; }
[ -n "$query" ] || usage_err "缺少查询词"
case "$lane" in cn|glb|zhihu|prime) ;; *) usage_err "非法 lane: $lane" ;; esac

# 归一化：压缩空白（与 save-memory.sh 保持同一规则，key 才能对上）
qnorm=$(printf '%s' "$query" | tr -s '[:space:]' ' ' | sed 's/^ //;s/ $//')
key="${qnorm}|${lane}"

# lane → 工具路由表（与 SKILL.md §Phase2 的分工一致）
routing() {
  case "$1" in
    cn)    jq -cn '{action:"search",lane:"cn",tool:"mcp__websearch-cn__search",tool_params:{engines:["sogou"],limit:5},fallback:{tool:"mcp__websearch-cn__search",tool_params:{engines:["sogou","csdn","juejin","linuxdo"],limit:5}},note:"中文事实/新闻；baidu 引擎间歇 302 不路由"}' ;;
    glb)   jq -cn '{action:"search",lane:"glb",tool:"mcp__websearch-global__search",tool_params:{engines:["startpage","duckduckgo"],limit:5},fallback:{tool:"mcp__websearch-global__search",tool_params:{engines:["startpage","duckduckgo","brave"],limit:5}},note:"外文事实/技术文档；非英文查询先翻译"}' ;;
    zhihu) jq -cn '{action:"search",lane:"zhihu",tool:"mcp__zhihu__zhihu_search",tool_params:{count:3},fallback:{tool:"mcp__zhihu-global__global_search",tool_params:{count:5}},note:"观点/体验/中文争议；限额≤4次/任务串行"}' ;;
    prime) jq -cn '{action:"search",lane:"prime",tool:"mcp__web-search-prime__web_search_prime",tool_params:{count:5},fallback:null,note:"仅 deep 模式高价值查询；主会话直调≤3次；贵"}' ;;
  esac
}

ttl_days() { case "$1" in short) echo 7 ;; long) echo 90 ;; permanent) echo -1 ;; *) echo 0 ;; esac; }

if [ -f "$MEM_FILE" ] && [ "$refresh" -eq 0 ]; then
  if hit=$(jq --arg k "$key" '.[$k] // empty' "$MEM_FILE" 2>/dev/null) && [ -n "$hit" ]; then
    days=$(ttl_days "$(printf '%s' "$hit" | jq -r '.ttl_class')")
    fresh=$(jq --arg k "$key" --argjson d "$days" '
      (.[$k].fetched_at | strptime("%Y-%m-%d") | mktime) as $t |
      if $d < 0 then true elif $t > (now - $d * 86400) then true else false end
    ' "$MEM_FILE" 2>/dev/null)
    if [ "$fresh" = "true" ]; then
      jq --arg k "$key" '{action:"reuse",key:$k} * .[$k]' "$MEM_FILE"
      exit 0
    fi
  fi
fi
routing "$lane"
```

- [ ] **Step 5: 跑测试确认通过**

```bash
chmod +x deep-research/scripts/route-lane.sh
bash deep-research/tests/test-route-lane.sh
```

Expected: 6 个 PASS，末行 `pass=6 fail=0`，退出码 0。

- [ ] **Step 6: Commit**

```bash
git add deep-research/scripts/route-lane.sh deep-research/tests/test-route-lane.sh
git commit -m "feat(deep-research): route-lane.sh 查询缓存查表+lane工具路由（TDD 6用例）"
```

---

### Task 2: save-memory.sh（查询结果写回）

**Files:**
- Create: `deep-research/scripts/save-memory.sh`
- Create: `deep-research/tests/test-save-memory.sh`

**Interfaces:**
- Consumes: Task 1 的 key 规则（`归一化查询|lane`）与 `SEARCH_MEMORY_FILE` 环境变量
- Produces: `save-memory.sh "<query>" --lane <cn|glb|zhihu|prime> --ttl <short|long|permanent> --task <相对路径> --results <results.json>`
  - `<results.json>` 内容为结果数组 `[{"title","url","snippet"},...]`
  - 成功 stdout `saved: <key> (<ttl>, <今天>)`，exit 0；错误 exit 2 + stderr
  - 同 key 重复保存 = 更新（覆盖 fetched_at/results/task）

- [ ] **Step 1: 写失败测试**

创建 `deep-research/tests/test-save-memory.sh`：

```bash
#!/usr/bin/env bash
# save-memory.sh 单元测试（4 用例）
set -u
DIR="$(cd "$(dirname "$0")/.." && pwd)"
SCRIPT="$DIR/scripts/save-memory.sh"
TMP=$(mktemp -d); MEM="$TMP/mem.json"; R="$TMP/r.json"
pass=0; fail=0
ok()  { pass=$((pass+1)); echo "PASS: $1"; }
bad() { fail=$((fail+1)); echo "FAIL: $1"; }

echo '[{"title":"t1","url":"u1","snippet":"s1"}]' > "$R"

# Case 1: 保存新条目
out=$(SEARCH_MEMORY_FILE="$MEM" "$SCRIPT" "赛力斯 财报" --lane cn --ttl short --task "reports/research/x/" --results "$R" 2>/dev/null)
jq -e --arg k "赛力斯 财报|cn" --arg d "$(date +%F)" '.[$k].fetched_at==$d and .[$k].ttl_class=="short" and (.[$k].results|length)==1 and .[$k].task=="reports/research/x/"' "$MEM" >/dev/null \
  && ok "保存新条目结构完整" || bad "Case1 out=$out file=$(cat "$MEM")"

# Case 2: 同 key 再存 = 更新不重复
echo '[{"title":"t2","url":"u2","snippet":"s2"},{"title":"t3","url":"u3","snippet":"s3"}]' > "$R"
SEARCH_MEMORY_FILE="$MEM" "$SCRIPT" "赛力斯 财报" --lane cn --ttl long --task "reports/research/y/" --results "$R" >/dev/null 2>&1
n=$(jq '. | length' "$MEM"); rn=$(jq '.["赛力斯 财报|cn"].results | length' "$MEM")
[ "$n" = "1" ] && [ "$rn" = "2" ] && ok "同key更新不重复" || bad "Case2 keys=$n results=$rn"

# Case 3: results 非法 JSON → exit 2
echo 'not json' > "$TMP/bad.json"
SEARCH_MEMORY_FILE="$MEM" "$SCRIPT" "q" --lane cn --ttl short --task "t/" --results "$TMP/bad.json" >/dev/null 2>&1
[ $? -eq 2 ] && ok "非法JSON报错exit2" || bad "Case3"

# Case 4: 缺参数 → exit 2
SEARCH_MEMORY_FILE="$MEM" "$SCRIPT" "q" --lane cn >/dev/null 2>&1
[ $? -eq 2 ] && ok "缺参数报错exit2" || bad "Case4"

echo "----"; echo "pass=$pass fail=$fail"
rm -rf "$TMP"
[ "$fail" -eq 0 ]
```

- [ ] **Step 2: 跑测试确认失败**

```bash
chmod +x deep-research/tests/test-save-memory.sh
bash deep-research/tests/test-save-memory.sh
```

Expected: `pass=0 fail=4`，退出码非 0。

- [ ] **Step 3: 实现 save-memory.sh**

创建 `deep-research/scripts/save-memory.sh`：

```bash
#!/usr/bin/env bash
# save-memory.sh — 查询结果写回 search-memory 注册表（Phase 5 记忆固化用）
# 用法: save-memory.sh "<query>" --lane <cn|glb|zhihu|prime> --ttl <short|long|permanent> \
#         --task <任务目录相对路径> --results <results.json（数组文件）>
# 退出: 0 成功；2 用法/IO/JSON 错误（stderr 显式说明，R12）
set -u
DIR_ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
MEM_FILE="${SEARCH_MEMORY_FILE:-$DIR_ROOT/datastore/search-memory.json}"

query=""; lane=""; ttl=""; task=""; results=""
while [ $# -gt 0 ]; do
  case "$1" in
    --lane)    lane="$2"; shift 2 ;;
    --ttl)     ttl="$2"; shift 2 ;;
    --task)    task="$2"; shift 2 ;;
    --results) results="$2"; shift 2 ;;
    *)         query="$1"; shift ;;
  esac
done

usage_err() { echo "save-memory.sh: $1" >&2; exit 2; }
[ -n "$query" ]   || usage_err "缺少查询词"
case "$lane" in cn|glb|zhihu|prime) ;; *) usage_err "非法 lane: $lane" ;; esac
case "$ttl"  in short|long|permanent) ;; *) usage_err "非法 ttl: $ttl" ;; esac
[ -n "$task" ]    || usage_err "缺少 --task"
[ -n "$results" ] && [ -f "$results" ] || usage_err "缺少/不存在 --results 文件: $results"
jq -e 'type == "array"' "$results" >/dev/null 2>&1 || usage_err "results 不是合法 JSON 数组: $results"

# 归一化规则与 route-lane.sh 一致
qnorm=$(printf '%s' "$query" | tr -s '[:space:]' ' ' | sed 's/^ //;s/ $//')
key="${qnorm}|${lane}"
today=$(date +%F)

mkdir -p "$(dirname "$MEM_FILE")"
[ -f "$MEM_FILE" ] || printf '{}' > "$MEM_FILE"
jq -e 'type == "object"' "$MEM_FILE" >/dev/null 2>&1 || usage_err "注册表已损坏（非 JSON 对象）: $MEM_FILE"

tmp=$(mktemp) || usage_err "mktemp 失败"
jq --arg k "$key" --arg d "$today" --arg ttl "$ttl" --arg t "$task" --slurpfile r "$results" \
  '.[$k] = {fetched_at:$d, ttl_class:$ttl, task:$t, results:($r[0])}' "$MEM_FILE" > "$tmp" \
  && mv "$tmp" "$MEM_FILE" || usage_err "写回失败: $MEM_FILE"
echo "saved: $key ($ttl, $today)"
```

- [ ] **Step 4: 跑测试确认通过**

```bash
chmod +x deep-research/scripts/save-memory.sh
bash deep-research/tests/test-save-memory.sh
```

Expected: 4 个 PASS，末行 `pass=4 fail=0`，退出码 0。

- [ ] **Step 5: Commit**

```bash
git add deep-research/scripts/save-memory.sh deep-research/tests/test-save-memory.sh
git commit -m "feat(deep-research): save-memory.sh 查询结果写回注册表（TDD 4用例）"
```

---

### Task 3: validate-findings.sh（findings.json schema 校验）

**Files:**
- Create: `deep-research/scripts/validate-findings.sh`
- Create: `deep-research/tests/test-validate-findings.sh`
- Create: `deep-research/tests/fixtures/findings-valid.json`

**Interfaces:**
- Produces: `validate-findings.sh <findings.json>`
  - stdout `PASS: <file>` exit 0；`FAIL: <file>` + 逐条违规（中文）exit 1；用法错误 exit 2
  - 校验 schema（与 spec §8 一致）：topic 字符串 / date YYYY-MM-DD / mode∈quick|deep / sub_questions 非空数组且每项有 id+question+tier∈core|background+status∈answered|partial|unanswered / findings 数组且每项有 claim+sub_question+confidence∈high|medium|low+evidence[] 每项有 url+lane∈cn|glb|zhihu|prime|human / findings 引用的 sub_question 必须存在 / strongest_objection 字符串 / gaps 数组 / meta 含 requested_mode+effective_mode+reused_queries+fresh_queries+contrarian_run
  - Task 5 的 SKILL.md 与 Task 6 验收依赖此 exit code

- [ ] **Step 1: 写合法 fixture**

创建 `deep-research/tests/fixtures/findings-valid.json`：

```json
{
  "topic": "open-websearch 双实例部署调研",
  "date": "2026-09-03",
  "mode": "quick",
  "sub_questions": [
    {"id": "q1", "question": "websearch-cn 覆盖哪些引擎", "tier": "core", "status": "answered"},
    {"id": "q2", "question": "USE_PROXY 的语义与限制", "tier": "background", "status": "partial"}
  ],
  "findings": [
    {"claim": "websearch-cn 配置了 baidu/sogou/csdn/juejin/linuxdo 五引擎", "sub_question": "q1", "confidence": "high",
     "evidence": [{"url": "https://example.com/a", "title": "配置记录", "lane": "human", "quote": "ALLOWED_SEARCH_ENGINES=baidu,sogou,csdn,juejin,linuxdo", "published": "2026-09-01"}]}
  ],
  "strongest_objection": "未发现",
  "gaps": ["q2 的按引擎 bypass 机制未找到官方文档"],
  "meta": {"requested_mode": "quick", "effective_mode": "quick", "lane_health": {"cn": "ok"}, "reused_queries": 0, "fresh_queries": 3, "contrarian_run": true}
}
```

- [ ] **Step 2: 写失败测试**

创建 `deep-research/tests/test-validate-findings.sh`：

```bash
#!/usr/bin/env bash
# validate-findings.sh 单元测试（6 用例：1 合法 + 5 违规）
set -u
DIR="$(cd "$(dirname "$0")/.." && pwd)"
SCRIPT="$DIR/scripts/validate-findings.sh"
FIX="$DIR/tests/fixtures/findings-valid.json"
TMP=$(mktemp -d)
pass=0; fail=0
ok()  { pass=$((pass+1)); echo "PASS: $1"; }
bad() { fail=$((fail+1)); echo "FAIL: $1"; }

# Case 1: 合法文件 → PASS exit 0
out=$("$SCRIPT" "$FIX" 2>/dev/null); rc=$?
[ "$rc" -eq 0 ] && echo "$out" | grep -q "^PASS:" && ok "合法文件通过" || bad "Case1 rc=$rc out=$out"

# Case 2: 缺 topic → FAIL 且指明
jq 'del(.topic)' "$FIX" > "$TMP/t2.json"
out=$("$SCRIPT" "$TMP/t2.json" 2>/dev/null); rc=$?
[ "$rc" -eq 1 ] && echo "$out" | grep -q "topic" && ok "缺topic被拒" || bad "Case2 rc=$rc out=$out"

# Case 3: mode 非法 → FAIL
jq '.mode="fast"' "$FIX" > "$TMP/t3.json"
out=$("$SCRIPT" "$TMP/t3.json" 2>/dev/null); rc=$?
[ "$rc" -eq 1 ] && echo "$out" | grep -q "mode" && ok "非法mode被拒" || bad "Case3 rc=$rc"

# Case 4: findings 引用不存在的 sub_question → FAIL
jq '.findings[0].sub_question="qX"' "$FIX" > "$TMP/t4.json"
out=$("$SCRIPT" "$TMP/t4.json" 2>/dev/null); rc=$?
[ "$rc" -eq 1 ] && echo "$out" | grep -q "sub_question" && ok "悬空引用被拒" || bad "Case4 rc=$rc"

# Case 5: evidence.lane 非法 → FAIL
jq '.findings[0].evidence[0].lane="twitter"' "$FIX" > "$TMP/t5.json"
out=$("$SCRIPT" "$TMP/t5.json" 2>/dev/null); rc=$?
[ "$rc" -eq 1 ] && echo "$out" | grep -q "lane" && ok "非法lane被拒" || bad "Case5 rc=$rc"

# Case 6: meta 缺字段 → FAIL
jq '.meta |= del(.contrarian_run)' "$FIX" > "$TMP/t6.json"
out=$("$SCRIPT" "$TMP/t6.json" 2>/dev/null); rc=$?
[ "$rc" -eq 1 ] && echo "$out" | grep -q "contrarian_run" && ok "meta缺字段被拒" || bad "Case6 rc=$rc"

echo "----"; echo "pass=$pass fail=$fail"
rm -rf "$TMP"
[ "$fail" -eq 0 ]
```

- [ ] **Step 3: 跑测试确认失败**

```bash
chmod +x deep-research/tests/test-validate-findings.sh
bash deep-research/tests/test-validate-findings.sh
```

Expected: Case 1 FAIL（脚本不存在），`pass=0 fail=6`，退出码非 0。

- [ ] **Step 4: 实现 validate-findings.sh**

创建 `deep-research/scripts/validate-findings.sh`：

```bash
#!/usr/bin/env bash
# validate-findings.sh — findings.json schema 校验（R12：失败显式报错，不静默）
# 用法: validate-findings.sh <findings.json>
# 退出: 0 PASS；1 FAIL（stdout 列出全部违规）；2 用法错误
set -u
f="${1:-}"
if [ -z "$f" ] || [ ! -f "$f" ]; then
  echo "validate-findings.sh: 缺少/不存在文件: $f" >&2
  exit 2
fi
jq -e . "$f" >/dev/null 2>&1 || { echo "FAIL: $f"; echo "  - 不是合法 JSON"; exit 1; }

errs=$(jq -r '
  [
    (if (.topic | type) != "string" then "topic 缺失或非字符串" else empty end),
    (if ((.date // "") | test("^\\d{4}-\\d{2}-\\d{2}$") | not) then "date 非 YYYY-MM-DD: \(.date)" else empty end),
    (if ((.mode // "") as $m | ($m == "quick" or $m == "deep") | not) then "mode 非法: \($m)" else empty end),
    (if (.sub_questions | type) != "array" or (.sub_questions | length) == 0 then "sub_questions 需非空数组" else empty end),
    ( .sub_questions[]? |
      (if ((.id // "") == "") then "sub_questions[] 缺 id" else empty end),
      (if ((.question // "") == "") then "sub_questions[] 缺 question" else empty end),
      (if ((.tier // "") as $t | ($t == "core" or $t == "background") | not) then "sub_questions[\(.id)].tier 非法: \($t)" else empty end),
      (if ((.status // "") as $s | ($s == "answered" or $s == "partial" or $s == "unanswered") | not) then "sub_questions[\(.id)].status 非法: \($s)" else empty end)
    ),
    (if (.findings | type) != "array" then "findings 需数组" else empty end),
    ( .findings[]? |
      (if ((.claim // "") == "") then "findings[] 缺 claim" else empty end),
      (if ((.sub_question // "") == "") then "findings[] 缺 sub_question" else empty end),
      (if ((.confidence // "") as $c | ($c == "high" or $c == "medium" or $c == "low") | not) then "findings[].confidence 非法: \($c)" else empty end),
      ( .evidence[]? |
        (if ((.url // "") == "") then "evidence[] 缺 url" else empty end),
        (if ((.lane // "") as $l | ($l == "cn" or $l == "glb" or $l == "zhihu" or $l == "prime" or $l == "human") | not) then "evidence.lane 非法: \($l)" else empty end)
      )
    ),
    ( ([.sub_questions[]?.id]) as $ids |
      .findings[]? |
      select((.sub_question) as $s | ($ids | index($s)) == null) |
      "findings 引用不存在的 sub_question: \(.sub_question)"
    ),
    (if (.strongest_objection | type) != "string" then "strongest_objection 需字符串（可为「未发现」）" else empty end),
    (if (.gaps | type) != "array" then "gaps 需数组" else empty end),
    ( (.meta // {}) |
      (if (has("requested_mode") | not) then "meta 缺 requested_mode" else empty end),
      (if (has("effective_mode") | not) then "meta 缺 effective_mode" else empty end),
      (if (has("reused_queries") | not) then "meta 缺 reused_queries" else empty end),
      (if (has("fresh_queries") | not) then "meta 缺 fresh_queries" else empty end),
      (if (has("contrarian_run") | not) then "meta 缺 contrarian_run" else empty end)
    )
  ] | join("\n")
' "$f" 2>&1)

if [ -n "$errs" ]; then
  echo "FAIL: $f"
  printf '%s\n' "$errs" | while IFS= read -r line; do [ -n "$line" ] && echo "  - $line"; done
  exit 1
fi
echo "PASS: $f"
```

- [ ] **Step 5: 跑测试确认通过**

```bash
chmod +x deep-research/scripts/validate-findings.sh
bash deep-research/tests/test-validate-findings.sh
```

Expected: 6 个 PASS，`pass=6 fail=0`，退出码 0。

- [ ] **Step 6: 回归 Task 1/2 测试**

```bash
bash deep-research/tests/test-route-lane.sh && bash deep-research/tests/test-save-memory.sh
```

Expected: 全部 PASS，退出码 0。

- [ ] **Step 7: Commit**

```bash
git add deep-research/scripts/validate-findings.sh deep-research/tests/test-validate-findings.sh deep-research/tests/fixtures/findings-valid.json
git commit -m "feat(deep-research): validate-findings.sh schema校验（TDD 6用例）"
```

---

### Task 4: 报告模板 + inbox README 模板

**Files:**
- Create: `deep-research/templates/report.md`
- Create: `deep-research/templates/inbox-README.md`

**Interfaces:**
- Produces: Task 5 的 SKILL.md Phase 5 引用这两个模板路径（`{baseDir}/templates/report.md`、`{baseDir}/templates/inbox-README.md`）
- 模板内 `{{占位符}}` 为运行时填充标记，由编排者替换

- [ ] **Step 1: 写 report.md 模板**

创建 `deep-research/templates/report.md`：

```markdown
# {{topic}} 调研报告

> 日期：{{date}} ｜ 模式：{{requested_mode}} → {{effective_mode}} ｜ 查询：复用 {{reused_queries}} / 新搜 {{fresh_queries}}

## 摘要

{{3-5 句核心结论，含最重要的数字与判断}}

## 发现

{{按子主题重组全部发现（综合而非粘贴），每条事实带日期/数字/[S1] 式内联引用}}

### {{子主题 1}}

{{发现内容}}

### {{子主题 2}}

{{发现内容}}

## 最强反驳

{{contrarian pass 的结果；明确写「未发现」如果搜索后无反面证据}}

## 未解问题

{{core 未覆盖项 + 原因；无则写「无」}}

## 引用

{{每行一条：S1: title — url — lane — published_date}}

## Meta

- lane 健康：{{如 cn:ok / zhihu:限流跳过}}
- 降级记录：{{无则「无」}}
- 任务目录：{{task_dir}}
```

- [ ] **Step 2: 写 inbox-README.md 模板**

创建 `deep-research/templates/inbox-README.md`：

```markdown
# inbox — 人工投喂通道

搜索被墙、登录墙、或内容有问题时，把资料手动放到本目录，重跑/续跑调研时会被自动吸收。

- 支持格式：`.md` / `.txt`（纯文本或 markdown，UTF-8）
- 命名建议：`<来源或主题>.md`（如 `zhihu-answer-12345.md`）
- 文件内首行建议写明来源 URL 与获取日期
- 吸收规则：文件会被转存为 `../raw/S<n>-inbox.md` 并标记 `lane: human`，作为高优先证据源
```

- [ ] **Step 3: 验证模板关键节存在**

```bash
grep -q "最强反驳" deep-research/templates/report.md && grep -q "未解问题" deep-research/templates/report.md && grep -q "lane: human" deep-research/templates/inbox-README.md && echo TEMPLATES-OK
```

Expected: 输出 `TEMPLATES-OK`。

- [ ] **Step 4: Commit**

```bash
git add deep-research/templates/report.md deep-research/templates/inbox-README.md
git commit -m "feat(deep-research): 报告与inbox模板"
```

---

### Task 5: SKILL.md（编排主文档）

**Files:**
- Create: `deep-research/SKILL.md`

**Interfaces:**
- Consumes: Task 1-4 的全部产物（脚本命令行、模板路径）
- Produces: 完整编排文档。`{baseDir}` 为 skill 目录绝对路径（框架运行时替换，与 global-search 约定一致）；`{TASK}` 为 `reports/research/<topic-slug>/` 绝对路径

- [ ] **Step 1: 写 SKILL.md**

创建 `deep-research/SKILL.md`，内容如下（完整）：

````markdown
---
name: deep-research
version: 0.1.0
description: 通用深度调研服务：自主拆分需求为子主题，本地记忆→搜索缓存→网页搜索三层递进，多子agent并行搜集+对抗核实，输出详尽报告并固化长期记忆。触发：/deep-research、「深度调研」「帮我调研」「全面了解一下」「收集资料写报告」「查一下XX的来龙去脉」。
metadata: {"openclaw":{"emoji":"🔬","requires":{"bins":["bash","jq"]}}}
---

# Deep Research 深度调研服务

主会话 = 编排者，全程自动推进、不等用户确认。六阶段如下；任何失败按「降级链」处理并显式记录在报告 Meta。

## 模式判定

- 默认 quick；用户说「深挖 / 深度调研 / 详尽」→ deep；「快查 / 简单看下」→ 强制 quick
- 用户措辞永远覆盖启发式，双向都成立

## 硬约束（违反任何一条 = 失败运行）

1. core 子问题覆盖率 100%：未覆盖项必须进报告「未解问题」并给原因，不许静默
2. contrarian pass 必跑：无反驳也必须写「未发现」
3. 报告未落盘 = 失败运行；findings.json 过不了 validate-findings.sh = 失败运行
4. 报告必须标注 Requested/Effective Mode、lane 健康、reused/fresh 查询数
5. 查询去重：任何搜索执行前先查任务登记表与路由缓存，已登记/已缓存的跳过
6. 子 agent 必须显式指定 model（R5.1）：搜索员 sonnet / 读取员 haiku / 核实员 opus
7. 限额：prime ≤3 次且仅 deep、主会话直调；zhihu MCP ≤4 次/任务

## Phase 0 感知判定

1. 判模式（见上）
2. spawn 可用性：已在子 agent 内执行 → 全程 solo（主会话串行扮演各员，保格式），Effective Mode 加 `+solo`
3. 长期记忆感知（由近及远）：
   - recall auto-memory 中过往调研结论（关键词匹配主题）
   - 读 `reports/research/INDEX.md`：旧报告能直接回答 → 引用输出 + 按需小补充，收工
   - ctx_search 召回历史 Findings/raw（无 ctx 工具的框架跳过）
   - 扫描任务目录 `inbox/`：有人工投喂 → 列为高优先证据源（lane: human）
4. 旧资料足以回答 → 输出并收工；否则 Phase 1

## Phase 1 需求拆分

1. 建任务目录 `{TASK}`（slug：主题的短横线小写拼音或英文）：
   ```bash
   mkdir -p {TASK}/raw {TASK}/parts {TASK}/inbox {TASK}/cache
   cp {baseDir}/templates/inbox-README.md {TASK}/inbox/README.md
   touch {TASK}/queries.jsonl
   ```
   写 `{TASK}/meta.json`：`{"topic","date","requested_mode","sub_questions":[{id,question,tier,source_route}],"{note}"}`
2. 拆子主题：quick 3-5 个 / deep 4-8 个（cap 12）；每个标 `tier: core|background`；deep 可带依赖（DAG，wave 按拓扑序）
3. 每个子主题标源路由：
   - 本地可答（记忆/旧报告/raw 已有）→ 不进搜索清单
   - 需网页 → 分配 lane（cn=中文事实 / glb=外文 / zhihu=观点争议 / prime=deep 高价值）
   - 预期搜不到（登录墙/被墙）→ 标「待 inbox 投喂」
4. 生成查询清单（每子主题 1-2 条查询），逐条路由：
   ```bash
   bash {baseDir}/scripts/route-lane.sh "<query>" --lane <lane>
   ```
   - `action=reuse` → 直接采用缓存结果，append 登记 `{query,lane,agent:"orchestrator",wave:0,reused:true}` 到 queries.jsonl
   - `action=search` → 进待搜清单，记录输出的 tool/tool_params
5. 分配去重：归一化合并同义查询（大小写/空白/同义词），每条查询唯一归属一个 lane；每个搜索员的 prompt **只包含分给它的查询清单**，边界划清
6. 打印「子主题×lane×查询」矩阵表格，然后直接开跑

## Phase 2 并行搜集

spawn 搜索员（Agent 工具，general-purpose，**显式 model**，并行发出）：

| 员 | model | 工具（只用这些） | 搜索上限 |
|---|---|---|---|
| cn 搜索员 | sonnet | mcp__websearch-cn__search | quick 3 / deep 6 |
| glb 搜索员 | sonnet | mcp__websearch-global__search | quick 3 / deep 6 |
| zhihu 搜索员 | sonnet | mcp__zhihu__zhihu_search、mcp__zhihu-global__global_search | ≤4 次，串行调用 |

搜索员 prompt 模板（`{LANE}`/`{DATE}`/`{TASK}`/`{QUERY_LIST}`/`{TOOL_DOC}`/`{WAVE}` 运行时填充）：

```
你是{LANE}通道的搜索员，只负责这一个通道。今天日期：{DATE}（一切以它为准；构造搜索词必须带年份，不依赖你对当前日期的先验）。

任务目录：{TASK}
你只搜以下查询，不要搜清单外的内容（过程中发现的新线索记入 Gaps，不要自己扩展搜索）：
{QUERY_LIST}

工具与参数（照此调用，失败时改用 fallback）：
{TOOL_DOC}

去重纪律（重要）：
- 每次搜索前先 cat {TASK}/queries.jsonl；若该查询已被任何 agent 登记 → 跳过，并在 Gaps 里说明「查询已由他人覆盖」
- 每次实际执行的搜索，完成后立刻追加登记一行（保持文件是逐行 JSON）：
  printf '%s\n' '{"query":"<该次查询>","lane":"{LANE}","agent":"{LANE}-1","wave":{WAVE}}' >> {TASK}/queries.jsonl

严格按以下格式返回，不要输出其他内容：
## Findings
（事实+日期+数字，内联引用标记 [S1][S2]…，每条标明来源）
## Gaps
（没答上的/发现的矛盾/值得 follow-up 的问题；无则写 None）
## Sources
（每行：S1: title — url — {LANE} — published_date）
```

读取员（高价值信源抓正文，model: haiku）：

```
你是读取员。用 mcp__web-reader__webReader 依次抓取以下 URL 的正文：
{URL_LIST}
每个来源写入 {TASK}/raw/S{n}-{短slug}.md，文件首三行固定为：
# {title}
- url: {url}
- fetched: {DATE}
只返回每源的元数据清单（编号/标题/大致字节数），绝对不要返回正文内容。
```

prime：deep 模式且存在高价值查询 → **主会话直调** mcp__web-search-prime__web_search_prime（≤3 次），结果同样登记 queries.jsonl（agent:"orchestrator-prime"）。

每个 agent 返回后：
- 全文 `ctx_index`（source: `<topic-slug>`；无 ctx 工具跳过），主会话上下文只留摘要
- wave 间：把已登记查询清单 + 依赖子主题的发现摘要，注入下一 wave 各员 prompt

## Phase 3 缺口补搜（仅 deep，max 1 轮）

汇总各员 Gaps + core 未覆盖项 → 只补「会改变结论」的 gap（1-3 条定向查询，照常走 route-lane.sh + queries.jsonl 登记）→ 作为最后一波。若新结果全部与已有发现重复（低效用）→ 提前停。

## Phase 4 对抗核实（spawn 1 个，model: opus）

输入：主会话综合后的载荷论断清单 + 全部 Sources。prompt 模板：

```
你是对抗核实员。任务目录 {TASK}，今天 {DATE}。
1. 独立来源计数：下列每个载荷论断，数一数独立来源数（域名不同才算独立；同一域名多篇=1）。<2 个的标 low：
{载荷论断清单 + 各自现有来源域名}
2. contrarian 搜索：用 mcp__websearch-cn__search（中文）或 mcp__websearch-global__search（外文）搜每个核心结论的反面证据（构造「<结论关键词> 错了/批评/翻车/反面/风险」类查询）。输出每个结论的「最强反驳」；找不到写「未发现」。每次搜索后登记：
  printf '%s\n' '{"query":"...","lane":"cn|glb","agent":"verifier","wave":9}' >> {TASK}/queries.jsonl
3. factored 验证：不看草稿，仅凭下列 URL 用 mcp__web-reader__webReader 直接回答验证题，再与草稿说法比对，列出不一致处：
{验证题清单（如「S3 中提到的营收数字是多少？」）+ 草稿对应说法}

返回格式：
## 独立来源计数
（论断 → 来源数 → high/low）
## 最强反驳
（结论 → 反驳内容 或 未发现）
## 验证不一致
（无则写 无）
```

## Phase 5 整理成文 + 记忆固化（主会话独占写盘）

1. `{TASK}/report.md`：按 `{baseDir}/templates/report.md` 骨架填充；按子主题**重组**发现（综合而非粘贴），数字/日期/[S1] 引用齐全；含最强反驳、未解问题、Meta
2. `{TASK}/findings.json`：schema 见 `scripts/validate-findings.sh` 内注释（topic/date/mode/sub_questions/findings/strongest_objection/gaps/meta）
3. `{TASK}/sources.json`：`[{"id":"S1","title","url","lane","published"}]`
4. 校验（失败必须修复重校，不许跳过）：
   ```bash
   bash {baseDir}/scripts/validate-findings.sh {TASK}/findings.json
   ```
5. 写回记忆：
   - 每条 fresh 查询：把该查询结果数组写入 `{TASK}/cache/q{n}-{lane}.json`，然后
     ```bash
     bash {baseDir}/scripts/save-memory.sh "<query>" --lane <lane> --ttl <short|long|permanent> --task {TASK相对路径} --results {TASK}/cache/q{n}-{lane}.json
     ```
     ttl 选择：新闻/行情=short，版本号/数据/方法论=long，历史事实=permanent
   - `reports/research/INDEX.md` 追加一行（不存在则先建表头 `| 日期 | slug | 一句话结论 |`）
   - auto-memory 写一条：结论一句话 + 报告路径
   - ctx_index 全量 Findings/raw（source: `<topic-slug>`）
6. 会话内只回：报告摘要 + 路径 + reused/fresh 统计 + inbox 提示（若有「待投喂」项，给出建议文件名）

## 降级链

- spawn 不可用 → solo：主会话串行扮演各员，保持返回格式不变
- MCP 工具失败 → 用 route-lane.sh 输出的 fallback 配置 → 仍失败 → CLI 兜底：`python3 <repo>/global-search/scripts/global-search.py '{"query":"...","count":5}'` 或 `python3 <repo>/zhihu-search/scripts/zhihu-search.py '{"query":"...","count":3}'`
- prime 失败 → ows-glb 兜底
- zhihu 超限 → search-memory 缓存 / 旧报告引用
- 某 lane 全挂 → 报告标注 lane 缺席 + 其余发现置信度降级说明 + 提示「可放入 {TASK}/inbox/ 后重跑」

## inbox 吸收

Phase 0 扫描到 inbox/ 有未吸收文件（不在 meta.json 的 absorbed_inbox 列表中）→ 读取并转存 `{TASK}/raw/S{n}-inbox.md`（保留原文件，首行补来源信息），标 `lane: human`，作为高优先证据源；吸收后把文件名记入 meta.json。
````

- [ ] **Step 2: 验证 SKILL.md 结构**

```bash
head -6 deep-research/SKILL.md; grep -c "^## Phase" deep-research/SKILL.md; grep -q "route-lane.sh" deep-research/SKILL.md && grep -q "save-memory.sh" deep-research/SKILL.md && grep -q "validate-findings.sh" deep-research/SKILL.md && grep -q "queries.jsonl" deep-research/SKILL.md && echo SKILL-OK
```

Expected: frontmatter 正常显示；`grep -c "^## Phase"` 输出 `6`；输出 `SKILL-OK`。

- [ ] **Step 3: Commit**

```bash
git add deep-research/SKILL.md
git commit -m "feat(deep-research): SKILL.md 六阶段编排主文档（agent模板+去重纪律+降级链）"
```

---

### Task 6: 部署 + 端到端验收

**Files:**
- Create: `~/.claude/skills/deep-research`（symlink）
- Create（运行产物）: `reports/research/<三个验收主题目录>/`、`datastore/search-memory.json`、验收报告

**Interfaces:**
- Consumes: Task 1-5 全部产物
- Produces: 可被 Claude Code 识别的 skill；spec §13 的 6 条验收证据

- [ ] **Step 1: 部署 symlink（对齐 story-audit 分发模式）**

```bash
ln -sfn /Users/ganjie/skills/deep-research ~/.claude/skills/deep-research
ls -la ~/.claude/skills/deep-research
```

Expected: 显示 `deep-research -> /Users/ganjie/skills/deep-research`。

- [ ] **Step 2: 全量单元测试回归**

```bash
bash deep-research/tests/test-route-lane.sh && bash deep-research/tests/test-save-memory.sh && bash deep-research/tests/test-validate-findings.sh && echo ALL-TESTS-PASS
```

Expected: `ALL-TESTS-PASS`。

- [ ] **Step 3: E2E #1 — quick 中文投研类**

读取 `deep-research/SKILL.md` 并严格按其流程执行：`调研：赛力斯 2026 上半年经营状况与主要风险（quick 模式）`

验收 checklist（逐项执行命令核对）：

```bash
T=$(ls -dt reports/research/* | head -1)   # 最新任务目录
bash deep-research/scripts/validate-findings.sh "$T/findings.json"          # 期望 PASS
[ -s "$T/queries.jsonl" ] && wc -l < "$T/queries.jsonl"                     # 期望 ≥1
grep -q "最强反驳" "$T/report.md" && grep -q "未解问题" "$T/report.md"      # 期望成功
grep -q "$(basename $T)" reports/research/INDEX.md 2>/dev/null || echo "INDEX 缺行"  # 期望无输出
jq -e '.meta.contrarian_run == true' "$T/findings.json" >/dev/null          # 期望成功
```

- [ ] **Step 4: E2E #2 — deep 技术选型类**

按 SKILL.md 执行：`深度调研：2026 年 9 月 Bun 与 Node.js 生产环境选型`

额外核对（在 Step 3 checklist 基础上）：

```bash
jq -e '.mode == "deep"' "$T/findings.json" >/dev/null           # 期望成功
jq '.meta.fresh_queries' "$T/findings.json"                      # 期望 >0
grep -c '"agent":"orchestrator-prime"' "$T/queries.jsonl"        # 期望 ≤3（prime 限额）
ls "$T/raw/" | wc -l                                             # 期望 ≥1（deep 应抓正文）
```

- [ ] **Step 5: E2E #3 — 混合语言类**

按 SKILL.md 执行：`调研：トヨタ 2026年3月期 決算と電動化戦略`（日语源）
核对：findings.json 中存在 `lane: "glb"` 的 evidence；validate PASS。

- [ ] **Step 6: 缓存复验（同题重跑）**

对 E2E #1 同一问题再跑一次（quick），核对：

```bash
jq '.meta.reused_queries' "$T/findings.json"    # 期望 ≥1（缓存生效）
```

- [ ] **Step 7: inbox 吸收测试**

```bash
T1=$(ls -dt reports/research/* | head -1)
printf '# 手工资料\n- url: https://example.com/manual\n- fetched: 2026-09-03\n\n这里是用户手动粘贴的正文内容。\n' > "$T1/inbox/test-feed.md"
```

对同题重跑/续跑后核对：

```bash
ls "$T1/raw/" | grep -q inbox                   # 期望成功（被吸收转存）
jq -e '.findings[].evidence[]? | select(.lane=="human")' "$T1/findings.json" >/dev/null   # 期望成功
```

- [ ] **Step 8: 写验收报告并 commit**

把 6 条验收结果写入 `reports/research/2026-09-03-acceptance-deep-research.md`（每条 PASS/FAIL + 证据），然后：

```bash
git add deep-research reports/research datastore/search-memory.json
git commit -m "feat(deep-research): 端到端验收通过——3问题E2E+缓存复验+inbox吸收"
```

---

## 计划自审记录

1. **Spec 覆盖**：六阶段流程（Task 5 SKILL.md）、lane 路由表（Task 1 内嵌）、save/validate 脚本（Task 2/3）、模板（Task 4）、主题目录+queries.jsonl+inbox（Task 5 Phase 1 + Task 6）、两级记忆（Task 1/2 精确层 + Task 5 Phase 5 语义层）、大文件 IO（Task 5 读取员/raw 落盘/parts 合并）、质量门（Task 3 + Task 5 硬约束）、降级链（Task 5）、验收 6 条（Task 6）——全部有对应任务
2. **占位符扫描**：模板内 `{{...}}` 为运行时填充标记（设计如此）；所有代码块完整可执行；无 TBD/TODO
3. **类型/命名一致性**：`SEARCH_MEMORY_FILE`、key 格式 `归一化查询|lane`、ttl 枚举 `short|long|permanent`、lane 枚举 `cn|glb|zhihu|prime|human`、queries.jsonl 字段 `{query,lane,agent,wave[,reused]}` 在 Task 1/2/5/6 间一致
