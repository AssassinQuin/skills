# Skills

统一的 AI 技能库，集中管理 Claude、OpenCode、Trae、Cursor、Agents 等工具共享的技能文件。

所有技能通过软链接分发到各工具的 skills 目录，一处修改全局生效。

## 技能一览（27 个）

| # | 技能 | 用途 | 来源 | 大小 |
|---|------|------|------|------|
| 1 | **agent-browser** | 浏览器自动化：导航、填表、截图、数据提取、Web 应用测试 | 本地生成 | 4K |
| 2 | **algorithmic-art** | 用 p5.js 创建算法艺术、生成艺术、流场、粒子系统 | 本地生成 | 64K |
| 3 | **canvas-design** | 用设计哲学创建海报、艺术、静态视觉作品（.png/.pdf） | 本地生成 | 5.5M |
| 4 | **citation-sourcing** | 引用来源分级、格式化、验证模式，防止幻觉 | 本地生成 | 8K |
| 5 | **codemap** | 为不熟悉的代码库生成全面的层级化代码地图 | 本地生成 | 36K |
| 6 | **darwin-skill** | 达尔文技能优化器：8 维评分、爬山优化、测试验证 | [GitHub](https://github.com/alchaincyf/darwin-skill) | 72K |
| 7 | **doc-coauthoring** | 结构化文档协作流程：写文档、提案、技术规格 | 本地生成 | 16K |
| 8 | **docx** | Word 文档创建/编辑/分析，支持修订、批注、格式保留 | 本地生成 | 1.3M |
| 9 | **huashu-nuwa** | 女娲造人：深度调研→思维框架提炼→生成人物 Skill | [GitHub](https://github.com/alchaincyf/nuwa-skill) | 18M |
| 10 | **humanizer** | 去除 AI 写作痕迹，检测修复 29 种 AI 写作模式 | [GitHub](https://github.com/blader/humanizer) (adapted) | 28K |
| 11 | **mcp-builder** | 构建 MCP 服务器集成外部 API（Python/Node） | 本地生成 | 144K |
| 12 | **pdf** | PDF 操作：提取文本/表格、创建、合并/拆分、填表 | 本地生成 | 92K |
| 13 | **planning-with-files** | Manus 风格文件计划：task_plan.md, findings.md, progress.md | [GitHub](https://github.com/OthmanAdi/planning-with-files) | 1.4M |
| 14 | **pptx** | PPT 创建/编辑/分析、布局、批注、演讲备注 | 本地生成 | 1.3M |
| 15 | **programmer** | 全流程编程引擎：记忆检索→考古→调研→拆解→实现→校验 | 本地生成 | 60K |
| 16 | **prose-craft** | 文档写作质量优化：声音建立、选词纠正、LLM 弱点修复 | [GitHub](https://github.com/obra/the-elements-of-style) (ref) | 148K |
| 17 | **pua-debugging** | 强制穷举式问题解决：失败2次后触发，杜绝放弃 | 本地生成 | 20K |
| 18 | **seo-optimization** | SEO 内容优化：页面因素、E-E-A-T、语义 SEO、GEO | 本地生成 | 48K |
| 19 | **simplify** | 简化代码：在不改变行为的前提下提升可读性 | 本地生成 | 16K |
| 20 | **skill-creator** | 创建新技能的指南和工作流 | 本地生成 | 72K |
| 21 | **skill-seekers** | 从文档网站、GitHub 仓库、PDF 转换为 Claude Skill | [GitHub](https://github.com/yusufkaraaslan/Skill_Seekers) | 8K |
| 22 | **social-media** | 社交媒体帖子写作：平台格式、字数限制、语气 | 本地生成 | 16K |
| 23 | **storytelling** | 故事创作：小说写作、漫画脚本、影片企划、角色塑造 | [GitHub](https://github.com/miles990/claude-domain-skills) | 16K |
| 24 | **theme-factory** | 主题样式工具包：10 个预设主题，适用于幻灯片/文档/网页 | 本地生成 | 180K |
| 25 | **transcript-cleanup** | 清理语音转文字输出：修复语音伪影，保留说话者声音 | 本地生成 | 8K |
| 26 | **video-scripting** | 视频脚本/TTS 脚本：节奏、钩子结构、语音过渡 | 本地生成 | 16K |
| 27 | **xlsx** | 电子表格创建/编辑/分析：公式、格式、数据可视化 | 本地生成 | 24K |

### huashu-nuwa 内含子技能（8 个视角 Skill）

通过女娲造人技能生成的人物视角 Skills，位于 `huashu-nuwa/examples/`：

| 视角 Skill | 来源 | 调研日期 |
|------------|------|----------|
| andrej-karpathy-perspective | Karpathy 博文/访谈/X 帖子（20+来源） | 2026-04-05 |
| feynman-perspective | 费曼书籍/演讲/访谈（40+来源） | 2026-04-04 |
| munger-perspective | 《穷查理宝典》/股东会/演讲（50+来源） | 2026-04-04 |
| naval-perspective | Naval 著作/播客/推文 | 2026-04-04 |
| paul-graham-perspective | PG 文章/播客/批评者（200+来源） | 2026-04-05 |
| taleb-perspective | 塔勒布《不确定性》系列/访谈（40+来源） | 2026-04-04 |
| x-mastery-mentor | Cole/Bush/Bloom/Welsh/Koe/Hormozi + X 算法 | 2026-04-06 |
| zhang-yiming-perspective | 张一鸣访谈/决策案例（32片段/12案例） | 2026-04-06 |

## 来源分类

### 有外部上游仓库（可检查更新）

| 技能 | 上游仓库 | 最新版本/提交 | 本地状态 | 备注 |
|------|---------|-------------|---------|------|
| planning-with-files | [OthmanAdi/planning-with-files](https://github.com/OthmanAdi/planning-with-files) | 2026-04-21 `v2.35.0` | ✅ 已是最新 | Hermes adapter + NLPM audit |
| skill-seekers | [yusufkaraaslan/Skill_Seekers](https://github.com/yusufkaraaslan/Skill_Seekers) | 2026-04-26 `v3.5.1` | 🔴 高优先更新 | C3.x 语言过滤修复 + defaults.json 重构 |
| humanizer | [blader/humanizer](https://github.com/blader/humanizer) | 2026-04-01 `#80` | ⚠️ 待更新 | 新增被动语态规则 + OpenCode 支持 |
| darwin-skill | [alchaincyf/darwin-skill](https://github.com/alchaincyf/darwin-skill) | 2026-04-21 `2056abf` | ⚠️ 待更新 | banner 扩展 + 异常边界条件 + 自评优化 74→80 |
| huashu-nuwa | [alchaincyf/nuwa-skill](https://github.com/alchaincyf/nuwa-skill) | 2026-04-23 `ea4b9ab` | ⚠️ 待更新 | Bloome 合作展示 + hero banner |
| storytelling | [miles990/claude-domain-skills](https://github.com/miles990/claude-domain-skills) | 2026-01-20 `dbd2fed` | ⚠️ 待更新 | 上游已重构为扁平 plugin 结构（24 个独立 plugin） |
| prose-craft | [obra/the-elements-of-style](https://github.com/obra/the-elements-of-style) | 2025-10-18 `6099c50` | ✅ 上游无新提交 | 用 Strunk 原则重写 |

### 本地/自定义生成（已确认无 GitHub 上游源）

agent-browser, algorithmic-art, canvas-design, citation-sourcing, codemap, doc-coauthoring, docx, mcp-builder, pdf, pptx, programmer, pua-debugging, seo-optimization, simplify, skill-creator, social-media, theme-factory, transcript-cleanup, video-scripting, xlsx

## 软链接分发

技能文件集中存储在本仓库，通过软链接分发到各工具目录（每个工具 27 个）：

```
~/.trae/skills/            → 27 个技能
~/.config/opencode/skills/ → 27 个技能
~/.opencode/skills/        → 27 个技能
~/.claude/skills/          → 27 个技能
~/.agents/skills/          → 27 个技能
~/.cursor/skills/          → 27 个技能
```

### 添加/修复软链接

```bash
# 为所有工具目录创建缺失的软链接
for dir in ~/.trae/skills ~/.config/opencode/skills ~/.opencode/skills ~/.claude/skills ~/.agents/skills ~/.cursor/skills; do
  mkdir -p "$dir"
  for skill in /Users/ganjie/skills/*/; do
    name=$(basename "$skill"); [ "$name" = "README.md" ] && continue
    [ -e "$dir/$name" ] || ln -s "$skill" "$dir/$name"
  done
done
```

## 已删除的损坏 Skill（2026-04-28）

| 技能 | 问题 |
|------|------|
| ~~webapp-testing~~ | 缺少 `scripts/with_server.py` 依赖脚本 |
| ~~slack-gif-creator~~ | 缺少 `core/gif_builder.py` 依赖脚本 |

## 质量分级

### 高质量（完整的参考文件和脚本）
darwin-skill, docx, pptx, canvas-design, prose-craft, humanizer, seo-optimization, huashu-nuwa, mcp-builder, programmer, xlsx, skill-creator, theme-factory

### 精简但自足
citation-sourcing, transcript-cleanup, video-scripting, social-media, pua-debugging, simplify, storytelling, algorithmic-art, agent-browser, skill-seekers, doc-coauthoring, codemap
