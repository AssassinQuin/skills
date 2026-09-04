#!/bin/bash
# fetch-index-data.sh — 一次性抓取指数深度研究所有数据（基于 akshare）
#
# 用法:
#   fetch-index-data.sh <INDEX_CODE> <ETF_CODE> [YEAR]
#   fetch-index-data.sh 930740 515300
#   fetch-index-data.sh 930740 515300 2026
#
# 输出: /Users/ganjie/skills/datastore/indices/<INDEX_CODE>/

set -e

INDEX="${1:?Usage: $0 <INDEX_CODE> <ETF_CODE> [YEAR]}"
ETF="${2:?Usage: $0 <INDEX_CODE> <ETF_CODE> [YEAR]}"
YEAR="${3:-$(date +%Y)}"

DATA_ROOT="/Users/ganjie/skills/datastore/indices/$INDEX"
AKSHARE="$HOME/.claude/tools/ai-berkshire/fetch-akshare.py"
DATE_STAMP=$(date +%Y-%m-%d)

mkdir -p "$DATA_ROOT"/{constituents,holdings,financials,macro,reports}

echo "════════════════════════════════════════════════"
echo "  指数深度研究数据抓取"
echo "  指数: $INDEX    跟踪 ETF: $ETF    年份: $YEAR"
echo "  存储: $DATA_ROOT"
echo "════════════════════════════════════════════════"

# 1. 成分股
echo ""
echo "[1/6] 抓取指数成分股 (akshare index_stock_cons_csindex)..."
python3 "$AKSHARE" constituents "$INDEX" > "$DATA_ROOT/constituents/$DATE_STAMP.json" 2>&1 && \
  echo "  ✅ $DATA_ROOT/constituents/$DATE_STAMP.json" || \
  echo "  ⚠️ 失败，见文件"

# 2. ETF 持仓（前 10 大）
echo ""
echo "[2/6] 抓取 ETF 持仓 (akshare fund_portfolio_hold_em)..."
python3 "$AKSHARE" holdings "$ETF" --year "$YEAR" > "$DATA_ROOT/holdings/$ETF-$YEAR-Q1.json" 2>&1 && \
  echo "  ✅ $DATA_ROOT/holdings/$ETF-$YEAR-Q1.json" || \
  echo "  ⚠️ 失败"

# 3. 前 5 大重仓股财报
echo ""
echo "[3/6] 抓取前 5 大重仓股 5 年财报..."
# 从持仓 JSON 提取前 5 大股票代码
TOP5=$(python3 -c "
import json
with open('$DATA_ROOT/holdings/$ETF-$YEAR-Q1.json') as f:
    d = json.load(f)
# orient='split' 格式: {columns:[...], index:[...], data:[[row1], [row2], ...]}
cols = d['data']['columns']  # ['序号', '股票代码', '股票名称', ...]
rows = d['data']['data']
# 找列索引
rank_idx = cols.index('序号')
code_idx = cols.index('股票代码')
# 按 rank 排序，取前 5 的 code
sorted_rows = sorted(rows, key=lambda r: int(r[rank_idx]) if str(r[rank_idx]).isdigit() else 99)
for r in sorted_rows[:5]:
    print(r[code_idx])  # 6 位股票代码
" 2>/dev/null || echo "")

if [ -z "$TOP5" ]; then
  echo "  ⚠️ 无法从持仓 JSON 提取前 5 大代码，跳过财报抓取"
else
  for code in $TOP5; do
    echo "  抓取 $code..."
    python3 "$AKSHARE" financials "$code" --years 5 > "$DATA_ROOT/financials/$code.json" 2>&1 && \
      echo "    ✅ $code.json" || \
      echo "    ⚠️ $code 失败"
  done
fi

# 4. 宏观数据
echo ""
echo "[4/6] 抓取中国宏观 GDP..."
python3 "$AKSHARE" macro gdp > "$DATA_ROOT/macro/gdp.json" 2>&1 && echo "  ✅ gdp.json" || echo "  ⚠️ 失败"

echo "[5/6] 抓取中国 CPI..."
python3 "$AKSHARE" macro cpi > "$DATA_ROOT/macro/cpi.json" 2>&1 && echo "  ✅ cpi.json" || echo "  ⚠️ 失败"

echo "[6/6] 抓取中国 PMI..."
python3 "$AKSHARE" macro pmi > "$DATA_ROOT/macro/pmi.json" 2>&1 && echo "  ✅ pmi.json" || echo "  ⚠️ 失败"

# 总结
echo ""
echo "════════════════════════════════════════════════"
echo "  ✅ 完成。数据存储于 $DATA_ROOT"
echo ""
echo "  目录结构:"
find "$DATA_ROOT" -type f | head -20 | sed 's/^/    /'
echo "════════════════════════════════════════════════"
