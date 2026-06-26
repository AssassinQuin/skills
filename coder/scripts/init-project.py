#!/usr/bin/env python3
"""coder 项目初始化 — 智能合并生成项目级 agent / hook / 流程。

设计见 coder/.deepen/20260625-project-init/design.md。
参考 oh-story-claude 的 intelligent-merge 模式（不覆盖，markers 之间合并）。
"""
from __future__ import annotations

import argparse
import json
import os
import re
import shutil
import subprocess
import sys
from datetime import date
from pathlib import Path

# ---- coder skill 路径解析 ----
SCRIPT_DIR = Path(__file__).resolve().parent
CODER_DIR = SCRIPT_DIR.parent
TEMPLATES_DIR = CODER_DIR / "templates"
SKILL_MD = CODER_DIR / "SKILL.md"

# ---- coder 版本 ----
def read_coder_version() -> str:
    if not SKILL_MD.exists():
        return "5.0"
    text = SKILL_MD.read_text(encoding="utf-8")
    m = re.search(r'(?m)^\s*version:\s*"([^"]+)"', text)
    return m.group(1) if m else "5.0"


CODER_VERSION = read_coder_version()
INIT_DATE = date.today().isoformat()


# ---- 项目语言/框架检测 ----
def detect_language(project_dir: Path, override: str | None) -> str | None:
    if override:
        return override
    checks = [
        ("go.mod", "go"),
        ("pyproject.toml", "python"),
        ("setup.py", "python"),
        ("requirements.txt", "python"),
        ("package.json", "typescript"),
        ("Cargo.toml", "rust"),
    ]
    for filename, lang in checks:
        if (project_dir / filename).exists():
            return lang
    return None


def detect_lang_version(project_dir: Path, lang: str) -> str:
    try:
        if lang == "go":
            mod = project_dir / "go.mod"
            if mod.exists():
                for line in mod.read_text().splitlines():
                    if line.startswith("go "):
                        return line.split()[1]
        elif lang == "python":
            pp = project_dir / "pyproject.toml"
            if pp.exists():
                m = re.search(r'(?m)^python\s*=\s*"([^"]+)"', pp.read_text())
                if m:
                    return m.group(1)
        elif lang == "typescript":
            pj = project_dir / "package.json"
            if pj.exists():
                data = json.loads(pj.read_text())
                return (data.get("devDependencies", {}).get("typescript")
                        or data.get("dependencies", {}).get("typescript")
                        or "?")
        elif lang == "rust":
            ct = project_dir / "Cargo.toml"
            if ct.exists():
                m = re.search(r'(?m)^edition\s*=\s*"([^"]+)"', ct.read_text())
                if m:
                    return m.group(1)
    except Exception:
        pass
    return "?"


def detect_pkg_manager(project_dir: Path, lang: str) -> str:
    if lang == "go":
        return "go modules"
    if lang == "python":
        for lock, mgr in [("poetry.lock", "poetry"), ("uv.lock", "uv"),
                          ("pdm.lock", "pdm")]:
            if (project_dir / lock).exists():
                return mgr
        return "pyproject" if (project_dir / "pyproject.toml").exists() else "pip"
    if lang == "typescript":
        for lock, mgr in [("pnpm-lock.yaml", "pnpm"), ("yarn.lock", "yarn")]:
            if (project_dir / lock).exists():
                return mgr
        return "npm"
    if lang == "rust":
        return "cargo"
    return "unknown"


def detect_framework(project_dir: Path, lang: str) -> str:
    try:
        if lang == "go":
            mod = project_dir / "go.mod"
            if mod.exists():
                content = mod.read_text()
                for pkg, fw in [("gin-gonic/gin", "gin"), ("labstack/echo", "echo")]:
                    if pkg in content:
                        return fw
            return "stdlib"
        if lang == "python":
            pp = project_dir / "pyproject.toml"
            if pp.exists():
                content = pp.read_text()
                for pkg, fw in [("fastapi", "FastAPI"), ("flask", "Flask"),
                                ("django", "Django"), ("typer", "Typer CLI")]:
                    if pkg in content:
                        return fw
            return "stdlib"
    except Exception:
        pass
    return "unknown"


def detect_test_cmd(lang: str, pkg: str) -> str:
    return {
        "go": "go test ./...",
        "python": {
            "poetry": "poetry run pytest",
            "uv": "uv run pytest",
            "pdm": "pdm run pytest",
        }.get(pkg, "pytest"),
        "typescript": "npm test",
        "rust": "cargo test",
    }.get(lang, "?")


def detect_lint_cmd(lang: str, pkg: str) -> str:
    return {
        "go": "golangci-lint run",
        "python": {
            "poetry": "poetry run ruff check .",
            "uv": "uv run ruff check .",
        }.get(pkg, "ruff check ."),
        "typescript": "npm run lint",
        "rust": "cargo clippy",
    }.get(lang, "?")


# ---- 模板渲染 ----
GOTCHA_TAG_TEMPLATE = "coding-{lang}-gotcha"

PLACEHOLDER_DEFAULTS = {
    "MODULE_BOUNDARIES": "（init 时未自动检测，请项目维护者填写本项目模块边界约束）",
    "COMMON_TARGETS": "（请补充：make targets / npm scripts）",
    "PROJECT_HARD_CONSTRAINTS": "（请补充：本项目硬约束，如禁止跨包 import、public API 变更需 semver 等）",
    "PROJECT_HARD_CONSTRAINTS_REVIEW": "（请补充：审查时检查的项目硬约束清单）",
    "PROJECT_CODESTYLE": "（请补充：项目命名 / 布局 / import 顺序惯例）",
    "NAMING_CONVENTION": "（请补充）",
    "LAYOUT_TYPE": "（请补充）",
    "MAIN_PACKAGES": "（请补充）",
    "MAKE_TARGETS": "（请补充）",
    "PACKAGE_LAYOUT": "（请补充）",
    "TEST_FRAMEWORK": "（请补充）",
    "TYPE_CHECKER": "（请补充）",
    "FORMAT_CMD": "（请补充）",
    "TYPE_CMD": "（请补充）",
    "BUILD_CMD": "",
    "MODULE_PATH": "",
    "PROJECT_SPECIFIC_CMDS": "",
    "SOURCE_DIR": "src",
    "PROJECT_CLAUDE_DIR": ".",
}


def render_template(tpl_path: Path, ctx: dict) -> str:
    content = tpl_path.read_text(encoding="utf-8")
    gotcha_tag = GOTCHA_TAG_TEMPLATE.format(lang=ctx["PRIMARY_LANG"])
    ctx = dict(ctx)
    ctx.update(PLACEHOLDER_DEFAULTS)
    ctx["INITIAL_GOTCHAS"] = f"（init 时未发现明显坑；后续 reviewer 发现的坑请写到 memory MCP [{gotcha_tag}] tag）"
    ctx["INITIAL_GOTCHAS_REVIEW"] = f"（init 时未发现；后续 reviewer 发现的新坑 MUST 写 memory MCP [{gotcha_tag}] tag）"
    ctx.setdefault("PYTHON_VERSION", ctx["LANG_VERSION"])
    ctx.setdefault("GO_VERSION", ctx["LANG_VERSION"])
    ctx.setdefault("PACKAGE_NAME", ctx["PROJECT_NAME"])
    ctx.setdefault("SERVICE_NAME", ctx["PROJECT_NAME"])

    # 替换所有 {{VAR}} 占位符
    def replace(match):
        key = match.group(1)
        return ctx.get(key, match.group(0))

    return re.sub(r"\{\{(\w+)\}\}", replace, content)


# ---- 智能合并 ----
def merge_with_markers(target: Path, rendered: str, start_marker: str, end_marker: str,
                       force: bool, dry_run: bool) -> str:
    """返回 action 描述。markers 之间内容替换，其他保留。"""
    if not target.exists():
        if not dry_run:
            target.parent.mkdir(parents=True, exist_ok=True)
            target.write_text(rendered, encoding="utf-8")
        return f"created: {target}"

    existing = target.read_text(encoding="utf-8")
    if start_marker not in existing:
        return f"skipped (no managed marker, use --force): {target}"

    # 提取新的 managed section
    new_section = extract_between(rendered, start_marker, end_marker)
    pattern = re.compile(
        re.escape(start_marker) + r".*?" + re.escape(end_marker),
        re.DOTALL,
    )
    backup_path = target.with_suffix(target.suffix + f".bak.{INIT_DATE}")
    if not dry_run:
        shutil.copy2(target, backup_path)
        new_content = pattern.sub(start_marker + "\n" + new_section + "\n" + end_marker, existing)
        target.write_text(new_content, encoding="utf-8")
    return f"merged (backup: {backup_path.name})"


def extract_between(text: str, start: str, end: str) -> str:
    pattern = re.compile(re.escape(start) + r"(.*?)" + re.escape(end), re.DOTALL)
    m = pattern.search(text)
    return m.group(1).strip() if m else ""


def merge_settings_json(settings_path: Path, fragment_rendered: str,
                        dry_run: bool) -> str:
    """合并 hooks 字段到 settings.json（去重 + backup）。"""
    fragment = json.loads(fragment_rendered)

    if not settings_path.exists():
        if not dry_run:
            settings_path.parent.mkdir(parents=True, exist_ok=True)
            settings_path.write_text(json.dumps(fragment, indent=2, ensure_ascii=False),
                                     encoding="utf-8")
        return f"created: {settings_path}"

    target = json.loads(settings_path.read_text(encoding="utf-8"))
    backup_path = settings_path.with_suffix(settings_path.suffix + f".bak.{INIT_DATE}")

    if not dry_run:
        shutil.copy2(settings_path, backup_path)

    target.setdefault("hooks", {})
    frag_hooks = fragment.get("hooks", {})
    for event, entries in frag_hooks.items():
        if not entries:
            continue
        target["hooks"].setdefault(event, [])
        existing_cmds = {
            h.get("command")
            for entry in target["hooks"][event]
            for h in entry.get("hooks", [])
        }
        for entry in entries:
            new_cmds = {h.get("command") for h in entry.get("hooks", [])}
            if new_cmds - existing_cmds:
                target["hooks"][event].append(entry)

    target["_coder_init_meta"] = fragment.get("_coder_init_meta", {})

    if not dry_run:
        settings_path.write_text(
            json.dumps(target, indent=2, ensure_ascii=False),
            encoding="utf-8",
        )
    return f"merged hooks (backup: {backup_path.name})"


# ---- 主流程 ----
def main() -> int:
    parser = argparse.ArgumentParser(description="coder 项目初始化")
    parser.add_argument("project_dir", nargs="?", default=".", help="项目目录（默认当前目录）")
    parser.add_argument("--force", action="store_true", help="强制覆盖 managed section")
    parser.add_argument("--dry-run", action="store_true", help="只打印，不写文件")
    parser.add_argument("--lang", default=None, help="覆盖语言检测")
    args = parser.parse_args()

    project_dir = Path(args.project_dir).resolve()
    if not project_dir.exists():
        print(f"ERROR: project dir not found: {project_dir}", file=sys.stderr)
        return 1

    if not TEMPLATES_DIR.exists():
        print(f"ERROR: templates dir not found: {TEMPLATES_DIR}", file=sys.stderr)
        return 1

    # 检测
    primary_lang = detect_language(project_dir, args.lang)
    if not primary_lang:
        print("ERROR: 无法检测项目语言。用 --lang={go|python|typescript|rust} 显式指定。",
              file=sys.stderr)
        return 1

    lang_version = detect_lang_version(project_dir, primary_lang)
    pkg_manager = detect_pkg_manager(project_dir, primary_lang)
    framework = detect_framework(project_dir, primary_lang)
    project_name = project_dir.name
    test_cmd = detect_test_cmd(primary_lang, pkg_manager)
    lint_cmd = detect_lint_cmd(primary_lang, pkg_manager)

    ctx = {
        "PROJECT_NAME": project_name,
        "PRIMARY_LANG": primary_lang,
        "LANG_VERSION": lang_version,
        "PKG_MANAGER": pkg_manager,
        "FRAMEWORK": framework,
        "TEST_CMD": test_cmd,
        "LINT_CMD": lint_cmd,
        "DATE": INIT_DATE,
        "CODER_VERSION": CODER_VERSION,
    }

    print("==> 检测结果：")
    for k, v in ctx.items():
        print(f"    {k.lower():12}: {v}")
    print()

    if args.dry_run:
        print("(dry-run 模式，不写文件)")

    if primary_lang in ("typescript", "rust"):
        print(f"WARN: {primary_lang} 模板尚未完整支持，将仅生成 reviewer agent。")

    claude_dir = project_dir / ".claude"
    agents_dir = claude_dir / "agents"
    hooks_dir = claude_dir / "hooks"

    # ---- 1. agents ----
    print("==> 1. 生成项目 agent")
    lang_tpl_map = {
        "go": "go-coder.template.md",
        "python": "python-coder.template.md",
    }
    if primary_lang in lang_tpl_map:
        tpl = TEMPLATES_DIR / "agents" / lang_tpl_map[primary_lang]
        rendered = render_template(tpl, ctx)
        agent_file = agents_dir / f"{primary_lang}-coder-project.md"
        if not args.dry_run:
            agent_file.parent.mkdir(parents=True, exist_ok=True)
            agent_file.write_text(rendered, encoding="utf-8")
        print(f"    -> {agent_file}")
    else:
        print(f"    (skipped: no template for {primary_lang})")

    reviewer_tpl = TEMPLATES_DIR / "agents" / "project-reviewer.template.md"
    reviewer_rendered = render_template(reviewer_tpl, ctx)
    reviewer_file = agents_dir / "project-reviewer.md"
    if not args.dry_run:
        reviewer_file.parent.mkdir(parents=True, exist_ok=True)
        reviewer_file.write_text(reviewer_rendered, encoding="utf-8")
    print(f"    -> {reviewer_file}")

    # ---- 2. hook 脚本 ----
    print("==> 2. 复制 hook 脚本")
    for hook in ["edit-guard.sh", "git-guard.sh", "phase-guard.sh",
                 "spec-guard.sh", "signature-guard.sh", "task-progress-guard.sh",
                 "session-load.sh", "session-resume.sh", "spawn-trace.sh"]:
        src = TEMPLATES_DIR / "hooks" / "scripts" / hook
        if not src.exists():
            continue
        dst = hooks_dir / hook
        if not args.dry_run:
            dst.parent.mkdir(parents=True, exist_ok=True)
            shutil.copy2(src, dst)
            dst.chmod(0o755)
        print(f"    -> {dst}")

    # ---- 2b. git 分支管理脚本 ----
    print("==> 2b. 复制 git 分支管理脚本")
    git_scripts_src = TEMPLATES_DIR / "scripts" / "git"
    git_scripts_dst = claude_dir / "scripts" / "git"
    if git_scripts_src.exists():
        for src in git_scripts_src.iterdir():
            if src.suffix != ".sh":
                continue
            dst = git_scripts_dst / src.name
            if not args.dry_run:
                dst.parent.mkdir(parents=True, exist_ok=True)
                shutil.copy2(src, dst)
                dst.chmod(0o755)
            print(f"    -> {dst}")

    # ---- 2c. v6.0 state + delivery 校验脚本 ----
    print("==> 2c. 复制 v6.0 state + delivery 校验脚本")
    v6_scripts = [
        ("coder-state.sh", "scripts/coder-state.sh"),
        ("coder-state.py", "scripts/coder-state.py"),
        ("validate-delivery.py", "scripts/validate-delivery.py"),
    ]
    for src_name, dst_rel in v6_scripts:
        src = CODER_DIR / "scripts" / src_name
        if not src.exists():
            continue
        dst = claude_dir / dst_rel
        if not args.dry_run:
            dst.parent.mkdir(parents=True, exist_ok=True)
            shutil.copy2(src, dst)
            dst.chmod(0o755)
        print(f"    -> {dst}")

    # 创建 state 目录结构
    if not args.dry_run:
        (claude_dir / "coder-state" / "specs-active").mkdir(parents=True, exist_ok=True)
        (claude_dir / "coder-state" / "archive").mkdir(parents=True, exist_ok=True)
        print(f"    -> {claude_dir}/coder-state/{{specs-active,archive}}/")

    # ---- 3. settings.json ----
    print("==> 3. 合并 settings.json")
    fragment_path = TEMPLATES_DIR / "hooks" / "settings.json.fragment"
    fragment_text = fragment_path.read_text(encoding="utf-8")
    fragment_text = fragment_text.replace("${PROJECT_CLAUDE_DIR}", ".")
    fragment_text = fragment_text.replace("${CODER_VERSION}", CODER_VERSION)
    fragment_text = fragment_text.replace("${DATE}", INIT_DATE)

    settings_path = claude_dir / "settings.json"
    action = merge_settings_json(settings_path, fragment_text, args.dry_run)
    print(f"    {settings_path}: {action}")

    # ---- 4. CLAUDE.md ----
    print("==> 4. 合并 CLAUDE.md")
    claude_md = project_dir / "CLAUDE.md"
    claude_md_tpl = TEMPLATES_DIR / "CLAUDE.md.template"
    claude_md_rendered = render_template(claude_md_tpl, ctx)
    start = "<!-- coder-init: project-context start -->"
    end = "<!-- coder-init: project-context end -->"
    action = merge_with_markers(claude_md, claude_md_rendered, start, end,
                                 args.force, args.dry_run)
    print(f"    {claude_md}: {action}")

    # ---- 5. init metadata ----
    print("==> 5. 写 init 元数据")
    init_meta = {
        "project_name": project_name,
        "primary_lang": primary_lang,
        "lang_version": lang_version,
        "pkg_manager": pkg_manager,
        "framework": framework,
        "init_date": INIT_DATE,
        "coder_version": CODER_VERSION,
        "project_path": str(project_dir),
    }
    init_meta_path = claude_dir / ".coder-initialized.json"
    if not args.dry_run:
        init_meta_path.parent.mkdir(parents=True, exist_ok=True)
        init_meta_path.write_text(
            json.dumps(init_meta, indent=2, ensure_ascii=False),
            encoding="utf-8",
        )
    print(f"    -> {init_meta_path}")

    # ---- 6. .gitignore ----
    gitignore = project_dir / ".gitignore"
    coder_entries = [
        ".claude/coder-trace.jsonl",
        ".claude/.coder-edit-counter",
        ".claude/*.bak.*",
    ]
    if not args.dry_run and gitignore.exists():
        existing = gitignore.read_text(encoding="utf-8") if gitignore.exists() else ""
        if "coder-trace.jsonl" not in existing:
            with gitignore.open("a", encoding="utf-8") as f:
                f.write("\n# coder init artifacts\n")
                for entry in coder_entries:
                    f.write(f"{entry}\n")
            print("==> 6. 更新 .gitignore")
    elif not args.dry_run and not gitignore.exists():
        # 没有就跳过——不强行创建（用户可能用 hg 或其他）
        pass

    print()
    print("==> ✅ 初始化完成")
    print()
    print("下一步：")
    print(f"  1. 编辑 {claude_md} 填充模块边界 / 硬约束")
    if primary_lang in lang_tpl_map:
        print(f"  2. 编辑 {agents_dir}/{primary_lang}-coder-project.md 填充项目特定内容")
    print("  3. 跑一次 coder skill 验证 hook 生效")
    print()
    print(f"卸载：删除 {claude_dir}/ + 项目 CLAUDE.md 的 markers 之间内容")
    return 0


if __name__ == "__main__":
    sys.exit(main())
