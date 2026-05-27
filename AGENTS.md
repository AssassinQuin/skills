# AGENTS.md — Skills Repository

> 本文件为维护指南，不纳入 git（含本地路径等私有信息）。

## 仓库定位

统一的 AI skill 库。6 个应用通过目录级软链接直接指向本仓库，增删 skill 无需额外操作。无构建系统、无测试、无 CI。

## 当前状态（27 skills）

### 分发方式（目录级软链接）

每个应用的 skills 目录直接 symlink 到本仓库：

```
~/.trae/skills/          → /Users/ganjie/skills
~/.config/opencode/skills/ → /Users/ganjie/skills
~/.opencode/skills/      → /Users/ganjie/skills
~/.claude/skills/        → /Users/ganjie/skills
~/.agents/skills/        → /Users/ganjie/skills
~/.cursor/skills/        → /Users/ganjie/skills
```

新增/删除 skill 后所有应用自动同步，无需手动操作。

### 初始化软链接

```bash
for dir in ~/.trae/skills ~/.config/opencode/skills ~/.opencode/skills ~/.claude/skills ~/.agents/skills ~/.cursor/skills; do
  rm -rf "$dir"
  ln -s /Users/ganjie/skills "$dir"
done
```

## 布局

```
<skill-name>/SKILL.md          — 顶层 skill 目录
<skill-name>/references/       — 可选参考文档
<skill-name>/scripts/          — 可选辅助脚本
huashu-nuwa/examples/          — 8 个生成的视角子 skill
planning-with-files/           — 独立 .git（嵌套 repo，非 submodule），含 IDE 子目录和 CI
```

## SKILL.md 格式

YAML frontmatter（必需：`name`, `description`）+ markdown body。可选字段：`allowed-tools`, `license`, `hidden`, `user-invocable`, `hooks`, `metadata.version`。
语言：主要是英文，部分中文（programmer, huashu-nuwa, pua-debugging），部分繁体中文（storytelling）。

## 已删除的损坏 Skill

- **webapp-testing** — 缺少 `scripts/with_server.py`（2026-04-28 删除）
- **slack-gif-creator** — 缺少 `core/gif_builder.py`（2026-04-28 删除）

## 上游仓库更新状态（2026-04-28）

### 嵌套 Git Repo（fork + upstream remote）

已 fork 到 AssassinQuin，在 skill 目录内 `git pull upstream <branch>` 即可更新：

| 技能 | Fork | Upstream | 分支 |
|------|------|----------|------|
| planning-with-files | AssassinQuin/planning-with-files | OthmanAdi/planning-with-files | master |
| darwin-skill | AssassinQuin/darwin-skill | alchaincyf/darwin-skill | master |
| humanizer | AssassinQuin/humanizer | blader/humanizer | main |

更新命令：
```bash
cd <skill-dir>
git fetch upstream
git merge upstream/<branch>
git push origin <branch>
```

### 普通目录（上游结构不兼容，手动更新 SKILL.md）

| 技能 | 上游仓库 | 最新版本/提交 | 状态 | 原因 |
|------|---------|-------------|------|------|
| skill-seekers | [yusufkaraaslan/Skill_Seekers](https://github.com/yusufkaraaslan/Skill_Seekers) | v3.5.1 | ✅ 已同步 | 上游是整个 Python 项目，只要 SKILL.md |
| huashu-nuwa | [alchaincyf/nuwa-skill](https://github.com/alchaincyf/nuwa-skill) | ea4b9ab | ✅ 已同步 | 仓库 18M+（含图片），clone 超时 |
| storytelling | [miles990/claude-domain-skills](https://github.com/miles990/claude-domain-skills) | dbd2fed | ✅ 已同步 | 上游 24 个 plugin，只要 storytelling |
| prose-craft | [obra/the-elements-of-style](https://github.com/obra/the-elements-of-style) | 6099c50 | ✅ 已同步 | 上游 6 个月无活动 |

### 本地生成 Skill（已确认无 GitHub 上游）

agent-browser, algorithmic-art, canvas-design, citation-sourcing, codemap, doc-coauthoring, docx, mcp-builder, pdf, pptx, programmer, pua-debugging, seo-optimization, simplify, skill-creator, social-media, theme-factory, transcript-cleanup, video-scripting, xlsx — 已通过 GitHub search 确认无上游仓库。

## Caveats

### 嵌套 Git Repo 策略（.gitignore + 独立管理）

`planning-with-files/`, `darwin-skill/`, `humanizer/` 是 **独立的嵌套 git repo**（非 submodule），已通过 `.gitignore` 排除在父仓库之外。

**原则**：父仓库不跟踪它们的任何状态变更，各自独立管理。

**克隆（如果本地没有）**：
```bash
# 如果 git clone 超时，用 gh CLI（走 SSH）
gh repo clone AssassinQuin/planning-with-files
gh repo clone AssassinQuin/humanizer
gh repo clone AssassinQuin/darwin-skill
```

**更新**：
```bash
cd <skill-dir>
git fetch upstream
git merge upstream/<branch>
git push origin <branch>
```

**父仓库提交不受影响**——嵌套 repo 的变更永远不会出现在 `git status` 中。

### huashu-nuwa

`huashu-nuwa/` 因仓库过大（18M+）未转为嵌套 repo，保持普通目录手动更新。
