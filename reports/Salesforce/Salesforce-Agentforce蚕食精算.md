# Salesforce (NYSE: CRM) Agentforce 商业化与自我蚕食精算

**作者**：Agentforce 蚕食精算分析师（串行检索 / 无子 agent）
**成文日期**：2026-07-22
**核心命题**：Agentforce 是 Salesforce 的新增长引擎，还是会蚕食其传统坐席订阅根基？

---

## 执行摘要（TL;DR）

- **事实层**：Agentforce ARR 从 FY26 Q1 的 ~$100M 飙升至 FY27 Q1 的 $1.2B（18 个月，+205% YoY），是 Salesforce 史上最快产品增长；FY26 总营收 $41.5B（+10%），FCF $14.4B（+16%）。
- **模式层**：Salesforce 在 18 个月内迭代了三种定价（$2/对话 → Flex Credits $0.10/action → per-user $125+/月），策略未定型反映在「增量 vs 替代」之间的对冲。
- **蚕食层**：全球坐席收入曝险 $80-120B；每个 agent 完成等量工作，per-seat 收入可能下降 70-90%。但 FY26 仍是「纯增量」——管理层未披露坐席数下降，NDR 未显著恶化。
- **临界点判断**：当 Agentforce ARR 突破 ~$3-4B（预计 FY28），坐席 ARPU 或客户坐席总数开始连续下滑，蚕食开始主导。在那之前，Data 360 + Informatica + MuleSoft 的捆绑大概率将蚕食延后 2-3 年。
- **最终判断**：Agentforce **短期（FY26-27）净增量，中期（FY28-29）转为混合，长期（FY30+）蚕食主导**——但只要 Salesforce 完成从「坐席收费」到「任务/agent 数收费」的价值锚迁移，长期收入净效应仍可能为正（管理层押注 agentic economy 是 SaaS economy 的 3-4x）。

---

## 1. Agentforce 商业模式拆解

### 1.1 三模式定价演变

Salesforce 在 18 个月内迭代了至少三套定价——这种反复在 SaaS 史上罕见，本身就是「如何给 AI agent 定价」的行业级难题的写照。

| 时间 | 模式 | 价格 | 单位经济学 | 适用场景 | 状态 |
|---|---|---|---|---|---|
| **2024-10** | Per-conversation | $2/次对话 | 简单但难预算；ROI 难映射 | 中小客户、初版 | 弃用/legacy |
| **2025-05** | Flex Credits（消耗制） | $500 / 100K credits ≈ **$0.10/action** | 最灵活；可按 prompt/action 拆分 | 客户面/员工面/Voice 全场景 | **主推（GA Q3 2025）** |
| **2025 下半年** | Per-user（坐席附加） | $125/user/month（Sales/Service/Field Service add-on）；Agentforce 1 Edition **$550/user/month**（全包） | 与传统坐席一致；客户预算可控 | 大企业、保守型客户 | 防蚕食对冲 |

来源：[Salesforce 官方定价页](https://www.salesforce.com/agentforce/pricing/)；[Saastr 分析](https://www.saastr.com/salesforce-now-has-3-pricing-models-for-agentforce-and-maybe-right-now-thats-the-way-to-do-it/)；[Aquiva Flex Credits 解读](https://aquiva.com/blog/agentforce-pricing-gets-a-long-overdue-fix-flex-credits-are-now-live)；[Constellation Research](https://constellationr.com/insights/news/salesforce-revamps-agentforce-pricing-flex-credits-what-you-need-know)。

### 1.2 哪种模式正成为主流？

**Flex Credits 已明确成为主推模式**（2025 Q3 GA）。原因：
1. 对客户：可按 action/prompt 精细计费，不被「对话」黑盒绑架；
2. 对 Salesforce：能在客户 AI 用量爆发时自然捕获上行（consumption-based 天然杠杆）。

但 **per-user 模式回归**（2025 下半年 $125 起）是关键信号：Salesforce 在客户保守偏好与自身收入稳定性之间做对冲——「如果客户自治度低，坐席模式能保住人工使用与黏性」（[Medium / Jens Eriksvik](https://medium.com/@jens.eriksvik/salesforce-agentforce-and-the-magical-return-of-the-seat-license-945a669c6f9b)）。

### 1.3 与传统坐席订阅的经济学对比

**核心单位经济学换算**（精算）：

- 传统 Sales/Service Cloud 坐席：$75-300/user/month → $900-3,600/user/year
- Agentforce Flex Credits：$0.10/action；假设一个 AI agent 替代一名人类坐席完成同等工作，每天执行 ~200 actions → **$20/天 ≈ $600/月 ≈ $7,300/年**
- **但**：一个 agent 可 24/7 工作，相当于 ~3 个人类 FTE 的产出，因此「同等产出」下 agent 路径可能只要坐席费用的 **20-35%**——这就是 Business Engineer AI 测算「per-seat revenue drop 70-90%」的来源（[Business Engineer](https://businessengineer.ai/p/salesforce-and-the-agentic-cannibalization)）。

**经济学含义**：对客户而言，从坐席切换到 agent 是 ~60-80% 的成本节约——这是蚕食的引力源。Salesforce 必须在 agent 体积上赚到 **3-5 倍**的任务数才能补回单位收入损失。

---

## 2. 商业化进展（最新数据）

### 2.1 ARR 增长轨迹（公司史上最快产品增长）

| 季度 | Agentforce ARR | YoY | 备注 |
|---|---|---|---|
| Q1 FY26（2025-04） | ~$100M | — | 起步 |
| Q3 FY26（2025-12） | **$540M** | +330% | 9,500 paid deals；3.2T tokens 消耗；Data 360 + Agentforce 合计 ARR ~$1.4B（+114%） |
| Q4 FY26（2026-02-25） | **$800M** | +169% | 29,000 paid deals 累计 15 个月（+50% QoQ）；production 客户 +50% QoQ；2.4B Agentic Work Units |
| Q1 FY27（2026-05） | **$1.2B** | +205% | 突破 $1B 里程碑；约占 total revenue **~1.5%** |

来源：[Salesforce Q3 FY26 IR](https://investor.salesforce.com/news/news-details/2025/Salesforce-Delivers-Record-Third-Quarter-Fiscal-2026-Results-Driven-by-Agentforce--Data-360/default.aspx)；[Q4 FY26 新闻稿](https://www.salesforce.com/news/press-releases/2026/02/25/fy26-q4-earnings/)；[Salesforce Ben Q1 FY27](https://www.salesforceben.com/salesforce-q1-results-agentforce-hits-1b-arr-as-benioff-takes-aim-at-ai-doubters/)；[Q1 FY27 Investor Deck](https://s205.q4cdn.com/626266368/files/doc_financials/2027/q1/CRM-Q1-FY27-Quarterly-Investor-Deck.pdf)。

### 2.2 客户与转化

- **付费 deals**：9,500（Q3 FY26）→ 29,000（Q4 FY26）→ 待 Q2 FY27 披露
- **Q4 FY26 单季新增 deals**：环比 +50%
- **免费→付费转化率**：公司未单独披露；以 deals 环比 +50% 与 ARR +48% QoQ 推算，转化效率显著改善
- **Pipeline 指标**：cRPO（current RPO）Q3 FY26 +11% YoY，是 Agentforce + Data 360 拉动的领先指标

### 2.3 Data 360 + Agentforce 捆绑协同

- Q3 FY26 合计 ARR ~$1.4B（+114% YoY）
- 捆绑逻辑：Agentforce 不能脱离 Data Cloud 运行（agent 的 ground truth 数据底座），客户用 Agentforce 必然拉动 Data 360 收入
- 这是 Salesforce 防止「裸 agent」被颠覆的核心护城河设计

### 2.4 管理层指引与兑现

- FY26 实际 $41.5B（+10%），多次上调 guidance
- Q2 FY27 guidance：$11.27-11.35B（+10-11% YoY，CC +10%）
- FY27 全年 guidance 上调
- **Agentforce 兑现度**：连续四个季度超预期，但公司至今未给 Agentforce ARR 单独的多年定量指引——这是蚕食担忧下「不想过度承诺」的典型信号

---

## 3. 蚕食风险精算（核心）

### 3.1 $80-120B 坐席收入曝险拆解

全球坐席收入曝险 $80-120B 的来源是 Salesforce 当前所有按坐席计费的产品（[Business Engineer AI](https://businessengineer.ai/p/salesforce-and-the-agentic-cannibalization)；[FourWeekMBA "SaaSpocalypse"](https://fourweekmba.com/salesforce-agentic-cannibalization-saaspocalypse/)）。按蚕食易感度排序：

| 细分 | 曝险程度 | 替代逻辑 | 时间窗 |
|---|---|---|---|
| **Service Cloud**（客服坐席） | 🔴 极高 | 客服对话 60-80% 可被 AI agent 自动化；Zendesk/ServiceNow 同样承压 | FY27-28 开始 |
| **Sales Cloud**（销售坐席） | 🟡 中高 | prospecting / follow-up / data entry 高度可自动化；但复杂谈判仍需人类 | FY28-30 |
| **Marketing Cloud**（营销坐席） | 🟡 中高 | 内容生成、journey 编排已大量被 agent 替代 | FY27-29 |
| **Tableau / MuleSoft**（分析师/集成坐席） | 🟢 中低 | 工作流仍需人类治理；agent 主要是增强而非替代 | FY30+ |
| **Field Service**（现场服务坐席） | 🟢 低 | 物理现场必须人在；agent 仅做调度优化 | FY30+ |

### 3.2 历史转型启示

| 公司 | 切换策略 | 速度 | 短期营收冲击 | 长期结果 |
|---|---|---|---|---|
| **Adobe（2013）** | 硬切换：永久许可 → CC 订阅 | 快 | FY13 营收 -8%；股价先跌 | $4.4B → $15B；股价 $30 → $600+；订阅户 700K → 30M+ |
| **微软（Office 365）** | 渐进：永久许可与订阅共存多年 | 慢 | 几乎无短期冲击 | 商业云营收 +114% 增长期；奠定 $245B 营收基础 |
| **Salesforce（Agentforce）** | 三模式并存对冲 | 延迟/未定 | FY26 仍是纯增量 | TBD |

**关键启示**：Adobe 的成功建立在「**主动承诺新模式**」之上，不试图保护旧模式；微软则通过共存换取平稳过渡但牺牲转型速度。Salesforce 当前的对冲姿态——既推广 Flex Credits 又强化 per-user 选项——表明它仍在两者之间摇摆，未做战略承诺。

### 3.3 增量 vs 替代的临界点

**精算模型**（基于公开数据估算，待核实）：

定义：
- ΔAgentforce ARR（增量）vs ΔLost Seat ARR（蚕食）

测算：
- 假设 Agentforce ARR 在 FY28 末达 **$3-4B**
- 假设同期坐席收入开始以 -2% 到 -3% 的年化速率收缩（Service Cloud 优先承压）
- Salesforce 当前坐席收入基础约 $38B（占 subscription 96%）
- -2% 坐席收缩 = **-$760M 年度坐席损失**
- 若此时 Agentforce 年新增 ARR > $1B，则 **净增量仍为正**
- **临界点**：当 Agentforce 年新增 ARR 增速放缓至 < 坐席损失率 × 坐席基数时（约 FY29-30），蚕食开始主导 P&L

**临界点 ARR 区间：$3-5B**（预计 FY28 末至 FY29 初）

### 3.4 Salesforce 的延缓策略

定价设计上已观察到三种延缓机制：

1. **三模式并存**：让保守客户留在 per-user，避免一次性切坐席；
2. **Agentforce 1 Edition $550/user/month 全包**：定价比传统坐席高 ~2-3 倍，鼓励客户「升级」而非「替换」——本质是「坐席溢价」而非「坐席消灭」；
3. **Data 360 捆绑**：agent 必须跑在 Data Cloud 上，Data Cloud 收入随 agent 增长而增长——创造第二增长曲线对冲坐席压力。

---

## 4. AI agent 对 CRM 商业模式的根本影响

### 4.1 「按人头收费」模式是否会被颠覆？

**短期（FY26-28）：不会**。坐席仍是 Salesforce 与客户的「商业关系锚」——签合同、预算审批、续约谈判都按坐席走。Agentforce 目前主要是「坐席附加」而非「坐席替代」。

**中期（FY28-30）：部分被颠覆**。Service Cloud 等高替代率细分率先进入「坐席下行 + agent 上行」的交叉区。

**长期（FY30+）：价值锚迁移**。如果 Salesforce 成功，价值锚将从「坐席数」转向「agent 数 × 任务复杂度 × 完成质量」——这是管理层押注的「agentic economy = 3-4× SaaS economy」逻辑（[Business Engineer](https://businessengineer.ai/p/salesforce-and-the-agentic-cannibalization)）。

### 4.2 收入是增是减？

- **如果 agent 真的自动化大量工作**：客户总支出意愿上升（因为 ROI 高），但**单位价值锚下移**——单个 agent 任务价格远低于单个坐席价格
- **净效应取决于 volume × price 杠杆**：volume 必须增长 5-10 倍以补偿 price 下降 70-90%
- **可能性**：管理层主张 volume 杠杆会赢——因为 agent 解锁了大量「人类坐席从未服务过」的长尾任务（中小企业、个人创业者、24/7 全球服务）

---

## 5. 竞争位势

### 5.1 主要对手对比

| 维度 | Salesforce Agentforce | Microsoft Copilot Studio | 自建（OpenAI/Anthropic API） | ServiceNow / Zendesk |
|---|---|---|---|---|
| **核心优势** | CRM 数据原生 + 工作流深度 | M365 生态 + 简便宜 | 灵活、无锁定 | 垂直场景强 |
| **定价** | 复杂、$0.10/action 起 | 简单、更便宜 per interaction | API 按 token 计 | 坐席 + AI 附加 |
| **最适合** | 客户面销售/服务自动化 | 内部知识工作 | 大企业定制 | IT 服务 / 客服垂直 |
| **颠覆风险** | Data 360 + Informatica 防线 | Microsoft Graph 替代 Data Cloud | 通用 agent 连 CRM | 被 Salesforce + 微软挤压 |

来源：[Royal Cyber 对比](https://www.royalcyber.com/blogs/salesforce/salesforce-agentforce-vs-microsoft-copilot-studio-ai-agents/)；[Smartbridge 2026 对比](https://smartbridge.com/salesforce-agentforce-vs-microsoft-copilot-studio-2026-comparison/)；[Clarity Arc 三方对比](https://www.clarityarc.com/insights/copilot-vs-agentforce-vs-build-your-own)。

### 5.2 Salesforce 的护城河能否抵御？

**能**——但有条件：
1. **数据护城河**：Salesforce 持有全球最深的客户 CRM 数据；Agentforce 直接跑在这些数据上，第三方 agent 难以匹敌上下文质量
2. **工作流护城河**：Sales 流程、Service 流程已嵌入客户运营；替换 CRM 比替换 AI 模型难 10 倍
3. **平台护城河**：Data 360 + MuleSoft + Informatica + Tableau + Slack 形成完整数据栈
4. **渠道护城河**：全球 150K+ 企业深度部署，决策 inertia 极强

### 5.3 客户偏好：在 CRM 里用 AI vs 用通用 AI 连 CRM？

**目前倾向 Salesforce 内置**（[Clarity Arc](https://www.clarityarc.com/insights/copilot-vs-agentforce-vs-build-your-own)）。原因：
- 数据治理与权限管理直接继承 CRM
- 合规风险更低（金融、医疗、政府）
- 集成成本低
- 但**长期风险**：如果 OpenAI/Anthropic 等通用 agent 平台建立「连接一切 CRM」的开放生态，Salesforce 可能被管道化（commoditize）

---

## 6. Informatica $8B 收购协同

### 6.1 交易事实

- **宣布**：2025-05-27
- **完成**：2025-11-18
- **对价**：~$8B 股权价值（扣除 Salesforce 已持股部分）
- 来源：[Salesforce 完成公告](https://www.salesforce.com/news/press-releases/2025/11/18/salesforce-completes-acquisition-of-informatica/)；[宣布公告](https://www.salesforce.com/news/press-releases/2025/05/27/salesforce-signs-definitive-agreement-to-acquire-informatica/)

### 6.2 对 Agentforce 的价值

- **核心定位**：与 Data 360、MuleSoft 共同构成「Agentforce 360 Platform」的数据底座
- **协同点**：Informatica 提供企业级数据治理、ETL/ELT、主数据管理——给 agent 提供「trusted, governed data」
- **战略意图**：解决 AI agent 最大痛点——hallucination 与数据不可信。没有干净的治理数据，agent 无法进入生产级部署

### 6.3 回报预期与整合风险

- **回报预期**：管理层未给量化指引；定性目标是「加速 Agentforce 大企业部署」
- **整合风险**：
  - Informatica 与 Data Cloud 在数据集成层有功能重叠
  - 文化整合：Informatica 是成熟 ETL 厂商，节奏与 Salesforce 高速迭代不同
  - 客户重叠：许多大企业同时用两家，整合后定价策略复杂
- **类比**：Slack 收购（$27.7B, 2021）整合节奏偏慢，是前车之鉴

---

## 7. 三情景 Salesforce 命运精算

### 情景 A：增量主导（概率 ~35%）

**假设**：
- Agentforce ARR：FY27 $2B → FY28 $4B → FY29 $7B（维持 +100% 增速）
- 坐席收入：FY27-29 仍 +5-7% 增长（agent 主要做增量任务，未替代坐席）
- 竞争：Salesforce 守住 CRM-native 优势
- Informatica 协同显著，大企业 pipeline 加速

**预测**：
| 年度 | 总营收 | 增速 | FCF |
|---|---|---|---|
| FY27 | $46B | +11% | $15.5B |
| FY28 | $52B | +13% | $17.5B |
| FY29 | $60B | +15% | $20B |

**Salesforce 命运**：**AI 时代的赢家**——成功从坐席收费迁移到 agent 收费，市值重回 $400B+。

### 情景 B：混合（概率 ~45%，基准情景）

**假设**：
- Agentforce ARR：FY27 $1.8B → FY28 $3B → FY29 $4.5B（增速逐步放缓至 +50%）
- 坐席收入：FY27 +3% → FY28 -1% → FY29 -3%（Service Cloud 率先承压）
- 竞争：微软 Copilot 在 M365 客户中分流；自建 agent 在大企业兴起
- Informatica 整合平稳但缓慢

**预测**：
| 年度 | 总营收 | 增速 | FCF |
|---|---|---|---|
| FY27 | $45B | +9% | $15B |
| FY28 | $48B | +7% | $15.5B |
| FY29 | $51B | +6% | $16.5B |

**Salesforce 命运**：**稳态现金流机器**——增速降档至个位数，但 FCF 强劲，加大回购与分红，成为「value with AI optionality」标的。

### 情景 C：蚕食主导（概率 ~20%）

**假设**：
- Agentforce ARR：FY27 $1.5B → FY28 $2.2B → FY29 $3B（增速快速下滑至 +30%）
- 坐席收入：FY27 +1% → FY28 -5% → FY29 -10%（Service Cloud + Sales Cloud 同时承压）
- 竞争：OpenAI/Anthropic 通用 agent 平台通过开放连接颠覆 CRM 护城河
- Informatica 整合失败或被微软 Fabric 反击

**预测**：
| 年度 | 总营收 | 增速 | FCF |
|---|---|---|---|
| FY27 | $44B | +6% | $14B |
| FY28 | $43B | -2% | $13B |
| FY29 | $41B | -5% | $12B |

**Salesforce 命运**：**被颠覆（缓慢版）**——CRM 数据仍是护城河，但商业模式被管道化，估值倍数压缩至 15× earnings。

---

## 8. 结论 + 验证标准

### 8.1 净效应结论

**短期（FY26-27）**：Agentforce **明确是增量引擎**——$1.2B ARR 占比仅 1.5%，远未触达蚕食临界点；坐席收入仍 +5-7% 增长。

**中期（FY28-29）**：**进入混合区**——Service Cloud 坐席开始下行，Agentforce 增量部分对冲。净效应取决于 Agentforce ARR 能否在 FY28 突破 $3-4B 临界点。

**长期（FY30+）**：**蚕食主导但净效应可能仍为正**——前提是 Salesforce 完成「坐席数 → 任务数/agent 数」的价值锚迁移，且 agent volume 增长 5-10 倍补偿单位价格下降。

**总判断**：Agentforce **是引擎也是威胁**，二者并存。Salesforce 当前最大的战略资产是**时间**——用 Data 360 + Informatica + 三模式定价的对冲设计，争取 2-3 年窗口完成价值锚迁移。

### 8.2 Salesforce 能否完成商业模式迁移？

**能，但有条件**：
1. Agentforce ARR 在 FY28 末 ≥ $4B（验证 volume 杠杆启动）
2. 坐席 ARPU 不出现连续 4 个季度下滑（验证升级溢价有效）
3. NDR 维持 ≥ 110%（验证客户总支出仍在扩张）
4. Informatica 整合在 FY27 末贡献可量化 ARR（验证数据底座战略）

### 8.3 关键观察点（Top 3 验证标准）

#### 🎯 #1：Agentforce ARR 增速 vs 坐席收入增速的剪刀差
- 每季度跟踪：Agentforce ARR 同比增速 vs Core Subscription 坐席部分增速
- 若 Agentforce 增速 > 100% 且 Core Subscription 增速 > 5% → 增量主导（情景 A）
- 若 Agentforce 增速降至 < 50% 且 Core Subscription 增速 < 2% → 蚕食主导（情景 C）

#### 🎯 #2：付费客户数 + Production 部署比例
- Q4 FY26 数据：29,000 paid deals；production 客户 +50% QoQ
- 重点跟踪：paid deals 环比、production 转化率、 expansions/deal size
- 信号：expansion 比例上升 = 客户在「升级坐席到 Agentforce 1 Edition」而不是「减少坐席」

#### 🎯 #3：Service Cloud 营收 vs Sales Cloud 营收的分化
- Service Cloud 是最易被蚕食的细分
- 若 Service Cloud 增速明显低于 Sales Cloud（差距 > 5pp），说明蚕食正在 Service Cloud 先发生
- 这是最早可观察的蚕食信号

### 8.4 最大不确定性

**「agentic economy 3-4× SaaS economy」假设的真伪**——这是 Salesforce 整个战略的底层押注。若假设为真，volume 杠杆足以补偿 price 下降，长期净效应为正；若假设为伪（agent 完成的任务总量没想象中大），蚕食将主导，Salesforce 难逃被管道化命运。

---

## 附：关键数据源

- [Salesforce Q4 FY26 新闻稿](https://www.salesforce.com/news/press-releases/2026/02/25/fy26-q4-earnings/)
- [Salesforce Q3 FY26 IR](https://investor.salesforce.com/news/news-details/2025/Salesforce-Delivers-Record-Third-Quarter-Fiscal-2026-Results-Driven-by-Agentforce--Data-360/default.aspx)
- [Salesforce Q1 FY27 IR](https://investor.salesforce.com/news/news-details/2026/Salesforce-Delivers-Record-First-Quarter-Fiscal-2027-Results/default.aspx)
- [Q1 FY27 Investor Deck PDF](https://s205.q4cdn.com/626266368/files/doc_financials/2027/q1/CRM-Q1-FY27-Quarterly-Investor-Deck.pdf)
- [Agentforce 官方定价页](https://www.salesforce.com/agentforce/pricing/)
- [Salesforce 完成 Informatica 收购公告](https://www.salesforce.com/news/press-releases/2025/11/18/salesforce-completes-acquisition-of-informatica/)
- [Business Engineer AI：Salesforce & Agentic Cannibalization](https://businessengineer.ai/p/salesforce-and-the-agentic-cannibalization)
- [FourWeekMBA：SaaSpocalypse](https://fourweekmba.com/salesforce-agentic-cannibalization-saaspocalypse/)
- [Saastr：Salesforce 3 Pricing Models](https://www.saastr.com/salesforce-now-has-3-pricing-models-for-agentforce-and-maybe-right-now-thats-the-way-to-do-it/)
- [Wedbush：Software-mageddon](https://investor.wedbush.com/wedbush/article/marketminute-2026-2-16-software-mageddon-the-800-billion-tech-selloff-and-the-death-of-the-saas-model)
- [Medium / Jens Eriksvik：Agentforce 与坐席回归](https://medium.com/@jens.eriksvik/salesforce-agentforce-and-the-magical-return-of-the-seat-license-945a669c6f9b)
- [Salesforce Ben：Q1 FY27 Agentforce 突破 $1B](https://www.salesforceben.com/salesforce-q1-results-agentforce-hits-1b-arr-as-benioff-takes-aim-at-ai-doubters/)

---

*报告基于 2026-07-22 前公开信息；标注「待核实」的数据点需在公司下一季度财报或投资者日进一步确认。*
