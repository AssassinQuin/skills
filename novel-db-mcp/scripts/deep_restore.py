"""深度恢复：根据大纲详细重建章节/场景/伏笔/世界观/关系"""

import json, os, re, sys, glob
sys.path.insert(0, '/Users/ganjie/skills/novel-db-mcp')
from server import query

NOVEL_ID = 12
NOVEL_DIR = "/Users/ganjie/code/personal/bywork/books_creater/novels/这次不一样了"
SETTINGS_DIR = os.path.join(NOVEL_DIR, "设定")
OUTLINE_DIR = os.path.join(SETTINGS_DIR, "大纲")

# ── 1. 卷号映射（文件名→卷号） ──
VOL_MAP = {
    "01-兽潮": 1, "02-边城": 2, "03-惨败": 3, "04-灵站": 4, "05-星火": 5,
    "06-多线": 6, "07-灰色": 7, "08-双星": 8, "09-断裂": 9, "10-血脉": 10,
    "11-核心": 11, "12-循环": 12, "13-暗涌": 13, "14-抉择": 14, "尾声": 0,
}

def get_vol_number(filename):
    for prefix, num in VOL_MAP.items():
        if filename.startswith(prefix):
            return num
    m = re.match(r'(\d+)', filename)
    return int(m.group(1)) if m else 0

# ── 2. 从卷大纲文件恢复章节规划 ──
def restore_chapters_from_outlines():
    """从卷大纲中的时间线恢复章节规划"""
    files = sorted(glob.glob(os.path.join(OUTLINE_DIR, "*.md")))
    count = 0
    for fp in files:
        basename = os.path.basename(fp).replace(".md", "")
        if basename in ("线索追踪", "附录"):
            continue
        vol_num = get_vol_number(basename)
        vol = query("SELECT id FROM volumes WHERE novel_id = %s AND number = %s", (NOVEL_ID, vol_num), fetch="one")
        if not vol:
            continue
        vol_id = vol["id"]

        with open(fp, "r", encoding="utf-8") as f:
            content = f.read()

        # 解析时间线表格
        tl_match = re.search(r'### 本卷时间线.*?\n(\|.*\|(?:\n\|.*\|)+)', content, re.DOTALL)
        if not tl_match:
            continue

        # 估算章节总数
        total_match = re.search(r'总章数[：:]\s*约(\d+)章', content)
        total_est = int(total_match.group(1)) if total_match else 0

        # 解析每天的事件
        lines = tl_match.group(1).strip().split("\n")
        current_chapter = 1
        # 跳过表头
        for line in lines[2:]:  # skip header + separator
            parts = [p.strip() for p in line.split("|") if p.strip()]
            if len(parts) < 3:
                continue
            # parts[0] = D1, parts[1] = event description
            day_label = parts[0]  # D1, D2, etc.
            event_desc = parts[1] if len(parts) > 1 else ""
            # Each day gets at least 1 chapter
            ch_num = current_chapter
            
            # 检查是否已有章节
            existing = query(
                "SELECT id FROM chapters WHERE novel_id = %s AND number = %s",
                (NOVEL_ID, ch_num), fetch="one"
            )
            if not existing and ch_num <= total_est:
                # 从 day_label 提取天数
                day_num = int(re.search(r'D(\d+)', day_label).group(1)) if re.search(r'D(\d+)', day_label) else 0
                # 提取视角
                pov = parts[2] if len(parts) > 2 else ""
                chapter_type = "normal"
                if "兽潮" in event_desc or "战斗" in event_desc:
                    chapter_type = "climax"
                elif "日常" in event_desc or "市集" in event_desc:
                    chapter_type = "daily"
                elif "出发" in event_desc or "离开" in event_desc or "上路" in event_desc:
                    chapter_type = "transition"

                query(
                    "INSERT INTO chapters (novel_id, number, title, outline, chapter_type, volume_id, status) "
                    "VALUES (%s, %s, %s, %s, %s, %s, 'planned') "
                    "ON CONFLICT (novel_id, number) DO NOTHING",
                    (NOVEL_ID, ch_num, f"D{day_num} {event_desc[:40]}", event_desc[:500], chapter_type, vol_id),
                    fetch="none"
                )
                count += 1
            current_chapter += 1

        # 补充剩余章节
        existing_count = query(
            "SELECT COUNT(*) as cnt FROM chapters WHERE novel_id = %s AND volume_id = %s",
            (NOVEL_ID, vol_id), fetch="val"
        )
        for cn in range(current_chapter, total_est + 1):
            existing = query(
                "SELECT id FROM chapters WHERE novel_id = %s AND number = %s",
                (NOVEL_ID, cn), fetch="one"
            )
            if not existing:
                query(
                    "INSERT INTO chapters (novel_id, number, title, outline, chapter_type, volume_id, status) "
                    "VALUES (%s, %s, %s, %s, %s, %s, 'planned')",
                    (NOVEL_ID, cn, f"第{cn}章", "", "normal", vol_id), fetch="none"
                )
    print(f"  新增/规划章节: {count}")

# ── 3. 恢复伏笔 ──
def restore_foreshadows():
    count = 0
    files = sorted(glob.glob(os.path.join(OUTLINE_DIR, "*.md")))
    for fp in files:
        basename = os.path.basename(fp).replace(".md", "")
        if basename in ("线索追踪", "附录"):
            continue
        with open(fp, "r", encoding="utf-8") as f:
            content = f.read()

        # 找"伏笔"章节
        fs_section = re.search(r'伏笔.*?\n(.*?)(?=\n## |\Z)', content, re.DOTALL)
        if not fs_section:
            continue
        for line in fs_section.group(1).split("\n"):
            line = line.strip().strip('-* ')
            if len(line) > 10 and "伏笔" not in line:
                query(
                    "INSERT INTO foreshadows (novel_id, description, importance, status) "
                    "VALUES (%s, %s, 'medium', 'planted') ON CONFLICT DO NOTHING",
                    (NOVEL_ID, line[:300]), fetch="none"
                )
                count += 1
    print(f"  恢复伏笔: {count}")

# ── 4. 恢复世界观设定 ──
def restore_world_settings():
    locked_file = os.path.join(SETTINGS_DIR, "锁定设定.md")
    if not os.path.exists(locked_file):
        return
    with open(locked_file, "r", encoding="utf-8") as f:
        content = f.read()

    # 按章节分割
    sections = re.split(r'^## ', content, flags=re.MULTILINE)
    sections_created = 0
    for sec in sections:
        if not sec.strip():
            continue
        header = sec.split("\n")[0].strip().rstrip("（锁定）").strip().rstrip("（锁定）").strip()
        # Determine category
        cat = None
        if "货币" in header or "物价" in header:
            cat = "economy"
        elif "城市" in header or "聚落" in header or "地图" in header or "地点" in header:
            cat = "location"
        elif "服装" in header:
            cat = "daily_life"
        elif "异灵" in header or "灵兽" in header or "兽潮" in header:
            cat = "bestiary"
        elif "能力" in header:
            cat = "ability"
        elif "势力" in header:
            cat = "faction"
        elif "角色状态" in header or "同步" in header:
            cat = "character_status"

        if cat:
            query(
                "INSERT INTO world_settings (novel_id, category, name, data) "
                "VALUES (%s, %s, %s, %s) ON CONFLICT (novel_id, category, name) DO UPDATE SET data = %s",
                (NOVEL_ID, cat, header[:50], json.dumps({"content": sec[:2000]}, ensure_ascii=False),
                 json.dumps({"content": sec[:2000]}, ensure_ascii=False)),
                fetch="none"
            )
            sections_created += 1
    print(f"  世界观条目: {sections_created}")

# ── 5. 创建章摘要（已有正文的章节） ──
def restore_chapter_summaries():
    body_dir = os.path.join(NOVEL_DIR, "正文")
    files = sorted(glob.glob(os.path.join(body_dir, "*.md")))
    for fp in files:
        m = re.search(r'第(\d+)章-(.*)\.md', os.path.basename(fp))
        if not m:
            continue
        ch_num = int(m.group(1))
        ch = query(
            "SELECT id FROM chapters WHERE novel_id = %s AND number = %s",
            (NOVEL_ID, ch_num), fetch="one"
        )
        if not ch:
            continue
        ch_id = ch["id"]

        # 检查是否已有 summary
        existing = query(
            "SELECT chapter_id FROM chapter_summaries WHERE chapter_id = %s",
            (ch_id,), fetch="one"
        )
        if existing:
            continue

        with open(fp, "r", encoding="utf-8") as f:
            text = f.read()

        # 第一行做摘要
        title = text.split("\n")[0].replace("#", "").strip() if text else ""
        summary = f"{title}——见正文第{ch_num}章"

        # 提取出场人物 (粗略)
        chars = []
        for name in ["沈野", "沈念", "方岩", "老陈", "韩朗"]:
            if name in text:
                chars.append(name)

        query(
            "INSERT INTO chapter_summaries (chapter_id, summary, key_events, characters_involved) "
            "VALUES (%s, %s, %s, %s) ON CONFLICT (chapter_id) DO NOTHING",
            (ch_id, summary, json.dumps([f"第{ch_num}章完成"], ensure_ascii=False),
             json.dumps(chars, ensure_ascii=False)),
            fetch="none"
        )
        # Update status
        query("UPDATE chapters SET status = 'written' WHERE id = %s", (ch_id,), fetch="none")
    print(f"  章摘要: 已处理")

# ── 6. 创建关系 ──
def restore_relations():
    chars = {r["name"]: r["id"] for r in
             query("SELECT name, id FROM characters WHERE novel_id = %s", (NOVEL_ID,))}
    relations_data = [
        ("沈野", "沈念", "family", "兄妹，相依为命"),
        ("沈野", "方岩", "ally", "初遇，互相注意"),
        ("沈念", "方岩", "ally", "面摊见过"),
    ]
    for f, t, rel, desc in relations_data:
        if f in chars and t in chars:
            query(
                "INSERT INTO character_relations (novel_id, from_character_id, to_character_id, "
                "relation_type, description, chapter_established) VALUES (%s, %s, %s, %s, %s, 1) "
                "ON CONFLICT DO NOTHING",
                (NOVEL_ID, chars[f], chars[t], rel, desc), fetch="none"
            )
            print(f"  关系: {f}→{t} ({rel})")

print("=== 深度恢复开始 ===")
restore_chapters_from_outlines()
restore_foreshadows()
restore_world_settings()
restore_chapter_summaries()
restore_relations()
print("\n✅ 深度恢复完成")
