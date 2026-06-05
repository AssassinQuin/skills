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

## R4 — 2026-06-05
- **策略**：v4 重写（去补丁化）
- **为什么改**：补丁式设计导致流程不被遵守。评分公式定义5处漂移，痛点概念泄露14处，没有Quick Fix路径，脚本不做流程控制
- **改了什么**：
  1. SKILL.md 重写为薄路由层（333→156行），零补丁标记
  2. 新建 references/constants.md 作为唯一定义源
  3. evolve.sh 扩展流程控制（phase-check、phase-start、quick-fix-check）
  4. 删除死目录 references/phases/（6文件，含过期阈值）
  5. 所有 modules/ 去重，统一引用 constants.md
  6. 双路径：Quick Fix（问题明确时）+ Full Evolution（未知问题时）
- **痛点解决**：PP-4 → addressed
- **结果**：待审计
- **遗留**：无
