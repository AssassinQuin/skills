#!/usr/bin/env python3
"""validate-delivery.py — Phase 4.5 子 agent 交付校验。

读子 agent 输出末尾的 delivery YAML 块，按 7 条规则校验。
不合格 → 退出码非 0 + 输出返工理由。

Usage:
    validate-delivery.py <agent-output.md> [--git-diff] [--allowed-deps <comma-sep>]
"""
from __future__ import annotations

import argparse
import re
import subprocess
import sys
from pathlib import Path

try:
    import yaml
except ImportError:
    print("ERROR: 需要 PyYAML。pip install pyyaml", file=sys.stderr)
    sys.exit(2)


REQUIRED_FIELDS = {
    "agent": str,
    "task_id": str,
    "phase": str,
    "inputs_received": list,
    "outputs": dict,
    "verification_self": dict,
    "handoff": dict,
}

OUTPUTS_FIELDS = {
    "files_changed": list,
    "new_dependencies": list,
    "drift_score": (int, float),
}

VERIFICATION_KEYS = {"lint", "type_check", "tests", "build"}

HANDOFF_KEYS = {"to_reviewer", "to_orchestrator"}


def extract_delivery_yaml(content: str) -> str | None:
    """从 agent 输出末尾提取 ```yaml ... ``` 块（含 'delivery:' 顶字段）。"""
    pattern = re.compile(r"```ya?ml\n(.*?)\n```", re.DOTALL)
    matches = pattern.findall(content)
    # 从后往前找含 delivery: 的
    for m in reversed(matches):
        if re.search(r'(?m)^delivery:', m):
            return m
    return None


def get_git_diff_files() -> set[str]:
    """获取当前 git diff 的文件列表（已 staged + unstaged + untracked）。"""
    files = set()
    try:
        # staged + unstaged
        out = subprocess.check_output(
            ["git", "diff", "--name-only", "HEAD"], stderr=subprocess.DEVNULL
        ).decode()
        files.update(out.strip().splitlines())
        # untracked
        out = subprocess.check_output(
            ["git", "ls-files", "--others", "--exclude-standard"], stderr=subprocess.DEVNULL
        ).decode()
        files.update(out.strip().splitlines())
    except subprocess.CalledProcessError:
        pass
    return {f for f in files if f}


def validate(delivery_yaml: str, actual_files: set[str] | None,
             allowed_deps: set[str]) -> tuple[bool, list[str]]:
    """返回 (is_valid, violations)。"""
    violations: list[str] = []

    try:
        data = yaml.safe_load(delivery_yaml)
    except yaml.YAMLError as e:
        return False, [f"YAML 解析失败: {e}"]

    if not isinstance(data, dict) or "delivery" not in data:
        return False, ["缺少顶层 'delivery' 字段"]

    d = data["delivery"]

    # 规则 1: 必填字段
    for field, expected_type in REQUIRED_FIELDS.items():
        if field not in d:
            violations.append(f"缺少必填字段: delivery.{field}")
        elif not isinstance(d[field], expected_type):
            violations.append(f"delivery.{field} 类型错误（期望 {expected_type}）")

    if violations:
        return False, violations  # 后续规则依赖这些字段

    # 规则 2: files_changed vs git diff
    outputs = d["outputs"]
    for f in OUTPUTS_FIELDS:
        if f not in outputs:
            violations.append(f"缺少 delivery.outputs.{f}")

    if actual_files is not None:
        declared_files = {f["path"] for f in outputs.get("files_changed", []) if isinstance(f, dict)}
        missing = actual_files - declared_files
        extra = declared_files - actual_files
        if missing:
            violations.append(f"声明 files_changed 漏了实际改动的文件: {sorted(missing)}")
        if extra:
            violations.append(f"声明 files_changed 含未实际改动的文件: {sorted(extra)}")

    # 规则 3: drift_score < 0.4
    drift = outputs.get("drift_score", 0)
    if isinstance(drift, (int, float)) and drift >= 0.4:
        violations.append(
            f"drift_score={drift} ≥ 0.4，触发 adaptive control（需 oracle 重新分解）"
        )

    # 规则 4: verification_self 至少 1 PASS
    verification = d["verification_self"]
    pass_count = sum(1 for k in VERIFICATION_KEYS
                     if str(verification.get(k, "")).upper() == "PASS")
    if pass_count < 1:
        violations.append(
            f"verification_self 至少 1 项 PASS（当前 {pass_count}/{len(VERIFICATION_KEYS)}）"
        )

    # 规则 5: new_dependencies
    new_deps = set(outputs.get("new_dependencies", []))
    if new_deps and not new_deps.issubset(allowed_deps):
        illegal = new_deps - allowed_deps
        violations.append(
            f"new_dependencies 含未在 spec.allowed_deps 的依赖: {sorted(illegal)}"
        )

    # 规则 6: known_caveats < 5
    caveats = d.get("known_caveats", [])
    if isinstance(caveats, list) and len(caveats) >= 5:
        violations.append(
            f"known_caveats 数量 {len(caveats)} ≥ 5，建议拆任务或先解决部分"
        )

    # 规则 7: handoff.to_reviewer.focus_areas 至少 1 项
    handoff = d["handoff"]
    to_reviewer = handoff.get("to_reviewer", {})
    focus_areas = to_reviewer.get("focus_areas", [])
    if not isinstance(focus_areas, list) or len(focus_areas) < 1:
        violations.append("handoff.to_reviewer.focus_areas 至少 1 项（reviewer 需聚焦点）")

    return len(violations) == 0, violations


def main():
    parser = argparse.ArgumentParser(description="Phase 4.5 子 agent delivery 校验")
    parser.add_argument("agent_output", help="子 agent 输出文件（.md）")
    parser.add_argument("--git-diff", action="store_true",
                        help="对比 git diff 实际文件")
    parser.add_argument("--allowed-deps", default="",
                        help="spec 允许的新依赖（逗号分隔）")
    args = parser.parse_args()

    content = Path(args.agent_output).read_text(encoding="utf-8")
    delivery_yaml = extract_delivery_yaml(content)

    if not delivery_yaml:
        print("❌ BLOCK: 末尾未找到 delivery YAML 块（```yaml ... ``` 含 'delivery:'）",
              file=sys.stderr)
        print("   子 agent 必须按 templates/delivery-schema.yaml 格式输出", file=sys.stderr)
        return 1

    actual_files = get_git_diff_files() if args.git_diff else None
    allowed_deps = {d.strip() for d in args.allowed_deps.split(",") if d.strip()}

    is_valid, violations = validate(delivery_yaml, actual_files, allowed_deps)

    if is_valid:
        print("✅ delivery 校验通过")
        # 输出关键摘要
        try:
            data = yaml.safe_load(delivery_yaml)["delivery"]
            print(f"   agent: {data['agent']}")
            print(f"   task_id: {data['task_id']}")
            print(f"   drift: {data['outputs'].get('drift_score', '?')}")
            print(f"   files: {len(data['outputs'].get('files_changed', []))}")
            print(f"   focus_areas: {data['handoff']['to_reviewer'].get('focus_areas', [])}")
        except Exception:
            pass
        return 0
    else:
        print("❌ BLOCK: delivery 校验失败", file=sys.stderr)
        for v in violations:
            print(f"   - {v}", file=sys.stderr)
        print()
        print("返工建议：", file=sys.stderr)
        print("  1. 修复上述违规", file=sys.stderr)
        print("  2. 重新跑 Phase 4 spawn", file=sys.stderr)
        print("  3. drift_score ≥ 0.4 时回 Phase 3 重新分解", file=sys.stderr)
        return 1


if __name__ == "__main__":
    sys.exit(main())
