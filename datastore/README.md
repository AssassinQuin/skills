# Datastore：指数深度研究数据本地存储

> **目的**：存放指数深度研究的真实数据（成分股、财报、宏观、报告），避免 LLM 用训练知识估算。

## 目录结构

```
datastore/
├── README.md                              # 本文件
├── indices/                               # 按指数代码组织
│   ├── 930740/                            # 沪深300红利低波
│   │   ├── meta.json                      # 指数编制规则（fetch-csindex 抓）
│   │   ├── holdings/                      # 跟踪 ETF 季报重仓
│   │   │   ├── 515300-2026-Q1.json       # 前十大重仓（fetch-fund-pdf 抓）
│   │   │   └── ...
│   │   ├── constituents/                  # 完整成分股（基于 ETF 全量持仓）
│   │   │   ├── 515300-2026-Q1-all.tsv    # --topline 80 抓全量
│   │   │   └── ...
│   │   ├── financials/                    # 重仓股财报 PDF（巨潮）
│   │   │   ├── 601088-中国神华/
│   │   │   │   ├── 2024-年报.pdf
│   │   │   │   ├── 2024-年报.json         # LLM 解析后
│   │   │   │   └── ...
│   │   │   └── ...
│   │   ├── macro/                         # 宏观周期对照
│   │   │   ├── gdp.json
│   │   │   ├── cpi.json
│   │   │   └── index-cycles.json          # 指数在不同周期收益
│   │   └── reports/                       # 基于真实数据的报告
│   │       └── 2026-07-deep-dive.md
│   └── 000300/                            # 沪深300
│       └── ...
└── cache/                                 # 通用缓存（API 响应等）
```

## 数据来源（信息源等级 T0-T3）

| 数据类型 | T0 首选 | T1 备选 | T2 末选 | T3 禁用 |
|---|---|---|---|---|
| 指数编制规则 | 中证指数官网 | 蛋卷/理杏仁 | 东方财富 | UGC |
| ETF 重仓股 | 东方财富 FundArchivesDatas | 天天基金 | 新浪 | 雪球 |
| 个股年报 | 巨潮资讯 PDF | 基金公司官网 | 同花顺 F10 | UGC |
| 国债收益率 | 中债登 | 中国货币网 | 英为财情 | UGC |
| 利率体系 | 中国货币网 | LPR 官方 | 东方财富 | UGC |
| GDP/CPI | 国家统计局 | 中金/中信研报 | 财联社 | UGC |

## 工具调用流程

### 指数深度研究（8 模块）

```bash
INDEX=930740
ETF=515300  # 跟踪 ETF

# 1. 指数基本信息
python3 ~/.claude/tools/ai-berkshire/fetch-csindex.py --index $INDEX --field info > indices/$INDEX/meta.json

# 2. 当前重仓股（前 10）
python3 ~/.claude/tools/ai-berkshire/fetch-fund-pdf.py --fund $ETF --topline 10 > indices/$INDEX/holdings/$ETF-2026-Q1.json

# 3. 完整成分股（前 50，作为指数样本代理）
python3 ~/.claude/tools/ai-berkshire/fetch-fund-pdf.py --fund $ETF --topline 80 > indices/$INDEX/constituents/$ETF-2026-Q1-all.json

# 4. 每个重仓股的年报 PDF URL
for code in 601088 600938 601857 000895 000651; do
  python3 ~/.claude/tools/ai-berkshire/fetch-stock-financials.py --code $code --keyword "年度报告" > indices/$INDEX/financials/$code-reports.json
done

# 5. 国债收益率曲线（T0）
python3 ~/.claude/tools/ai-berkshire/fetch-chinabond.py --type 国债 > indices/$INDEX/macro/yield-curve.json

# 6. 宏观数据（WebSearch 拉 GDP/CPI/PMI）
python3 ~/.claude/tools/ai-berkshire/fetch-macro-data.py --type gdp --years 5
```

## 数据时效性

每个数据文件必须在末尾含 `fetched_at` 字段（ISO 时间）。数据 > 90 天需重新抓取。

## 8 模块研究流程

1. **指数基本信息**：编制规则、基日、成分数量、加权方式
2. **当前估值**：PE/PB/股息率 + 历史分位
3. **成分股保留分析**：哪些公司连续多期保留（5 年+），业绩如何
4. **重仓股财报深度**：前 5 大重仓的近 5 年收入/利润/现金流
5. **宏观周期对照**：指数在历次衰退/复苏/过热/滞胀的表现
6. **行业 / 因子暴露**：行业偏置、因子载荷
7. **风险清单**：成分股集中度、行业政策、估值高位
8. **持有建议**：基于真实数据给"持有 / 减仓 / 加仓"建议

详见 `~/.claude/commands/index-deep-research.md`。
