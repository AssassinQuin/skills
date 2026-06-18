# 主语言优先搜索策略

用户方向 3："要根据相关语言，进行搜索，然后是中、英 进行补充搜索"。

借鉴 SkillsMP（9 语言 + 800+ 职业分类，多语言作为一等公民）。

## 核心原则

**主语言优先 → 英文补充 → 中文补充**（三层降级）。
- 三层都搜到 → 强信号（标注"多源验证"）
- 只搜到主语言 → 中信号（标注"本土热门，国际冷门"）
- 只搜到英文 → 弱信号（标注"国际有，本土无"）

**不歧视中文**：中文 trigger 与英文 trigger 等价，但**目标仓库的主语言**决定搜索词优先级。

## Step 1: 主语言检测（P1 阶段）

对用户输入的候选（或 P2 发现的 Top 候选）执行三层检测：

| 检测层 | 数据源 | 用途 |
|---|---|---|
| L1 编程语言 | GitHub repo metadata `language` 字段 | 判断仓库技术栈（HTML? Python? Rust?） |
| L2 文档语言 | README.md 前 100 行字符分布 | 判断目标用户语言（中/英/韩/日/...） |
| L3 触发器语言 | SKILL.md frontmatter `description` | 判断 AI 实际触发语言 |

**检测方法**（用 `ctx_execute_file` 避免全文进上下文）：

```python
import re
def detect_lang(text):
    # 韩文 Hangul
    if re.search(r'[가-힣]', text): return 'ko'
    # 日文假名
    if re.search(r'[぀-ゟ゠-ヿ]', text): return 'ja'
    # 中文 CJK（排除假名）
    if re.search(r'[一-鿿]', text): return 'zh'
    return 'en'
```

## Step 2: 按主语言调整 P5 社区源

| 主语言 | 优先源（本土） | 次要源（英文） | 第三层（中文） |
|---|---|---|---|
| **英文 (en)** | Reddit / Hacker News / Medium / Dev.to | （本身是英文） | 知乎 / V2EX / 掘金 / CSDN（看是否有中译讨论） |
| **中文 (zh)** | 知乎 / V2EX / 掘金 / CSDN / 微博 / 即刻 | Reddit / HN（看是否有国际关注） | （本身是中文） |
| **韩文 (ko)** | Naver Blog / Tistory / Namuwiki / Reddit r/korea | Reddit / HN / Medium | 知乎 / V2EX（看是否有中译） |
| **日文 (ja)** | Qiita / Zenn / Hatena / Twitter JP | Reddit / HN / Dev.to | 知乎 / V2EX |

## Step 3: 搜索词主语言化

按主语言调整搜索词模板（替换 Scout-Community 的 `{功能词}`）：

### 中文仓库示例（如 zh-CN skill）
```
# 优先（中文）
site:zhihu.com "{功能词中文}" skill
site:v2ex.com "{功能词中文}"
"{功能词中文}" skill 推荐 OR 评测 OR 踩坑

# 次要（英文）
site:reddit.com "{功能词英文}" skill
site:news.ycombinator.com "{功能词英文}"

# 第三层（再中文，看本土热度）
"{功能词中文}" site:weibo.com OR site:jike.city
```

### 韩文仓库示例（如 revfactory/harness）
```
# 优先（韩文）
site:blog.naver.com "{功能词韩文}"
site:tistory.com "{功能词韩文}"
"{功能词韩文}" skill 리뷰 OR 추천

# 次要（英文）
site:reddit.com "{功能词英文}" skill

# 第三层（中文，看中译）
"하네스" OR "revfactory" site:zhihu.com
```

## Step 4: 触发词等价化

中文 trigger 与英文 trigger 等价（**不歧视中文，不默认英文为优**）：

| 中文 trigger | 等价英文 trigger |
|---|---|
| 找 skill | find skill |
| skill 推荐 | recommend skill |
| skill 选型 | skill comparison |
| skill 横评 | skill comparison |
| 哪个 skill 好 | which skill is best |
| 有什么好的 X skill | what's a good X skill |
| skill 评测 | skill review |

frontmatter description **必须**列出中英双语 trigger，禁止只列英文。

## Step 5: 职业分类作为辅助轴（P3 阶段）

借鉴 SkillsMP 的 800+ 职业分类。对每个候选标注：

```
职业分类: 后端开发 / 数据科学 / DevOps / 内容创作 / 法务 / ...
```

用户场景如 "找金融合规的 skill" → 优先过滤 `职业分类=金融` 的候选。

## 与硬约束的关系

本策略是用户方向 3 的实现，对应硬约束新增条款（见 SKILL.md）：
- 硬约束 #9：**主语言优先** — P1 必须检测主语言，P5 必须按主语言调整源
- 硬约束 #10：**中英补充而非默认** — 禁止默认中英双语并行；按主语言三层降级
