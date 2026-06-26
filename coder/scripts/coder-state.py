#!/usr/bin/env python3
"""coder-state — v6.0 跨 session 状态管理。

管理 .claude/coder-state/ 下的 spec 状态，支持断点续跑。

设计见 coder/.deepen/20260625-execution-flow/design.md。

Usage:
    coder-state.py init --slug <slug> [--auto-phases <list>]
    coder-state.py show
    coder-state.py update-phase <phase> <status>
    coder-state.py add-task <task-id> <phase> <subagent>
    coder-state.py update-task <task-id> <status> [--deliverable <path>]
    coder-state.py checkpoint <phase> [--note <text>]
    coder-state.py resume
    coder-state.py archive
    coder-state.py abandon --reason <text>
"""
from __future__ import annotations

import argparse
import hashlib
import json
import os
import sys
from datetime import datetime, timezone
from pathlib import Path

# ---- 路径解析 ----

def find_project_root(start: Path | None = None) -> Path:
    """从当前目录往上找含 .claude/ 的目录。"""
    p = start or Path.cwd()
    while True:
        if (p / ".claude").is_dir():
            return p
        if p.parent == p:
            return Path.cwd()
        p = p.parent

PROJECT_ROOT = find_project_root()
STATE_DIR = PROJECT_ROOT / ".claude" / "coder-state"
SPECS_ACTIVE_DIR = STATE_DIR / "specs-active"
ARCHIVE_DIR = STATE_DIR / "archive"
CURRENT_FILE = STATE_DIR / "current.json"


def now_iso() -> str:
    return datetime.now(timezone.utc).isoformat(timespec="seconds")


def slugify(s: str) -> str:
    import re
    s = re.sub(r'[^a-zA-Z0-9_-]+', '-', s.lower()).strip('-')
    return s[:40] or "unnamed"


def gen_spec_id(slug: str) -> str:
    ts = datetime.now().strftime("%Y%m%d-%H%M%S")
    return f"{ts}-{slug}"


def user_signature(content: str) -> str:
    """生成用户签字 hash（结合 user + content + timestamp）。"""
    user = os.environ.get("USER", "unknown")
    ts = datetime.now().isoformat(timespec="seconds")
    raw = f"{user}|{ts}|{content[:200]}"
    return hashlib.sha256(raw.encode()).hexdigest()[:16]


# ---- state 操作 ----

def cmd_init(args):
    """初始化新 spec。"""
    if CURRENT_FILE.exists() and not args.force:
        print(f"ERROR: 已有活跃 spec（{CURRENT_FILE}）", file=sys.stderr)
        print("用 --force 覆盖，或先 archive", file=sys.stderr)
        return 1

    slug = slugify(args.slug)
    spec_id = gen_spec_id(slug)
    spec_dir = SPECS_ACTIVE_DIR / spec_id
    spec_dir.mkdir(parents=True, exist_ok=True)

    state = {
        "spec_id": spec_id,
        "spec_slug": slug,
        "started_at": now_iso(),
        "last_active": now_iso(),
        "current_phase": "Phase 0",
        "state_machine": "new",  # v7.2 新增：new/triaging/designing/implementing/reviewing/delivered/needs_info/archived
        "phases": {},
        "skipped_phases": [],
        "tasks": [],
        "deliverables_paths": {},
        "user_preferences": {
            "auto_confirm_phases": args.auto_phases or [],
            "timeout_budget_minutes": args.budget or 60,
        },
        "spec_dir": str(spec_dir.relative_to(PROJECT_ROOT)),
    }

    STATE_DIR.mkdir(parents=True, exist_ok=True)
    CURRENT_FILE.write_text(json.dumps(state, indent=2, ensure_ascii=False), encoding="utf-8")
    print(f"✅ init spec: {spec_id}")
    print(f"   state: {CURRENT_FILE}")
    print(f"   spec_dir: {spec_dir}")
    return 0


def load_state() -> dict | None:
    if not CURRENT_FILE.exists():
        return None
    return json.loads(CURRENT_FILE.read_text(encoding="utf-8"))


def save_state(state: dict) -> None:
    state["last_active"] = now_iso()
    CURRENT_FILE.write_text(json.dumps(state, indent=2, ensure_ascii=False), encoding="utf-8")


def cmd_show(args):
    state = load_state()
    if not state:
        print("（无活跃 spec）")
        return 0

    # state_machine emoji（v7.4）
    sm_emojis = {
        "new": "🆕", "triaging": "🔍", "designing": "🎨",
        "implementing": "🔧", "reviewing": "🔬", "delivered": "📦",
        "archived": "🗄️", "needs_info": "❓", "abandoned": "💀",
    }
    sm = state.get("state_machine", "new")
    sm_emoji = sm_emojis.get(sm, "❓")

    print(f"📋 Spec: {state['spec_id']}")
    print(f"   Slug: {state['spec_slug']}")
    print(f"   Started: {state['started_at']}")
    print(f"   Last active: {state['last_active']}")
    print(f"   Current phase: {state['current_phase']}")
    print(f"   {sm_emoji} State machine: {sm}")
    print()

    # v7.4：needs_info 提示
    if sm == "needs_info":
        prev = state.get("needs_info_prev_state", "?")
        history = state.get("state_history", [])
        last_note = history[-1].get("note", "(无备注)") if history else "(无备注)"
        print(f"   ⚠️ needs_info 暂停态（from {prev}）")
        print(f"      待回答: {last_note}")
        print(f"      恢复: bash coder-state.sh state-machine transition --target resume")
        print()

    print("   Phases:")
    for phase, info in state.get("phases", {}).items():
        status = info.get("status", "?")
        ts = info.get("ts", "?")[:19]
        marker = {"completed": "✅", "in_progress": "🔄", "skipped": "⏭"}.get(status, "❓")
        signed = " ✍️" if info.get("user_signed_hash") else ""
        print(f"     {marker} {phase}: {status} ({ts}){signed}")
    if state.get("skipped_phases"):
        print(f"   Skipped: {', '.join(state['skipped_phases'])}")
    if state.get("tasks"):
        print()
        print("   Tasks:")
        for t in state["tasks"]:
            status = t.get("status", "?")
            marker = {"completed": "✅", "in_progress": "🔄", "pending": "⏳", "failed": "❌"}.get(status, "❓")
            sa = t.get("subagent", "?")
            tid = t.get("id", "?")
            print(f"     {marker} {tid} ({sa}): {status}")

    # v7.4：state_history 末尾 3 条
    history = state.get("state_history", [])
    if history:
        print()
        print(f"   📜 state history（最近 {min(3, len(history))} 条）:")
        for h in history[-3:]:
            ts = h.get("ts", "?")[:19]
            frm = h.get("from", "?")
            to = h.get("to", "?")
            note = h.get("note", "")
            note_str = f" // {note}" if note else ""
            print(f"     {ts}  {frm} → {to}{note_str}")

    return 0


def cmd_update_phase(args):
    state = load_state()
    if not state:
        print("ERROR: 无活跃 spec，先 init", file=sys.stderr)
        return 1

    phase = args.phase
    status = args.status

    if status == "skipped" and phase not in state["skipped_phases"]:
        state["skipped_phases"].append(phase)
    elif status == "in_progress":
        state["current_phase"] = phase

    state.setdefault("phases", {})[phase] = {
        "status": status,
        "ts": now_iso(),
    }

    if status == "completed":
        # 自动推进 current_phase 到下一个（按预定义顺序）
        order = ["Phase -1", "Phase 0", "Phase 0.5", "Phase 1", "Phase 2",
                 "Phase 3", "Phase 4", "Phase 4.5", "Phase 5", "Phase 6", "Phase 7"]
        try:
            idx = order.index(phase)
            state["current_phase"] = order[idx + 1] if idx + 1 < len(order) else phase
        except ValueError:
            pass

    # v7.2 新增：state_machine 自动推进
    PHASE_TO_STATE = {
        "Phase 0": "new",          # spec 创建中
        "Phase 0.5": "triaging",   # 复用分析
        "Phase 0.6": "triaging",   # bug 诊断
        "Phase 1": "triaging",     # 元数据扫描
        "Phase 2": "designing",    # 语言路由
        "Phase 2.5": "designing",  # prototype
        "Phase 3": "designing",    # 设计方案
        "Phase 4": "implementing", # 执行
        "Phase 4.5": "implementing",
        "Phase 5": "reviewing",    # 验证
        "Phase 6": "delivered",    # 持久化
        "Phase 7": "archived",     # 归档
    }
    if status == "in_progress" and phase in PHASE_TO_STATE:
        state["state_machine"] = PHASE_TO_STATE[phase]
    elif status == "completed" and phase == "Phase 7":
        state["state_machine"] = "archived"
    elif status == "completed" and phase == "Phase 6":
        state["state_machine"] = "delivered"

    save_state(state)
    state_sm = state.get("state_machine", "?")
    print(f"✅ {phase}: {status} (state: {state_sm})")
    return 0


def cmd_add_task(args):
    state = load_state()
    if not state:
        print("ERROR: 无活跃 spec", file=sys.stderr)
        return 1

    task = {
        "id": args.task_id,
        "phase": args.phase,
        "subagent": args.subagent,
        "status": "pending",
        "created_ts": now_iso(),
    }
    state.setdefault("tasks", []).append(task)
    save_state(state)
    print(f"✅ added task: {args.task_id} ({args.subagent})")
    return 0


def cmd_update_task(args):
    state = load_state()
    if not state:
        print("ERROR: 无活跃 spec", file=sys.stderr)
        return 1

    for t in state.get("tasks", []):
        if t["id"] == args.task_id:
            t["status"] = args.status
            t["updated_ts"] = now_iso()
            if args.deliverable:
                t["deliverable"] = args.deliverable
            save_state(state)
            print(f"✅ task {args.task_id}: {args.status}")
            return 0

    print(f"ERROR: task not found: {args.task_id}", file=sys.stderr)
    return 1


def cmd_checkpoint(args):
    state = load_state()
    if not state:
        print("ERROR: 无活跃 spec", file=sys.stderr)
        return 1

    phase = args.phase
    state.setdefault("checkpoints", []).append({
        "phase": phase,
        "ts": now_iso(),
        "note": args.note or "",
    })
    save_state(state)
    print(f"✅ checkpoint: {phase}")
    return 0


def cmd_resume(args):
    """检测是否有可续跑的 spec。"""
    if not CURRENT_FILE.exists():
        print("NO_ACTIVE_SPEC")
        return 0

    state = load_state()
    print(f"ACTIVE_SPEC: {state['spec_id']}")
    print(f"CURRENT_PHASE: {state['current_phase']}")
    completed = sum(1 for p in state.get("phases", {}).values() if p.get("status") == "completed")
    total = len(state.get("phases", {})) + len(state.get("skipped_phases", []))
    print(f"PROGRESS: {completed}/{total} phases done")
    return 0


def cmd_archive(args):
    """归档完成的 spec。"""
    state = load_state()
    if not state:
        print("ERROR: 无活跃 spec", file=sys.stderr)
        return 1

    spec_id = state["spec_id"]
    spec_dir = PROJECT_ROOT / state["spec_dir"]

    # 生成 archive.md
    archive_md = spec_dir / "archive.md"
    summary = f"""# Archive: {spec_id}

**Slug**: {state['spec_slug']}
**Started**: {state['started_at']}
**Archived**: {now_iso()}
**Final phase**: {state['current_phase']}

## Phase 历史
"""
    for phase, info in state.get("phases", {}).items():
        summary += f"- {phase}: {info.get('status')} ({info.get('ts', '?')[:19]})\n"
    if state.get("skipped_phases"):
        summary += f"\nSkipped: {', '.join(state['skipped_phases'])}\n"

    summary += f"\n## Tasks ({len(state.get('tasks', []))})\n"
    for t in state.get("tasks", []):
        summary += f"- {t['id']} ({t.get('subagent', '?')}): {t.get('status')}\n"

    archive_md.write_text(summary, encoding="utf-8")

    # 移动到 archive/
    ARCHIVE_DIR.mkdir(parents=True, exist_ok=True)
    target = ARCHIVE_DIR / spec_id
    if target.exists():
        target = ARCHIVE_DIR / f"{spec_id}-{now_iso().replace(':', '')[-8:]}"
    spec_dir.rename(target)

    # 清除 current.json
    CURRENT_FILE.unlink()

    print(f"✅ archived: {spec_id} → {target.relative_to(PROJECT_ROOT)}")
    return 0


def cmd_abandon(args):
    """放弃当前 spec（归档但标记 abandoned）。"""
    state = load_state()
    if not state:
        print("ERROR: 无活跃 spec", file=sys.stderr)
        return 1

    state["abandoned"] = True
    state["abandon_reason"] = args.reason
    state["abandoned_ts"] = now_iso()
    state["state_machine"] = "abandoned"
    save_state(state)

    # 走 archive 流程
    return cmd_archive(args)


def cmd_state_machine(args):
    """v7.2 新增：spec 状态机查询 / 转换。"""
    state = load_state()
    if not state:
        print("ERROR: 无活跃 spec", file=sys.stderr)
        return 1

    if args.action == "show":
        current = state.get("state_machine", "unknown")
        print(f"state_machine: {current}")
        print(f"current_phase: {state.get('current_phase', '?')}")
        print()
        print("States (valid transitions):")
        print("  new → triaging → designing → implementing → reviewing → delivered → archived")
        print("  any → needs_info (暂停，等用户回应) → 恢复到原 state")
        print("  any → abandoned (放弃)")
        return 0

    if args.action == "transition":
        current = state.get("state_machine", "new")
        target = args.target

        # 进入 needs_info 前记录原 state，恢复时用
        needs_info_prev = state.get("needs_info_prev_state")

        # needs_info → 任意原 state（恢复）
        if current == "needs_info" and target != "abandoned":
            if not needs_info_prev:
                print("ERROR: needs_info 无 prev_state 记录", file=sys.stderr)
                return 1
            if target not in ["resume", needs_info_prev]:
                print(f"ERROR: needs_info 只能恢复到 {needs_info_prev}（或用 --target resume）", file=sys.stderr)
                return 1
            # 恢复成功
            state.pop("needs_info_prev_state", None)
            state["state_machine"] = needs_info_prev
            state.setdefault("state_history", []).append({
                "from": "needs_info", "to": needs_info_prev,
                "ts": now_iso(), "note": args.note or f"resume from needs_info",
            })
            save_state(state)
            print(f"✅ needs_info → {needs_info_prev} (resumed)")
            return 0

        if target == "needs_info":
            state["needs_info_prev_state"] = current

        valid = {
            "new": ["triaging", "needs_info", "abandoned"],
            "triaging": ["designing", "needs_info", "abandoned"],
            "designing": ["implementing", "needs_info", "abandoned", "triaging"],
            "implementing": ["reviewing", "needs_info", "abandoned", "designing"],
            "reviewing": ["delivered", "needs_info", "abandoned", "implementing"],
            "delivered": ["archived", "needs_info", "reviewing"],
            "needs_info": ["resume", "abandoned"],  # 已在上面处理
            "archived": [],
            "abandoned": [],
        }
        allowed = valid.get(current, [])
        if target not in allowed:
            print(f"ERROR: 非法转换 {current} → {target}", file=sys.stderr)
            print(f"   允许: {allowed}", file=sys.stderr)
            return 1

        prev_state = state.get("state_machine")
        state["state_machine"] = target
        state.setdefault("state_history", []).append({
            "from": prev_state, "to": target, "ts": now_iso(),
            "note": args.note or "",
        })
        save_state(state)
        print(f"✅ {prev_state} → {target}")
        return 0

    return 1


# ---- main ----

def main():
    parser = argparse.ArgumentParser(description="coder v6.0 state 管理")
    sub = parser.add_subparsers(dest="cmd", required=True)

    p_init = sub.add_parser("init", help="初始化新 spec")
    p_init.add_argument("--slug", required=True)
    p_init.add_argument("--force", action="store_true")
    p_init.add_argument("--auto-phases", nargs="*", default=[], help="自动通过的 Phase")
    p_init.add_argument("--budget", type=int, help="时间预算（分钟）")
    p_init.set_defaults(func=cmd_init)

    p_show = sub.add_parser("show", help="显示当前 spec")
    p_show.set_defaults(func=cmd_show)

    p_phase = sub.add_parser("update-phase", help="更新 Phase 状态")
    p_phase.add_argument("phase")
    p_phase.add_argument("status", choices=["pending", "in_progress", "completed", "skipped", "failed"])
    p_phase.set_defaults(func=cmd_update_phase)

    p_add = sub.add_parser("add-task", help="添加 task")
    p_add.add_argument("--task-id", required=True)
    p_add.add_argument("--phase", required=True)
    p_add.add_argument("--subagent", required=True)
    p_add.set_defaults(func=cmd_add_task)

    p_utask = sub.add_parser("update-task", help="更新 task 状态")
    p_utask.add_argument("task_id")
    p_utask.add_argument("status", choices=["pending", "in_progress", "completed", "failed"])
    p_utask.add_argument("--deliverable", help="交付物路径")
    p_utask.set_defaults(func=cmd_update_task)

    p_cp = sub.add_parser("checkpoint", help="打 checkpoint")
    p_cp.add_argument("phase")
    p_cp.add_argument("--note")
    p_cp.set_defaults(func=cmd_checkpoint)

    p_res = sub.add_parser("resume", help="检测可续跑 spec")
    p_res.set_defaults(func=cmd_resume)

    p_arch = sub.add_parser("archive", help="归档完成的 spec")
    p_arch.set_defaults(func=cmd_archive)

    p_ab = sub.add_parser("abandon", help="放弃当前 spec")
    p_ab.add_argument("--reason", required=True)
    p_ab.set_defaults(func=cmd_abandon)

    # v7.2 新增：state machine
    p_sm = sub.add_parser("state-machine", help="spec 状态机查询 / 转换（v7.2）")
    p_sm.add_argument("action", choices=["show", "transition"])
    p_sm.add_argument("--target", help="目标 state（transition）",
                      choices=["new", "triaging", "designing", "implementing",
                               "reviewing", "delivered", "archived",
                               "needs_info", "abandoned", "resume"])
    p_sm.add_argument("--note", help="转换备注")
    p_sm.set_defaults(func=cmd_state_machine)

    args = parser.parse_args()
    return args.func(args)


if __name__ == "__main__":
    sys.exit(main())
