#!/usr/bin/env python3
"""group-vertical-slices.py — Phase 4 vertical slice 分组（v7.2 改进版）。

按文件改动 + user behavior，建议 vertical slice 分组（每个 slice 贯穿所有层）。

v7.2 改进：
- file→layer 分类更准（路径 + 文件名 + 内容启发式）
- slice 合并：单文件 slice 合并到主 slice
- --auto-merge 阈值参数

Usage:
    group-vertical-slices.py --files-changed src/auth/login.py,src/auth/models.py,tests/test_login.py \\
        --user-behaviors "用户能登录,用户错密码失败" \\
        --language python \\
        --auto-merge 2
"""
from __future__ import annotations

import argparse
import json
import sys
from pathlib import Path


# 扩展的层分类规则
LAYER_RULES = [
    # (predicate, layer_name)
    (lambda p, n, parts: 'test' in n or n.startswith('test_') or 'tests' in parts or 'spec' in parts, 'tests'),
    (lambda p, n, parts: 'migration' in parts or n.startswith(('db_', 'schema_')) or 'migrations' in parts, 'migrations'),
    (lambda p, n, parts: 'api' in parts or 'endpoint' in parts or 'route' in parts or 'controller' in parts, 'api'),
    (lambda p, n, parts: 'service' in parts or 'usecase' in parts or 'use_case' in parts, 'logic'),
    (lambda p, n, parts: 'repository' in parts or 'store' in parts or 'dao' in parts, 'repository'),
    (lambda p, n, parts: 'model' in parts or 'entity' in parts or 'domain' in parts or 'dto' in parts, 'schema'),
    (lambda p, n, parts: any(n.endswith(ext) for ext in ('.tsx', '.vue', '.jsx', '.svelte')) or 'component' in parts or 'page' in parts or 'view' in parts, 'ui'),
    (lambda p, n, parts: 'component' in parts or 'widget' in parts, 'ui'),
    (lambda p, n, parts: 'cmd' in parts or 'cli' in parts or n in ('main.go', '__main__.py', 'index.ts'), 'entry'),
    (lambda p, n, parts: 'config' in parts or 'conf' in parts or n in ('.env.example', 'config.yaml', 'pyproject.toml'), 'config'),
    (lambda p, n, parts: 'util' in parts or 'helper' in parts or 'common' in parts, 'util'),
    (lambda p, n, parts: n.endswith(('_presenter.py', '_view.py', '_viewmodel.py')), 'ui'),
]


def classify_layer(filepath: str, language: str = '') -> str:
    """从文件路径启发式推断所属层（v7.2 改进版）。"""
    p = Path(filepath)
    name = p.name.lower()
    parts = [x.lower() for x in p.parts]

    for predicate, layer in LAYER_RULES:
        try:
            if predicate(name, name, parts):
                return layer
        except Exception:
            continue

    # 后缀 fallback
    if name.endswith(('.md', '.rst', '.txt')):
        return 'docs'
    if name.endswith(('.json', '.yaml', '.yml', '.toml', '.ini')):
        return 'config'

    return 'other'


def extract_feature(filepath: str) -> str:
    """从文件路径提取 feature 关键词（v7.2 改进：更智能）。"""
    p = Path(filepath)
    parts = [x.lower() for x in p.parts]

    # 跳过常见无 feature 目录
    skip = {'src', 'lib', 'internal', 'pkg', 'app', 'cmd', 'main', 'root',
            'tests', 'test', 'spec', 'docs', 'doc', 'config', 'conf'}

    for part in parts[1:-1]:  # 不取首尾
        if part in skip:
            continue
        if part.startswith('.'):
            continue
        return part

    # 如果没找到，用文件名前缀（去后缀）
    name = p.stem.lower()
    for sep in ('_', '-', '.'):
        if sep in name:
            return name.split(sep)[0]
    return name or 'misc'


def group_slices(files: list[str], behaviors: list[str], auto_merge: int = 0) -> list[dict]:
    """按 feature 分组文件 → 转 vertical slice（v7.2 加 auto-merge）。"""
    # 按 feature 分组
    groups: dict[str, list[str]] = {}
    for f in files:
        feature = extract_feature(f)
        groups.setdefault(feature, []).append(f)

    # v7.2 新增：auto-merge 小 slice
    if auto_merge > 0:
        small = {k: v for k, v in groups.items() if len(v) <= auto_merge}
        if small and len(groups) > 1:
            # 找最大的 group 当主 slice
            main_feature = max(groups.items(), key=lambda x: len(x[1]) if x[0] not in small else 0)[0]
            for feat, fs in list(small.items()):
                groups[main_feature].extend(fs)
                del groups[feat]

    slices = []
    behaviors_iter = iter(behaviors)
    for feature, fs in groups.items():
        layers = sorted(set(classify_layer(f) for f in fs))
        slice_name = next(behaviors_iter, f'feature: {feature}')
        # 判定 HITL vs AFK（v7.2 更严：涉及 migrations 或 schema + api 都改 → HITL）
        hitl_signals = [
            'migrations' in layers,
            'schema' in layers and 'api' in layers,
            'ui' in layers and 'logic' in layers and 'migrations' in layers,
        ]
        slice_type = 'HITL' if any(hitl_signals) else 'AFK'

        slices.append({
            'name': slice_name,
            'feature': feature,
            'files': fs,
            'layers_covered': layers,
            'type': slice_type,
            'independently_demoable': len(layers) >= 2,
            'file_count': len(fs),
        })

    return slices


def main() -> int:
    parser = argparse.ArgumentParser(description='Phase 4 vertical slice 分组（v7.2）')
    parser.add_argument('--files-changed', required=True,
                        help='逗号分隔的文件列表')
    parser.add_argument('--user-behaviors', required=True,
                        help='逗号分隔的 user behavior 列表')
    parser.add_argument('--language', default='python')
    parser.add_argument('--max-slices', type=int, default=5,
                        help='上限（v7 推荐不超过 5）')
    parser.add_argument('--auto-merge', type=int, default=0,
                        help='v7.2 新增：≤N 个文件的 slice 合并到主 slice（默认 0 不合并）')
    parser.add_argument('--format', choices=['text', 'json'], default='text')
    args = parser.parse_args()

    files = [f.strip() for f in args.files_changed.split(',') if f.strip()]
    behaviors = [b.strip() for b in args.user_behaviors.split(',') if b.strip()]

    slices = group_slices(files, behaviors, auto_merge=args.auto_merge)

    if len(slices) > args.max_slices:
        print(f'⚠️  分组数 {len(slices)} > 上限 {args.max_slices}（建议拆 batch 或加大 --auto-merge）',
              file=sys.stderr)

    if args.format == 'json':
        print(json.dumps(slices, indent=2, ensure_ascii=False))
    else:
        print(f'# Vertical Slice 分组建议（v7.2）')
        print(f'# 总文件: {len(files)} | 分组: {len(slices)} | AFK: {sum(1 for s in slices if s["type"] == "AFK")} | HITL: {sum(1 for s in slices if s["type"] == "HITL")}')
        if args.auto_merge:
            print(f'# auto-merge: ≤{args.auto_merge} 文件的 slice 已合并')
        print()
        for i, s in enumerate(slices, 1):
            print(f'## Slice {i}: {s["name"]} [{s["type"]}]')
            print(f'  Feature: {s["feature"]} ({s["file_count"]} 文件)')
            print(f'  Layers: {" + ".join(s["layers_covered"]) if s["layers_covered"] else "(未识别)"}')
            print(f'  Demoable: {"✅" if s["independently_demoable"] else "❌ (单层切片，建议合并)"}')
            print(f'  Files:')
            for f in s['files']:
                layer = classify_layer(f)
                print(f'    - [{layer}] {f}')
            print()

    return 0


if __name__ == '__main__':
    sys.exit(main())

