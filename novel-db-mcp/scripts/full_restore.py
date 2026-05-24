"""全量恢复：人物/关系/势力/能力/世界观 从文件到DB"""

import json, os, re, sys, glob, yaml
sys.path.insert(0, '/Users/ganjie/skills/novel-db-mcp')
from server import query

NOVEL_ID = 12
BASE = "/Users/ganjie/code/personal/bywork/books_creater/novels/这次不一样了/设定"

# ── 1. 全量人物（从角色快速参考卡.md + 角色深化.md提取）──
ALL_CHARACTERS = [
    # name, role, ability, stage, attitude_anchor, status, speech_style, appearance
    ("沈野", "protagonist", "灵能解构/铸造", "萌芽(V1-V3)", "沈念唯一(10)", "指尖深红", "极短句，沉默寡言", "瘦高，棉衣肩膀有灰蜥爪痕，领口高拉"),
    ("沈念", "protagonist", "无能力", "无能力", "沈野唯一(10)", "灵衰症中期，灌注维持", "话唠，爱扯日常", "棉衣袖盖手指，围裙洗得发白"),
    ("方岩", "ally", "地形感知", "稳定(V1-V9)", "沈念心疼→家人(10)", "右腿伤恢复中", "简洁军人式干脆", "褪色军用包+旧棉衣，中年"),
    ("陆沉", "ally", "灵能分解", "发展(V3-V7)", "沈念关心→不舍(9)", "平静闷不说", "话少，冷", "苍白，眼角皱纹"),
    ("汐", "ally", "波动感知/碑文翻译", "发展(V3-V6)", "沈念温暖→唯一(10)", "好奇警惕", "语速慢，生涩", "月裔特征，常看人表情"),
    ("蔓", "ally", "编织物理→编灵能", "质变(V7)", "沈野观察→家人(9)", "好奇警觉", "简练，观察型", "年轻"),
    ("江屿", "ally", "强化体质", "稳定(V3-V7)", "柳陌复杂→释然(0)", "叛逃中紧张", "犹豫，有时结巴", "灵枢制服"),
    ("柳陌", "antagonist", "印记刻录", "稳定(V3-V11)", "灵枢信仰→崩塌(0)", "信仰驱动→茫然", "权威，说教感", "灵枢高阶制服"),
    ("钟衍", "ally", "共振解析", "稳定(V2-V7)", "女儿唯一(10)", "压抑平静", "少言，疲惫", "研究员白大褂"),
    ("韩朗", "antagonist", "灵能固化", "稳定(V1-V7)", "灵枢职业→崩塌(0)", "签文件手很稳", "职业化温和", "深灰制服"),
    ("赵铁山", "ally", "体魄共振", "稳定(V1-V10)", "壁盾信仰(10)", "沉稳压抑", "命令式短句", "壁盾戎装"),
    ("林原", "ally", "结构透视", "稳定(V5-V12)", "沈念数据→尊重(9)", "冷静自控", "精准冷淡", "白大褂，灰发"),
    ("陈启明", "ally", "异常预警", "发展(V1-V7)", "方岩信任→重逢(7)", "底层分析师", "焦虑式快语", "旧军装沾机油"),
    ("沈鹤", "ally", "回响感知", "崩塌(V12)", "教会信仰→重建(5)", "半信半疑", "沉稳，偶尔动摇", "教会长袍"),
    ("周远", "ally", "无能力", "无能力", "妹妹唯一(10)", "坚定执行", "坚定短促", "便装，朴素"),
    ("焱", "antagonist", "T4火焰", "稳定(V1-V13)", "人类恐惧→困惑(4)", "主战派统帅", "愤怒，爆发式", "深红鳞甲"),
    ("织", "antagonist", "T4编织", "稳定(V5-V12)", "蔓学生→失望(3)", "冷酷共存", "冷淡教育式", "暗蓝色透明"),
    ("蓁", "antagonist", "T3巢穴母体", "消耗(V1-V8)", "幼体全部(10)", "不停生育", "无声", "巨大巢状"),
    ("鸦", "ally", "T3信息中枢", "终局(V13)", "沈念恩人→唯一(10)", "独行→追踪", "短促，信息密集", "黑羽，半机械"),
    ("虞渊", "ally", "灵能同化", "终局(V13-V14)", "封绝原罪(10)", "麻木人性消退", "缓慢，古老", "400年不变的面容"),
    ("封绝", "ally", "分解", "终局(纪元1末)", "虞渊唯一(10)", "已故(封印)", "——", "——"),
    ("裴昭", "ally", "铸造", "终局(纪元2)", "虞渊忠诚(10)", "意识困容器", "——", "——"),
    ("裴晗", "ally", "铸造", "终局(纪元2)", "裴昭哥哥(10)", "已故(铸墙)", "——", "——"),
    ("影", "ally", "T3拟态", "终局(V8)", "城镇保护→牺牲(8)", "已牺牲", "新学语气的生疏感", "拟态人形"),
    ("渊", "ally", "远古意识", "远古", "汐血脉(7)", "沉睡/苏醒", "古老回音感", "无固定形态"),
]

char_map = {}
count = 0
for name, role, ability, stage, attitude, status, speech, appearance in ALL_CHARACTERS:
    existing = query("SELECT id FROM characters WHERE novel_id = %s AND name = %s", (NOVEL_ID, name), fetch="one")
    if existing:
        char_map[name] = existing["id"]
        query("UPDATE characters SET role=%s, ability_level=%s, speech_style=%s, appearance=%s WHERE id=%s",
              (role, f"{ability} {stage}", speech, appearance, existing["id"]), fetch="none")
        continue
    r = query(
        "INSERT INTO characters (novel_id, name, role, ability_level, speech_style, appearance, status) "
        "VALUES (%s, %s, %s, %s, %s, %s, %s) RETURNING id",
        (NOVEL_ID, name, role, f"{ability} {stage}", speech, appearance,
         json.dumps({"attitude": attitude, "status": status}, ensure_ascii=False)),
        fetch="one"
    )
    char_map[name] = r["id"]
    count += 1
print(f"  人物: 全量{len(ALL_CHARACTERS)}个（新增{count}）")

# ── 2. 关系网（从角色快速参考卡.md） ──
ALL_RELATIONS = [
    ("沈野", "沈念", "family", "兄妹相依为命", 1),
    ("沈野", "方岩", "ally", "从相互注意→生死之交", 5),
    ("沈野", "陆沉", "ally", "同行信任", 3),
    ("沈野", "汐", "ally", "观察→接纳", 5),
    ("沈野", "蔓", "ally", "观察→家人", 7),
    ("沈念", "汐", "ally", "姐妹情", 5),
    ("沈念", "方岩", "ally", "方岩心疼沈念", 1),
    ("沈念", "陆沉", "ally", "关心→不舍", 3),
    ("沈念", "林原", "ally", "数据关系→尊重", 5),
    ("沈念", "鸦", "ally", "恩人→唯一", 13),
    ("方岩", "陈启明", "ally", "信任→重逢", 1),
    ("方岩", "赵铁山", "ally", "壁盾同僚", 1),
    ("陆沉", "虞渊", "ally", "同族/同命", 10),
    ("陆沉", "封绝", "ally", "隔代传承", 1),
    ("江屿", "柳陌", "ally", "复杂→释然", 3),
    ("柳陌", "韩朗", "ally", "灵枢共事", 1),
    ("虞渊", "封绝", "ally", "唯一", 1),
    ("虞渊", "裴昭", "ally", "忠诚", 2),
    ("虞渊", "裴晗", "ally", "忠诚", 2),
    ("焱", "织", "ally", "同族", 1),
    ("炎", "蓁", "ally", "同族", 1),
    ("汐", "蔓", "ally", "月裔同族", 7),
    ("汐", "渊", "ally", "血脉祖先", 1),
    ("蔓", "织", "ally", "学生→失望", 5),
]

for f, t, rel, desc, ch in ALL_RELATIONS:
    if f in char_map and t in char_map:
        query(
            "INSERT INTO character_relations (novel_id, from_character_id, to_character_id, "
            "relation_type, description, chapter_established) "
            "VALUES (%s, %s, %s, %s, %s, %s) ON CONFLICT DO NOTHING",
            (NOVEL_ID, char_map[f], char_map[t], rel, desc, ch), fetch="none"
        )
print(f"  关系: {len(ALL_RELATIONS)}条")

# ── 3. 势力（从lorebook YAML） ──
lore_dir = os.path.join(BASE, "lorebook/entries/势力")
faction_count = 0
for yf in sorted(glob.glob(os.path.join(lore_dir, "*.yml"))):
    with open(yf, "r", encoding="utf-8") as f:
        try:
            data = yaml.safe_load(f)
        except:
            continue
    name = data.get("name", os.path.basename(yf).replace(".yml",""))
    content_str = yaml.dump(data, allow_unicode=True, default_flow_style=False)[:2000]
    query(
        "INSERT INTO world_settings (novel_id, category, name, data) "
        "VALUES (%s, 'faction', %s, %s) ON CONFLICT (novel_id, category, name) DO UPDATE SET data = %s",
        (NOVEL_ID, name, json.dumps({"content": content_str}, ensure_ascii=False),
         json.dumps({"content": content_str}, ensure_ascii=False)),
        fetch="none"
    )
    faction_count += 1
print(f"  势力: {faction_count}个（从lorebook）")

# ── 4. 世界观：地点/核心设定 ──
for subdir in ["地点", "核心设定"]:
    entry_dir = os.path.join(BASE, f"lorebook/entries/{subdir}")
    if not os.path.isdir(entry_dir):
        continue
    for yf in sorted(glob.glob(os.path.join(entry_dir, "*.yml"))):
        with open(yf, "r", encoding="utf-8") as f:
            try:
                data = yaml.safe_load(f)
            except:
                continue
        name = data.get("name", os.path.basename(yf).replace(".yml",""))
        cat = "location" if subdir == "地点" else "core_setting"
        content_str = yaml.dump(data, allow_unicode=True, default_flow_style=False)[:2000]
        query(
            "INSERT INTO world_settings (novel_id, category, name, data) "
            "VALUES (%s, %s, %s, %s) ON CONFLICT (novel_id, category, name) DO UPDATE SET data = %s",
            (NOVEL_ID, cat, name, json.dumps({"content": content_str}, ensure_ascii=False),
             json.dumps({"content": content_str}, ensure_ascii=False)),
            fetch="none"
        )
        print(f"  世界观(lorebook/{subdir}): {name}")

# ── 5. 能力详细设定 ──
ability_file = os.path.join(BASE, "人物能力设定方案.md")
if os.path.exists(ability_file):
    with open(ability_file, "r", encoding="utf-8") as f:
        text = f.read()
    # 按角色分节
    sections = re.split(r'^### ', text, flags=re.MULTILINE)
    for sec in sections:
        if not sec.strip():
            continue
        name = sec.split("\n")[0].strip().rstrip(" —").strip()
        # Only store if it's a character ability section
        if len(name) > 0 and len(name) < 20 and not name.startswith("#"):
            # Find which character this is for, store under their name
            for char_name in char_map:
                if char_name in sec[:20]:
                    query(
                        "INSERT INTO world_settings (novel_id, category, name, data) "
                        "VALUES (%s, 'ability', %s, %s) ON CONFLICT (novel_id, category, name) DO UPDATE SET data = %s",
                        (NOVEL_ID, f"能力_{char_name}",
                         json.dumps({"content": sec[:2000]}, ensure_ascii=False),
                         json.dumps({"content": sec[:2000]}, ensure_ascii=False)),
                        fetch="none"
                    )
                    print(f"  能力设定: {char_name}")
                    break

print(f"\n✅ 全量恢复完成！")
print(f"  人物: {len(char_map)} | 关系: {len(ALL_RELATIONS)} | 势力: {faction_count}")
