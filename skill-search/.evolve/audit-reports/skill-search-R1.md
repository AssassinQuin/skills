# Audit Report: skill-search R1

## 5 维评分

| 维度 | Score | Weight | Weighted | Evidence |
|------|-------|--------|----------|----------|
| D1 Frontmatter | 8/10 | 10% | 0.80 | name+description完整,16触发词,allowed-tools 20个可达;缺user-invocable字段 |
| D2 Workflow | 7/10 | 20% | 1.40 | P1-P6覆盖完整,exit-checklist有量化门槛;但无工具层强制执行,search_code禁用无拦截 |
| D3 Boundary | 9/10 | 15% | 1.35 | 无脚本依赖,121行+254行references=375行,架构健康 |
| D4 Precision | 8/10 | 20% | 1.60 | 搜索词4组有示例,粗筛有量化阈值;P1"模糊"无判断标准,P6"Top3-5"范围宽 |
| D5 Empirical | 7/10 | 35% | 2.45 | T_val V1=PASS,V2=PASS,V3=PASS;无MCP降级方案 |

**Score**: 7.60/10
**Verdict**: PASS (6 WARN, 0 FAIL)

## T_val Results

| Prompt | Result | Notes |
|--------|--------|-------|
| V1: PDF skill | PASS | 功能词/同义词/上下游/生态词齐全 |
| V2: API docs + OpenAPI | PASS | 技术栈限定在P4深读时重点检查 |
| V3: 安全审计 skill | PASS | 搜索模板可直接套用 |

## WARN List

| # | Dim | Severity | Issue | Suggestion | FM |
|---|-----|----------|-------|-----------|----|
| 1 | D2 | WARN | exit-checklist无工具层强制 | 当前无破坏性操作可接受 | FM3 |
| 2 | D2 | WARN | search_code禁用无拦截 | P4增加回溯自检 | FM3 |
| 3 | D4 | WARN | "模糊输入"无判断标准 | 添加2-3个示例 | FM6 |
| 4 | D4 | INFO | "Top3-5"选择标准缺失 | 加规则:>=5选5,不足全保留 | FM6 |
| 5 | D5 | WARN | 无MCP不可用降级方案 | 添加fallback:GitHub→WebSearch | FM5 |
| 6 | D1 | INFO | 缺user-invocable字段 | 添加user-invocable:true | FM6 |

## Contamination Check: PASS (no leakage detected)
## Overfit Check: PASS (no overfitting signals)
