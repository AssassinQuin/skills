# Evolution Context — skill-evolver

## R2 — 2026-06-02
- **策略**：S2+S3 融合（工作流重组 + 边界增强）
- **为什么改**：用户痛点信息丢失、无回归守卫、进化上下文未持久化
- **改了什么**：
  1. 新增 Mode G（痛点驱动进化）+ pain-points.jsonl 完整生命周期
  2. 部署回归守卫（>30% 回归率 → 自动回滚）+ FM-PP 失效模式
  3. evolution-context.md 追加式保存每轮 why+what+result
- **痛点解决**：PP-001(resolved: 痛点信息丢失), PP-002(resolved: 无回归检查), PP-003(resolved: 上下文未持久化)
- **结果**：评分 77 → 88（Δ +11），T_val 100%，审计 10/10 PASS
- **遗留**：Mode E 批量预算未显式定义；self-evolution.md meta 测试需同步
