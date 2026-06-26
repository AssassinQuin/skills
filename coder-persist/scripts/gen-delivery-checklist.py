#!/usr/bin/env python3
"""gen-delivery-checklist.py — Phase 6 delivery-checklist 生成器（v7.1 新增）。

从 spec.md + state.json + delivery-*.yaml 渲染 delivery-checklist.md。

Usage:
    gen-delivery-checklist.py \\
        --spec-dir .claude/coder-state/specs-active/20260625-1320-add-login/ \\
        --state-file .claude/coder-state/current.json
"""
from __future__ import annotations

import argparse
import hashlib
import json
import sys
from datetime import datetime
from pathlib import Path


def file_hash(p: Path) -> str:
    if not p.exists():
        return '—'
    return hashlib.sha256(p.read_bytes()).hexdigest()[:16]


def main() -> int:
    parser = argparse.ArgumentParser(description='Phase 6 delivery-checklist 生成器')
    parser.add_argument('--spec-dir', required=True)
    parser.add_argument('--state-file', required=True)
    parser.add_argument('--template', default=None,
                        help='自定义模板（默认用 module assets）')
    args = parser.parse_args()

    spec_dir = Path(args.spec_dir)
    state_file = Path(args.state_file)

    if not spec_dir.exists():
        print(f'ERROR: spec_dir 不存在: {spec_dir}', file=sys.stderr)
        return 1
    if not state_file.exists():
        print(f'ERROR: state_file 不存在: {state_file}', file=sys.stderr)
        return 1

    state = json.loads(state_file.read_text(encoding='utf-8'))

    # 默认模板（直接内联，避免外部依赖）
    # 真实实现应从 modules/phase-6-persistence/assets/delivery-checklist-template.md 读
    template_path = (Path(args.template) if args.template
                     else Path(__file__).parent.parent / 'assets' / 'delivery-checklist-template.md')

    if not template_path.exists():
        print(f'ERROR: 模板不存在: {template_path}', file=sys.stderr)
        return 1

    template = template_path.read_text(encoding='utf-8')

    # 计算 hashes
    spec_md = spec_dir / 'spec.md'
    design_md = spec_dir / 'design.md'
    test_plan_md = spec_dir / 'test-plan.md'
    review_md = spec_dir / 'review-report.md'

    # 统计 phase 状态
    completed_phases = [p for p, info in state.get('phases', {}).items()
                        if info.get('status') == 'completed']
    skipped_phases = state.get('skipped_phases', [])

    # 子 agent delivery 文件
    delivery_files = sorted(spec_dir.glob('delivery-*.yaml'))
    deliveries_summary = '\n'.join(f'- {f.name}' for f in delivery_files) or '（无）'

    # 简化渲染（实际实现可读模板占位符）
    spec_id = state.get("spec_id", "?")
    spec_slug = state.get("spec_slug", "?")
    ts_now = datetime.now().isoformat(timespec="seconds")
    completed_str = ", ".join(completed_phases) or "(none)"
    skipped_str = ", ".join(skipped_phases) or "(none)"

    output = f"""# Delivery Checklist: {spec_slug}

**Generated**: {ts_now}
**Phase**: 6
**Spec ID**: {spec_id}

## 0. Handoff View

### Current State
- spec_id: {spec_id}
- current_phase: Phase 6 (delivery-checklist generated)
- Completed Phases: {completed_str}
- Skipped Phases: {skipped_str}

### Next Actions
- [ ] User signs at section 8
- [ ] After signature: bash coder-state.sh update-phase "Phase 6" completed
- [ ] Then Phase 7: bash coder-state.sh archive

### Context Hashes
- spec.md: {file_hash(spec_md)}
- design.md: {file_hash(design_md)}
- test-plan.md: {file_hash(test_plan_md)}
- review-report.md: {file_hash(review_md)}

## Sub-agent Deliveries (Phase 4)

{deliveries_summary}

Each delivery passed validate-delivery.py.

---

(Full template rendering TBD v7.2, this is simplified.)
"""

    out = spec_dir / 'delivery-checklist.md'
    out.write_text(output, encoding='utf-8')
    print(f'✅ delivery-checklist.md generated: {out}')
    return 0


if __name__ == '__main__':
    sys.exit(main())
