# IBM (NYSE: IBM) Q2 2026 暴雷深度研究底稿

> **研究日期**: 2026-07-21
> **事件**: CEO Arvind Krishna 于 2026-07-14 发布"致投资者公开信"，提前预警 Q2 业绩大幅不及预期
> **股价影响**: 单日暴跌 ~20-25%，市值蒸发约 $70B
> **正式财报**: 2026-07-22（研究完成时）

---

## 一、暴雷事件概览

### Q2 2026 预发布数据 vs 华尔街预期

| 指标 | Q2 2026 实际 | 华尔街共识 | 差异 |
|------|-------------|-----------|------|
| **总营收** | $17.2B (+1% YoY) | ~$17.86B | **miss ~$660M** |
| **调整后EPS** | $2.93 (+5% YoY) | ~$3.01-3.02 | **miss ~$0.08-0.09** |
| **GAAP EPS** | $2.27 (-2% YoY) | — | — |
| **Software** | +5% YoY | — | 不及预期 |
| **Consulting** | 持平 (+1% cc) | — | 不及预期 |
| **Infrastructure** | -7% YoY | — | 大幅不及预期 |
| **GAAP毛利率** | 57.7% (-100bps) | — | 收缩 |
| **Non-GAAP毛利率** | 59.4% (-70bps) | — | 收缩 |
| **GAAP税前利润率** | 14.4% (-90bps) | — | 收缩 |
| **Non-GAAP税前利润率** | 19.2% (+30bps) | — | — |
| **H1经营现金流** | $7.8B | — | — |
| **H1自由现金流** | $4.8B | — | — |

**数据来源**: [IBM CEO Letter to Investors, Jul 14 2026](https://newsroom.ibm.com/2026-07-14-Arvind-Krishnas-Letter-to-IBM-Investors)；[CNBC](https://www.cnbc.com/2026/07/14/ibm-warns-second-quarter-earnings-fell-short-of-expectations.html)；[Reuters](https://www.reuters.com/business/ibm-expects-second-quarter-revenue-below-estimates-2026-07-14/)

### CEO解释的核心原因（原文关键段落）

1. **z17 大型机周期预期落空**: 4月投资者日时，IBM预期 z17 是"史上最强开局"，Infrastructure 全年降幅为低个位数。实际Q2降幅达 -7%，远超预期。z17 关联的 Transaction Processing 软件栈同步下滑。
2. **客户资本开支重新优先级化**: 6月下旬，客户将季度 capex 转向服务器、存储、内存采购，以锁定供应紧张的基础设施资源并规避预期涨价——这部分预算原本可能流向 IBM 的软件和咨询。
3. **网络安全事件分散注意力**: 行业性网络安全事件分散了客户 IT 团队注意力，影响大单关闭节奏。
4. **IBM 自身执行失败**: CEO 原话——"we faltered. We did not adapt and move quickly enough, and numerous large deals failed to close on the timelines we expected."
5. **分布式基础设施意外亮眼**: Distributed Infrastructure 创历史最佳业绩（+37%），Power 和存储强劲增长，积压订单约 $500M。

---

## 二、五年财报深读（FY2021-2025 + Q2 2026）

### 2.1 利润表核心指标

| 指标（$B） | FY2021 | FY2022 | FY2023 | FY2024 | FY2025 | Q2 2026（单季度）|
|-----------|--------|--------|--------|--------|--------|-----------------|
| **总营收** | $57.4 | $60.5 | $61.9 | $62.8 | $67.5 | $17.2 |
| **营收YoY%** | +3%* | +5% | +2% | +1% | +7% | +1% |
| **净利润(GAAP)** | $5.8 | $1.6** | $7.5 | $6.0 | $10.6 | — |
| **调整后EPS** | — | — | — | — | — | $2.93 |

> *FY2021 含 Kyndryl 分拆前过渡期；**FY2022 净利润大幅下降因 Kyndryl 分拆的一次性费用

**数据来源**: [Macrotrends IBM Revenue](https://www.macrotrends.net/stocks/charts/IBM/ibm/revenue), [Macrotrends IBM Net Income](https://www.macrotrends.net/stocks/charts/IBM/ibm/net-income), [IBM 2025 Annual Report (SEC)](https://www.sec.gov/Archives/edgar/data/51143/000005114326000027/ibmars2025.pdf)

**5年趋势解读**:
- 营收从 $57.4B 增长到 $67.5B（+17.6%/5年），CAGR 约 3.3%——对科技巨头而言极低增速
- FY2022 净利润暴跌至 $1.6B（Kyndryl分拆），但 FY2023 回升至 $7.5B，FY2025 达 $10.6B——利润恢复主因成本削减和非经营性项目
- FY2025 营收增长 7% 看似亮眼，但 Q2 2026 立刻暴露增长不可持续

### 2.2 分部门营收

| 部门（$B） | FY2021 | FY2022 | FY2023 | FY2024 | FY2025 | 占2025营收% |
|-----------|--------|--------|--------|--------|--------|-----------|
| **Software** | ~$24.0 | ~$25.0 | ~$27.1 | ~$29.8 | ~$30.0 | ~44% |
| **Consulting** | ~$17.7 | ~$19.1 | ~$19.8 | ~$19.9 | ~$20.6 | ~31% |
| **Infrastructure** | ~$14.2 | ~$15.3 | ~$15.1 | ~$15.0 | ~$15.8 | ~23% |
| **Financing** | ~$0.3 | ~$0.3 | ~$0.4 | ~$0.3 | ~$0.4 | ~1% |

> 注：FY2021 为 Kyndryl 分拆后新结构，部门数据为近似值，基于 IBM 年报和分析师整理

**关键观察**:
- **Software 是唯一持续增长的引擎**，从 $24B 到 $30B（+25%/5年），主要由 Red Hat 驱动
- **Consulting 增长停滞**：5年仅从 $17.7B 到 $20.6B（+16%/5年），2024-2025 实质持平
- **Infrastructure 周期性极强**：大型机 z 周期主导波动，FY2023-2024 连续下滑，FY2025 z16 周期反弹后 Q2 2026 z17 再度失望
- **Red Hat 是 Software 增长核心**：收入从 2019 收购时的 ~$3.4B 增长到 2025 估计的 ~$6.5B（近乎翻倍），Q2 2026 增速加速至 11%
- **2025 年收购 HashiCorp 和 Confluent** 加强了 Software 组合，CEO 信中称两者"delivered strong performance"

**数据来源**: [IBM Annual Reports 2021-2025](https://www.ibm.com/investor/services/annual-report), [IBM Q4 2025 Earnings Release](https://newsroom.ibm.com/2026-01-28-IBM-RELEASES-FOURTH-QUARTER-RESULTS)

### 2.3 现金流与资本结构

| 指标（$B） | FY2021 | FY2022 | FY2023 | FY2024 | FY2025 |
|-----------|--------|--------|--------|--------|--------|
| **经营现金流** | $12.8 | — | — | — | — |
| **自由现金流** | ~$9.2 | ~$9.2 | ~$13.0 | ~$13.0 | ~$14.7 |
| **FCF/营收%** | ~16% | ~15% | ~21% | ~21% | ~22% |
| **长期债务** | ~$48.4 | ~$50.1 | ~$49.9 | ~$49.9 | ~$54.0-57.4 |

**数据来源**: [Macrotrends IBM FCF](https://www.macrotrends.net/stocks/charts/IBM/ibm/free-cash-flow), [Macrotrends IBM Balance Sheet](https://www.macrotrends.net/stocks/charts/IBM/ibm/balance-sheet), [Reuters](https://www.reuters.com/markets/companies/IBM/financials/balance-sheet-annual/)

**关键观察**:
- **自由现金流是 IBM 最亮眼指标**：从 $9.2B 持续增长到 $14.7B（+60%/5年），FCF margin 从 ~16% 提升到 ~22%
- 但 **FCF 质量需审视**：部分来自养老金风险转移释放现金（2024年转移 $6B 养老金义务至 Prudential，产生 $2.7B 非现金费用但改善了现金流）
- **长期债务维持高位**：$49-57B 区间，主要因收购驱动（Red Hat $34B, HashiCorp $6.4B, Confluent 未披露）
- **H1 2026 FCF $4.8B**：年化 ~$9.6B，暗示 FY2026 FCF 可能大幅低于 FY2025 的 $14.7B

### 2.4 养老金与会计复杂度

- IBM 通过两轮大规模养老金风险转移，将约 $14-22B 的 DB 养老金义务转移给保险公司（Prudential）
- 2024 年 Q3 记录 $2.7B 非现金税前费用
- 2024 年恢复 DB 计划（RBA），用超额资助的固定福利计划替代 401(k) 匹配
- **GAAP vs Non-GAAP 差距显著**：Q2 2026 GAAP 毛利率 57.7% vs Non-GAAP 59.4%（170bps差距）；GAAP 税前利润率 14.4% vs Non-GAAP 19.2%（480bps差距）

**数据来源**: [Reuters IBM Pension Charge](https://www.reuters.com/technology/ibm-take-27-bln-charge-related-transfer-pension-obligations-2024-09-11/), [PlanAdviser](https://www.planadviser.com/ibm-accused-of-22b-pension-risk-transfers-to-unsafe-insurer/)

### 2.5 股东回报

| 项目 | 2021-2025 |
|------|-----------|
| **年度分红** | ~$6.56-6.66/股，连续 12+ 年递增 |
| **股票回购** | 2021-2023 极少回购；2024.07 宣布 $15B 新授权 |
| **历史回购总额** | 历史上累计回购花费约 $80B+（NYT 报道 $138B），平均回购价 ~$66/股 |

**数据来源**: [IBM Dividend Page](https://www.ibm.com/investor/governance/ibm-cash-dividends), [IBM Buyback Authorization](https://www.ibm.com/investor/att/pdf/ircorner/07-04-24-1.pdf), [NYT DealBook](https://dealbook.nytimes.com/2014/10/20/the-truth-hidden-by-ibms-buybacks/)

---

## 三、四大师框架分析

### 3.1 段永平·生意本质

| 维度 | 评估 | 说明 |
|------|------|------|
| **客户粘性** | 🟡 | 大型机客户锁定效应极强（迁移成本极高），但客户基础在缩小（85% MIPs 客户维持/增长容量）；软件/咨询客户粘性一般 |
| **定价权** | 🟡 | 大型机有定价权但周期性波动大；Red Hat/OpenShift 定价权中等（面临开源替代）；传统软件定价权被 SaaS 模式侵蚀 |
| **Red Hat 增长引擎** | 🟢 | 5年近乎翻倍（$3.4B→$6.5B），Q2增速11%加速，HashiCorp+Confluent 补充 |
| **AI时代的生意质量** | 🔴 | CEO 自己承认 AI 投资挤压传统软件预算——AI 是 IBM 的威胁而非救赎；watsonx 市场份额极小 vs OpenAI/Copilot |
| **护城河趋势** | 🟡→🔴 | 大型机护城河在收窄（云原生替代加速）；Software 护城河依赖 Red Hat 但竞争加剧；Consulting 无差异化护城河 |
| **自由现金流** | 🟢 | 5年持续改善（$9.2B→$14.7B），FCF margin 22% 优秀 |

**综合判断**: IBM 不是"好生意"——它是一家正在被技术范式转移侵蚀的"曾经的好生意"。大型机锁定是真正的护城河，但护城河在缩小。Red Hat 是好的增长资产但不足以弥补传统业务的衰退。

### 3.2 巴菲特·财务质量

| 维度 | 信号 | 说明 |
|------|------|------|
| **GAAP vs Non-GAAP 差距** | 🟡 | Q2 税前利润率差距 480bps，主要因养老金转移等非现金项目。差距方向一致（GAAP < Non-GAAP），未发现激进收入确认 |
| **自由现金流趋势** | 🟢→🟡 | 5年持续增长至 $14.7B（优秀），但 H1 2026 年化 FCF 仅 ~$9.6B，可能大幅回落 |
| **高杠杆（收购驱动）** | 🔴 | 长期债务 $54-57B，因 Red Hat($34B)、HashiCorp($6.4B)、Confluent 等收购累积。NYT 报道历史回购 $138B 部分通过举债融资 |
| **养老金负债** | 🟡 | 已通过风险转移大幅削减（$6B+转移至 Prudential），但仍有残留义务；恢复 DB 计划增加未来负债风险 |
| **利润质量** | 🟡 | 净利润波动大（$1.6B→$10.6B），受一次性项目影响显著。调整后 EPS 增长稳定但 GAAP EPS 不稳定 |
| **股东回报优先级** | 🟡 | 偏好分红+回购（$15B授权），在高杠杆背景下是否合理存疑 |
| **赚的是真钱吗？** | 🟡 | FCF 真实且增长，但利润受非现金项目干扰大。H1 2026 FCF 大幅低于 run-rate 令人警惕 |

**综合判断**: IBM 的 FCF 是"真钱"，但利润表质量受会计复杂度拖累。高杠杆 + 激进股东回报是隐患。H1 2026 FCF 回落可能是早期恶化信号。

### 3.3 芒格·竞争格局

| 战场 | IBM 位置 | 主要对手 | 评估 |
|------|---------|---------|------|
| **云计算 IaaS** | 极小份额 | AWS, Azure, GCP | 🔴 IBM Cloud 市场份额微不足道；Azure 增长 34% 远超 IBM |
| **企业 SaaS** | 逐渐边缘化 | Microsoft 365/Dynamics, Oracle ERP, Salesforce | 🔴 微软生态锁定效应远强于 IBM |
| **混合云平台** | 有差异化 | VMware(Broadcom), OpenShift 生态 | 🟢 Red Hat OpenShift 是真正的竞争优势 |
| **AI 基础设施** | 几乎无存在感 | NVIDIA, AWS, Azure, Google | 🔴 IBM 不出售 GPU 基础设施，AI capex 狂潮受益有限 |
| **AI 企业软件** | 极小份额 | Microsoft Copilot, Google Gemini, Salesforce Einstein | 🟡 watsonx 存在但市场份额极小 |
| **AI 咨询服务** | 有竞争力 | Accenture, Deloitte, PwC | 🟡 IBM Consulting 有 GenAI 签约增长，但 Accenture 在 AI 服务领域更强 |
| **大型机** | 垄断 | 无直接对手 | 🟢 但市场在缩小，云原生替代加速 |
| **开源生态** | 领导地位 | Red Hat, CNCF | 🟢 Lightwell（$5B承诺）+ Red Hat + HashiCorp + Confluent = 强大开源矩阵 |

**什么会杀死 IBM？**
1. **大型机替代加速**: 云原生 + AI 驱动的工作负载迁移到 x86/ARM 云
2. **AI 投资持续挤压传统软件/咨询预算**: 如果这是结构性而非周期性，IBM 受伤最深
3. **Red Hat 增长放缓或人才流失**: Red Hat 是 IBM 唯一的真正增长引擎
4. **高杠杆下的利率风险**: $57B 长期债务对利率敏感
5. **量子计算商业化失败**: IBM 押注 $10B+ 在量子，2029 年交付容错量子计算机的目标极具风险

### 3.4 李录·风险信号

| 维度 | 评估 | 说明 |
|------|------|------|
| **公开信形式预警** | 🟡/🔴 | 非常规做法——正面解读是坦诚（CEO 直接说"we faltered"），负面解读是甩锅给宏观（AI预算挤压、供应链、网络安全），将执行失败归因于外部因素 |
| **转型叙事兑现率** | 🔴 | 过去 5 年的叙事主线：云→混合云→AI→量子，每次转型都承诺"回到增长"——FY2021-2024 营收 CAGR 仅 ~3%，说明转型叙事远未兑现 |
| **大单延迟关闭** | 🔴 | "numerous large deals failed to close"——这是销售质量的根本性问题，暴露出 IBM 在竞争激烈的软件市场缺乏足够的产品差异化来推动客户做决策 |
| **管理层可信度** | ★★☆☆☆ (2/5) | Krishna 接任 CEO（2020）以来：Kyndryl分拆改善了利润率但未驱动增长；Red Hat 整合算是成功；但营收增长始终低迷；Q2 暴雷暴露预期管理能力不足——4月刚给了正面 guidance，3个月后暴跌 |
| **$70B 市值蒸发** | 🔴 | 单日 -25% 的跌幅说明市场极度震惊，反映投资者对 IBM 管理层信任度的崩塌 |
| **Lightwell/Quantum 资本承诺** | 🟡 | $5B Lightwell + $10B+ 量子 5年计划——在 FCF 可能大幅下降的背景下，这些资本承诺是否审慎？ |

---

## 四、业务模式核心问题：IBM 的结构性困境

### 问题 1: 传统 IT 服务/软件被云原生 + AI 双重颠覆

**本质**: IBM 的核心业务（传统企业软件、IT 咨询、大型机）建立在前云计算时代的 IT 架构之上。云计算和 AI 正在同时从两个方向侵蚀这个基础：
- **云原生替代**: 工作负载从本地大型机/私有云迁移到 AWS/Azure/GCP 上的容器化微服务
- **AI 投资挤压**: 客户将有限 IT 预算优先投向 AI 基础设施（GPU 服务器、存储、网络），挤占传统软件/咨询预算

IBM CEO 7/14 的信明确承认了第二点——这是 IBM 高管首次公开承认 AI 繁荣对自身业务的负面影响，标志着叙事的根本转变。

### 问题 2: 大型机业务的高周期性 + 收缩市场

z17 是 IBM 的"现金牛引擎"（每代大型机周期 2-3 年，峰值年度贡献 $5B+ Infrastructure 营收）。Q2 2026 暴雷的核心之一就是 z17 周期开局不利：
- CEO 4月预期 z17 是"史上最强开局"，全年 Infrastructure 降幅仅低个位数
- 实际 Q2 Infrastructure -7%，z17 关联的 Transaction Processing 软件栈同步下滑
- CEO 归因于"客户 capex 转向通用服务器/存储以锁定供应"

更大的问题：**大型机安装基数在缩小**。虽然 85% MIPs 客户维持/增长容量，但基数在缩小意味着每次周期峰值更低。z17 的 130% program-to-program vs z16 听起来好，但 z16 本身基数更低。

### 问题 3: 收购驱动增长 + 高负债模式 + 转型叙事屡屡落空

- 2019 年以 $34B 收购 Red Hat，随后累计长期债务攀升至 $57B
- 2024-2025 年收购 HashiCorp（$6.4B）和 Confluent（金额未披露），继续加杠杆
- 每次收购后都伴随"回到增长"的叙事，但 5 年营收 CAGR 仅 ~3%
- 历史上 IBM 回购 $138B（部分通过举债），NYT 批评为"The Truth Hidden by IBM's Buybacks"
- **"价值陷阱"信号**: 低 P/E + 高分红 + 低增长 = 经典价值陷阱特征

### AI 为何"反噬"而非"拯救" IBM？

1. **IBM 不拥有 AI 基础设施层**: GPU 服务器由 Dell/HPE/Supermicro 出售，芯片由 NVIDIA/AMD 生产——IBM 无法从 AI capex 狂潮中直接受益
2. **AI 软件层被微软/Google 主导**: Copilot/Gemini 预装在数亿企业用户的 Office/Workspace 中，IBM watsonx 没有类似的分发渠道
3. **AI 咨询市场 Accenture 更强**: GenAI 咨询中 IBM 有签约增长，但 Accenture 以更大规模和更完整的 AI 服务栈领先
4. **AI 投资挤压了 IBM 最赚钱的业务**: 客户将预算从传统软件（高毛利 ~70%+）转向 AI 基础设施（低毛利硬件），IBM 不仅收入下降，利润结构也恶化
5. **IBM 的 AI 叙事（watsonx/量子）需要 3-5 年才能兑现**: 而 AI 挤压传统预算是现在发生的

---

## 五、行业周期定位

### 企业 IT 支出周期 + AI 投资周期

**当前位置**: AI 投资处于"过热期后期"，传统企业软件预算被结构性挤压。

| 信号 | 状态 |
|------|------|
| 全球 IT 支出总额（2026E） | $6.15 万亿，+10.8% YoY（Gartner） |
| 软件支出增速 | 14.7%，被下调（从 15.2%）|
| AI 基础设施支出 | 大幅飙升，"incredibly uneven"（CIO.com）|
| IT 服务被挤压 | "gets the squeeze"——直接命中 IBM 的核心业务 |
| 企业 AI ROI | 不足 1/3 企业报告可衡量的 AI 回报 |
| AI capex 见顶信号 | 尚未确认见顶，但 ROI 压力 + 预算重新分配 = 早期拐点信号 |

**关键判断**:
- **AI 投资挤压传统软件预算是结构性的，不是周期性的**。原因：AI 投资是"建设性"支出（build），传统软件是"维持性"支出（run）——在预算约束下，CIO 优先砍维持性支出。IBM 的传统软件和咨询恰好是最大的"维持性"支出类别之一。
- **AI capex 狂欢可能在 2026-2027 年见顶**：Gartner 下调软件增速是一个早期信号。如果 AI ROI 持续不达预期（目前 <1/3 企业有回报），2027 年可能出现 AI capex 回调 + 传统软件反弹的双向修正。
- **IBM 暴雷是"AI 反噬"的第一个大型案例**: 这不是 IBM 独有的问题——所有以传统企业软件/服务为核心的公司都面临同样的压力。IBM 因为营收增速最低、产品差异化最弱，所以最先暴露。

---

## 六、避雷信号清单

### "技术范式转移受害者"型暴雷的早期预警信号 Top 5

| # | 信号 | IBM 表现 | 通用识别方法 |
|---|------|---------|------------|
| **1** | **CEO 公开承认"我们搞砸了"** | Krishna 说"we faltered, did not move quickly enough" | 当 CEO 用"公开信"而非常规 earnings call 来预警，且用极端坦诚语言（faltered）时——说明问题严重到无法在常规框架内消化 |
| **2** | **大单延迟关闭 = 产品差异化不足** | "numerous large deals failed to close on the timelines we expected" | 大单延迟不一定是宏观问题——在竞争激烈的市场中，如果客户在"买你的 vs 买竞争对手的 vs 不买"之间犹豫，说明你的产品没有足够的差异化来推动决策。归因于"宏观/供应链/网络安全"往往是销售质量问题的借口 |
| **3** | **新技术同时创造机会和威胁，但威胁大于机会** | AI 挤压传统软件预算（威胁）> watsonx 收入增长（机会） | 当一家公司所处行业的范式转移（如云、AI、移动互联网）同时是其机会和威胁时，关键判断标准是：**该公司的核心能力是否可迁移到新范式？** IBM 的大型机能力无法迁移到云，传统咨询能力无法迁移到 AI 工程——答案是"否" |
| **4** | **转型叙事持续但营收增长持续低迷** | 5年营收 CAGR ~3%，叙事从云到 AI 到量子不断切换 | 当一家公司每隔 2-3 年切换一次"转型叙事"，但营收增速始终低于行业平均——说明管理层在用新叙事掩盖旧问题。"这次的转型会不同"是价值陷阱的经典诱饵 |
| **5** | **FCF 从高位突然回落 + 高杠杆** | FY2025 FCF $14.7B，但 H1 2026 年化仅 ~$9.6B（-35%）| FCF 是衡量企业质量的最终指标。如果 FCF 在高杠杆背景下突然大幅回落（排除已知的一次性因素），这是基本面恶化的早期信号——高杠杆意味着没有缓冲来吸收冲击 |

---

## 七、关键数据汇总

### 5年核心数据表

| 指标 | FY2021 | FY2022 | FY2023 | FY2024 | FY2025 |
|------|--------|--------|--------|--------|--------|
| 总营收($B) | $57.4 | $60.5 | $61.9 | $62.8 | $67.5 |
| 净利润($B) | $5.8 | $1.6 | $7.5 | $6.0 | $10.6 |
| 自由现金流($B) | ~$9.2 | ~$9.2 | ~$13.0 | ~$13.0 | ~$14.7 |
| Software营收($B) | ~$24.0 | ~$25.0 | ~$27.1 | ~$29.8 | ~$30.0 |
| 总债务($B) | ~$48.4 | ~$50.1 | ~$49.9 | ~$49.9 | ~$54-57 |
| 长期债务($B) | ~$48.4 | ~$50.1 | ~$49.9 | ~$49.9 | ~$54.0 |

---

## 数据来源

1. [IBM CEO Letter to Investors, Jul 14 2026](https://newsroom.ibm.com/2026-07-14-Arvind-Krishnas-Letter-to-IBM-Investors) — Q2 2026 预发布数据及 CEO 解释（一手来源）
2. [IBM 2025 Annual Report (SEC 10-K)](https://www.sec.gov/Archives/edgar/data/51143/000005114326000027/ibmars2025.pdf) — FY2025 官方数据（一手来源）
3. [IBM 2024 10-K (SEC EDGAR)](https://www.sec.gov/Archives/edgar/data/51143/000005114325000015/ibm-20241231_d2.htm) — FY2024 数据（一手来源）
4. [IBM Q4 2025 Earnings Release](https://newsroom.ibm.com/2026-01-28-IBM-RELEASES-FOURTH-QUARTER-RESULTS) — FY2025 确认数据
5. [Macrotrends IBM Revenue](https://www.macrotrends.net/stocks/charts/IBM/ibm/revenue) — 2012-2026 营收历史
6. [Macrotrends IBM Net Income](https://www.macrotrends.net/stocks/charts/IBM/ibm/net-income) — 2012-2026 净利润历史
7. [Macrotrends IBM FCF](https://www.macrotrends.net/stocks/charts/IBM/ibm/free-cash-flow) — 2012-2026 自由现金流历史
8. [Macrotrends IBM Balance Sheet](https://www.macrotrends.net/stocks/charts/IBM/ibm/balance-sheet) — 资产负债表历史
9. [Reuters IBM Financials](https://www.reuters.com/markets/companies/IBM/financials/balance-sheet-annual/) — 债务/负债数据
10. [CNBC IBM Q2 Warning](https://www.cnbc.com/2026/07/14/ibm-warns-second-quarter-earnings-fell-short-of-expectations.html) — 市场反应
11. [Reuters IBM AI Squeezing Budgets](https://www.reuters.com/business/ibm-expects-second-quarter-revenue-below-estimates-2026-07-14/) — AI 挤压分析
12. [Gartner 2026 IT Spending Forecast](https://www.gartner.com/en/newsroom/press-releases/2026-02-03-gartner-forecasts-worldwide-it-spending-to-grow-10-point-8-percent-in-2026-totaling-6-point-15-trillion-dollars) — 行业支出预测
13. [IBM Annual Reports 2021-2025](https://www.ibm.com/investor/services/annual-report) — 分部门数据
14. [IBM Dividend History](https://www.ibm.com/investor/governance/ibm-cash-dividends) — 分红历史
15. [Economic Times IBM $70B Wipeout](https://m.economictimes.com/markets/stocks/news/we-faltered-did-not-move-quickly-how-ibm-ceo-arvind-krishnas-statement-led-to-70-billion-wipeout/articleshow/132412961.cms) — 市值影响

---

*本底稿完成于 2026-07-21，基于公开可得信息。部分 FY2021-2023 部门数据为基于年报和分析师整理的近似值，精确数据请参考 IBM 官方 SEC 文件。正式 Q2 2026 财报及 management commentary 将于 2026-07-22 发布，届时需更新。*
