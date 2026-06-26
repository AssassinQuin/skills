#!/usr/bin/env python3
"""gen-spec.py — Phase 0 spec.md 渲染器（v7.1 新增）。

从用户输入 + AskUserQuestion 答案，按 assets/spec-template.md 渲染 spec.md。

Usage:
    gen-spec.py --slug "add-login" \\
        --user-input "用户原话" \\
        --restated "agent 复述" \\
        --acceptance "功能 X 能跑,测试覆盖 Y" \\
        --phase-0_5 yes --phase-3 yes --phase-4_5 no --phase-7 yes \\
        --budget 60 \\
        --allowed-deps "" \\
        --out-dir .claude/coder-state/specs-active/

输出：{out-dir}/{ts}-{slug}/spec.md
"""
from __future__ import annotations

import argparse
import hashlib
import os
import re
import sys
from datetime import date, datetime
from pathlib import Path

# 路径解析
SCRIPT_DIR = Path(__file__).resolve().parent
MODULE_DIR = SCRIPT_DIR.parent
TEMPLATE = MODULE_DIR / 'assets' / 'spec-template.md'


def slugify(s: str) -> str:
    s = re.sub(r'[^a-zA-Z0-9_-]+', '-', s.lower()).strip('-')
    return s[:40] or 'unnamed'


def user_signature(content: str) -> tuple[str, str]:
    user = os.environ.get('USER', 'unknown')
    ts = datetime.now().isoformat(timespec='seconds')
    raw = f'{user}|{ts}|{content[:300]}'
    return hashlib.sha256(raw.encode()).hexdigest()[:16], ts


def render(template: str, ctx: dict) -> str:
    def replace(match):
        key = match.group(1)
        return ctx.get(key, match.group(0))
    return re.sub(r'\{\{(\w+)\}\}', replace, template)


def main() -> int:
    parser = argparse.ArgumentParser(description='Phase 0 spec.md 渲染器')
    parser.add_argument('--slug', required=True)
    parser.add_argument('--user-input', required=True)
    parser.add_argument('--restated', required=True)
    parser.add_argument('--acceptance', default='（待补充）')
    parser.add_argument('--phase-0_5', choices=['yes', 'no'], default='yes')
    parser.add_argument('--phase-3', choices=['yes', 'no'], default='yes')
    parser.add_argument('--phase-4_5', choices=['yes', 'no'], default='yes')
    parser.add_argument('--phase-7', choices=['yes', 'no'], default='yes')
    parser.add_argument('--budget', type=int, default=60)
    parser.add_argument('--allowed-deps', default='')
    parser.add_argument('--out-dir', default='.claude/coder-state/specs-active')
    args = parser.parse_args()

    if not TEMPLATE.exists():
        print(f'ERROR: 模板不存在: {TEMPLATE}', file=sys.stderr)
        return 1

    template = TEMPLATE.read_text(encoding='utf-8')

    slug = slugify(args.slug)
    ts = datetime.now().strftime('%Y%m%d-%H%M%S')
    spec_id = f'{ts}-{slug}'
    init_date = date.today().isoformat()

    # 用户签字 hash
    user_hash, sign_ts = user_signature(args.user_input + args.restated)

    # Phase 标记
    def phase_mark(v): return '✅' if v == 'yes' else '❌'

    ctx = {
        'SPEC_SLUG': slug,
        'SPEC_ID': spec_id,
        'DATE': init_date,
        'USER_HASH': user_hash,
        'SIGN_TS': sign_ts,
        'USER_ID': os.environ.get('USER', 'unknown'),
        'USER_RAW_INPUT': args.user_input,
        'AGENT_RESTATED': args.restated,
        'ACCEPTANCE_CHECKLIST': args.acceptance,
        'USER_STORIES': '（待 Phase 0.2b 补充）',
        'MODULE_SKETCH': '（待 Phase 0.2b 补充）',
        'PHASE_0_5': phase_mark(args.phase_0_5),
        'PHASE_0_5_REASON': '推荐' if args.phase_0_5 == 'yes' else '用户选跳',
        'PHASE_3': phase_mark(args.phase_3),
        'PHASE_3_REASON': '推荐（复杂任务必跑）' if args.phase_3 == 'yes' else '用户选跳',
        'PHASE_4_5': phase_mark(args.phase_4_5),
        'PHASE_4_5_REASON': '推荐' if args.phase_4_5 == 'yes' else '用户选跳',
        'PHASE_7': phase_mark(args.phase_7),
        'PHASE_7_REASON': '推荐' if args.phase_7 == 'yes' else '用户选跳',
        'BUDGET_MINUTES': str(args.budget),
        'AUTO_PHASES': '["Phase 1", "Phase 2"]',
        'ALLOWED_DEPS': args.allowed_deps or '（无）',
        'OUT_OF_SCOPE': '（agent 推断 + 用户确认）',
        'USER_PREFERENCES': '（默认）',
    }

    spec_md = render(template, ctx)

    out_dir = Path(args.out_dir) / spec_id
    out_dir.mkdir(parents=True, exist_ok=True)
    spec_file = out_dir / 'spec.md'
    spec_file.write_text(spec_md, encoding='utf-8')

    print(f'✅ spec.md generated: {spec_file}')
    print(f'   spec_id: {spec_id}')
    print(f'   user_hash: {user_hash}')
    return 0


if __name__ == '__main__':
    sys.exit(main())
