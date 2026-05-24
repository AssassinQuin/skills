"""从 novels/{小说名}/设定 文件恢复 novel-db 数据。

用法: python3 restore_from_files.py
依赖: 需在项目根目录运行，或设置 PROJECT_ROOT 环境变量
"""

import json, os, re, sys, glob

PROJECT_ROOT = os.environ.get(
    "PROJECT_ROOT",
    "/Users/ganjie/code/personal/bywork/books_creater"
)
NOVEL_NAME = "这次不一样了"
NOVEL_DIR = os.path.join(PROJECT_ROOT, "novels", NOVEL_NAME)
SETTINGS_DIR = os.path.join(NOVEL_DIR, "设定")

# 确保 DB 连接可用
sys.path.insert(0, os.path.join(os.path.dirname(__file__), ".."))
from server import query


def restore():
    print(f"=== 从文件恢复 {NOVEL_NAME} 到 novel-db ===")

    # 1. 创建小说项目
    r = query(
        "SELECT id FROM novels WHERE name = %s", (NOVEL_NAME,), fetch="one"
    )
    if r:
        novel_id = r["id"]
        print(f"  小说已存在: id={novel_id}, 跳过创建")
    else:
        r = query(
            "INSERT INTO novels (name, genre, status) VALUES (%s, '玄幻', 'planning') RETURNING id",
            (NOVEL_NAME,), fetch="one"
        )
        novel_id = r["id"]
        print(f"  创建小说: id={novel_id}")

    # 2. 创建卷 (从大纲文件)
    outline_dir = os.path.join(SETTINGS_DIR, "大纲")
    volume_files = sorted(glob.glob(os.path.join(outline_dir, "*.md")))
    volume_count = 0
    for vf in volume_files:
        basename = os.path.basename(vf)
        if basename == "线索追踪.md" or basename == "附录.md":
            continue
        m = re.match(r'(\d+)-(.*)\.md', basename)
        title = m.group(2) if m else basename.replace(".md", "")
        num = int(m.group(1)) if m else 0

        # Read first few lines for description
        with open(vf, "r", encoding="utf-8") as f:
            content = f.read()
        desc_line = content.split("\n")[0].replace("#", "").strip() if content else title

        r = query(
            "SELECT id FROM volumes WHERE novel_id = %s AND number = %s",
            (novel_id, num), fetch="one"
        )
        if r:
            continue
        query(
            "INSERT INTO volumes (novel_id, number, title, notes) VALUES (%s, %s, %s, %s)",
            (novel_id, num, title, desc_line), fetch="none"
        )
        volume_count += 1
    print(f"  创建卷: {volume_count} 个")

    # 3. 创建章节 (从大纲时间线+正文)
    # 先从正文目录找到已有章节
    body_dir = os.path.join(NOVEL_DIR, "正文")
    chapter_files = sorted(glob.glob(os.path.join(body_dir, "*.md")))
    chapter_count = 0
    for cf in chapter_files:
        m = re.search(r'第(\d+)章-(.*)\.md', os.path.basename(cf))
        if not m:
            continue
        ch_num = int(m.group(1))
        ch_title = m.group(2)

        # 确定所属卷
        if ch_num <= 25:
            vol_num = 1
        elif ch_num <= 50:
            vol_num = 2
        else:
            vol_num = (ch_num - 1) // 25 + 1

        vol = query(
            "SELECT id FROM volumes WHERE novel_id = %s AND number = %s",
            (novel_id, vol_num), fetch="one"
        )
        vol_id = vol["id"] if vol else None

        r = query(
            "SELECT id FROM chapters WHERE novel_id = %s AND number = %s",
            (novel_id, ch_num), fetch="one"
        )
        if r:
            continue

        # 读取正文内容作为 outline
        with open(cf, "r", encoding="utf-8") as f:
            text = f.read()
        first_line = text.split("\n")[0].replace("#", "").strip() if text else ""

        query(
            "INSERT INTO chapters (novel_id, number, title, outline, volume_id, status) "
            "VALUES (%s, %s, %s, %s, %s, 'written')",
            (novel_id, ch_num, ch_title, first_line[:500], vol_id), fetch="none"
        )
        chapter_count += 1
    print(f"  创建章节: {chapter_count} 个")

    # 4. 创建人物 (从角色蒸馏文件)
    char_distill_dir = os.path.join(SETTINGS_DIR, "角色蒸馏")
    char_files = sorted(glob.glob(os.path.join(char_distill_dir, "*.md")))
    char_map = {}
    for cf in char_files:
        basename = os.path.basename(cf)
        if basename == "TEMPLATE.md":
            continue
        with open(cf, "r", encoding="utf-8") as f:
            content = f.read()

        # 提取角色名
        name_match = re.search(r'^# (.+?)\s*[··]', content)
        name = name_match.group(1).strip() if name_match else basename.replace(".md", "")

        # 提取能力/状态
        ability = ""
        status = {}
        am = re.search(r'当前阶段[：:]\s*(.+)', content)
        if am:
            ability = am.group(1).strip()
        sm = re.search(r'物理状态[：:]\s*(.+)', content)
        if sm:
            status["physical"] = sm.group(1).strip()

        r = query(
            "SELECT id FROM characters WHERE novel_id = %s AND name = %s",
            (novel_id, name), fetch="one"
        )
        if r:
            char_map[name] = r["id"]
            # 更新能力
            if ability:
                query(
                    "UPDATE characters SET ability_level = %s WHERE id = %s",
                    (ability, r["id"]), fetch="none"
                )
            continue

        # 角色类型推断
        role = "npc"
        if "沈野" in name:
            role = "protagonist"
        elif "沈念" in name:
            role = "protagonist"
        elif "方岩" in name:
            role = "ally"

        r = query(
            "INSERT INTO characters (novel_id, name, role, ability_level, status) "
            "VALUES (%s, %s, %s, %s, %s) RETURNING id",
            (novel_id, name, role, ability, json.dumps(status, ensure_ascii=False)),
            fetch="one"
        )
        char_map[name] = r["id"]
    print(f"  创建人物: {len(char_map)} 个")

    # 5. 作者声音 → world_settings
    voice_file = os.path.join(SETTINGS_DIR, "作者声音.md")
    if os.path.exists(voice_file):
        with open(voice_file, "r", encoding="utf-8") as f:
            voice_text = f.read()
        query(
            "INSERT INTO world_settings (novel_id, category, name, data) "
            "VALUES (%s, 'author_voice', '作者声音', %s) "
            "ON CONFLICT (novel_id, category, name) DO UPDATE SET data = %s",
            (novel_id, json.dumps({"content": voice_text[:3000]}, ensure_ascii=False),
             json.dumps({"content": voice_text[:3000]}, ensure_ascii=False)),
            fetch="none"
        )
        print(f"  写入作者声音")

    # 6. 写作规范 → world_settings
    spec_file = os.path.join(SETTINGS_DIR, "写作执行规范.md")
    if os.path.exists(spec_file):
        with open(spec_file, "r", encoding="utf-8") as f:
            spec_text = f.read()
        query(
            "INSERT INTO world_settings (novel_id, category, name, data) "
            "VALUES (%s, 'writing_spec', '写作规范', %s) "
            "ON CONFLICT (novel_id, category, name) DO UPDATE SET data = %s",
            (novel_id, json.dumps({"content": spec_text[:3000]}, ensure_ascii=False),
             json.dumps({"content": spec_text[:3000]}, ensure_ascii=False)),
            fetch="none"
        )
        print(f"  写入写作规范")

    # 7. 覆盖引擎内容（从参考文件灌入）
    engine_dir = os.path.join(PROJECT_ROOT, ".claude/skills/novel-writer/references")
    engine_map = {
        "engine-action.md": "action",
        "engine-dialogue.md": "dialogue",
        "engine-environment.md": "environment",
        "engine-item.md": "item",
    }
    engine_count = 0
    for ef, etype in engine_map.items():
        epath = os.path.join(engine_dir, ef)
        if os.path.exists(epath):
            with open(epath, "r", encoding="utf-8") as f:
                content = f.read()
            query(
                "INSERT INTO world_settings (novel_id, category, name, data) "
                "VALUES (%s, 'engine_reference', %s, %s) "
                "ON CONFLICT (novel_id, category, name) DO UPDATE SET data = %s",
                (novel_id, etype, json.dumps({"content": content[:2000]}, ensure_ascii=False),
                 json.dumps({"content": content[:2000]}, ensure_ascii=False)),
                fetch="none"
            )
            engine_count += 1
    print(f"  写入引擎: {engine_count} 个")

    print(f"\n✅ 恢复完成！小说ID: {novel_id}")
    print(f"   卷: {volume_count}, 章节: {chapter_count}, 人物: {len(char_map)}")


if __name__ == "__main__":
    restore()
