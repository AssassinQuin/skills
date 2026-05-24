-- Novel Writer Database Schema
-- 数据库: fcli, 用户: postgres

-- 小说项目
CREATE TABLE IF NOT EXISTS novels (
    id SERIAL PRIMARY KEY,
    name VARCHAR(100) NOT NULL UNIQUE,
    genre VARCHAR(50),
    target_platform VARCHAR(50), -- fanqie/qidian/zongheng
    status VARCHAR(20) DEFAULT 'brainstorming', -- brainstorming/worldbuilding/character_design/outlining/writing/reviewing/publishing
    current_chapter INTEGER DEFAULT 0,
    total_planned_chapters INTEGER,
    word_count INTEGER DEFAULT 0,
    notes TEXT,
    created_at TIMESTAMP DEFAULT NOW(),
    updated_at TIMESTAMP DEFAULT NOW()
);

-- 世界观设定（按维度）
CREATE TABLE IF NOT EXISTS world_settings (
    id SERIAL PRIMARY KEY,
    novel_id INTEGER REFERENCES novels(id) ON DELETE CASCADE,
    category VARCHAR(50) NOT NULL, -- race/faction/location/ability/economy/daily_life/history
    name VARCHAR(200) NOT NULL,
    data JSONB NOT NULL DEFAULT '{}',
    created_at TIMESTAMP DEFAULT NOW(),
    updated_at TIMESTAMP DEFAULT NOW(),
    UNIQUE(novel_id, category, name)
);

-- 人物
CREATE TABLE IF NOT EXISTS characters (
    id SERIAL PRIMARY KEY,
    novel_id INTEGER REFERENCES novels(id) ON DELETE CASCADE,
    name VARCHAR(100) NOT NULL,
    role VARCHAR(30) DEFAULT 'npc', -- protagonist/ally/antagonist/mentor/rival/love_interest/npc
    faction_id INTEGER,
    race VARCHAR(50),
    ability_level VARCHAR(50),
    status JSONB DEFAULT '{}', -- {hp, location, inventory, mood, current_goal}
    appearance TEXT,
    personality TEXT,
    background TEXT,
    goals TEXT,
    weaknesses TEXT,
    speech_style TEXT, -- 说话风格
    catchphrase TEXT, -- 口头禅
    arc_notes TEXT, -- 成长弧线
    first_appearance_chapter INTEGER,
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP DEFAULT NOW(),
    updated_at TIMESTAMP DEFAULT NOW()
);

-- 人物关系
CREATE TABLE IF NOT EXISTS character_relations (
    id SERIAL PRIMARY KEY,
    novel_id INTEGER REFERENCES novels(id) ON DELETE CASCADE,
    from_character_id INTEGER REFERENCES characters(id) ON DELETE CASCADE,
    to_character_id INTEGER REFERENCES characters(id) ON DELETE CASCADE,
    relation_type VARCHAR(50) NOT NULL, -- ally/enemy/mentor/lover/family/rival/subordinate
    description TEXT,
    chapter_established INTEGER,
    intensity INTEGER DEFAULT 5, -- 1-10, 关系强度
    created_at TIMESTAMP DEFAULT NOW(),
    updated_at TIMESTAMP DEFAULT NOW()
);

-- 章节
CREATE TABLE IF NOT EXISTS chapters (
    id SERIAL PRIMARY KEY,
    novel_id INTEGER REFERENCES novels(id) ON DELETE CASCADE,
    number INTEGER NOT NULL,
    title VARCHAR(200),
    status VARCHAR(20) DEFAULT 'planned', -- planned/drafting/written/reviewed/published
    word_count INTEGER DEFAULT 0,
    outline TEXT,
    chapter_type VARCHAR(30) DEFAULT 'normal', -- normal/transition/climax/filler/daily
    created_at TIMESTAMP DEFAULT NOW(),
    updated_at TIMESTAMP DEFAULT NOW(),
    UNIQUE(novel_id, number)
);

-- 章节摘要
CREATE TABLE IF NOT EXISTS chapter_summaries (
    id SERIAL PRIMARY KEY,
    chapter_id INTEGER REFERENCES chapters(id) ON DELETE CASCADE UNIQUE,
    summary TEXT NOT NULL,
    key_events JSONB DEFAULT '[]', -- [{event, characters, location}]
    characters_involved INTEGER[] DEFAULT '{}', -- character ids
    new_foreshadows INTEGER[] DEFAULT '{}', -- foreshadow ids planted in this chapter
    resolved_foreshadows INTEGER[] DEFAULT '{}', -- foreshadow ids resolved
    dimension_snapshot JSONB DEFAULT '{}', -- {time_point, location_ids, ability_changes}
    created_at TIMESTAMP DEFAULT NOW()
);

-- 伏笔
CREATE TABLE IF NOT EXISTS foreshadows (
    id SERIAL PRIMARY KEY,
    novel_id INTEGER REFERENCES novels(id) ON DELETE CASCADE,
    description TEXT NOT NULL,
    planted_chapter_id INTEGER REFERENCES chapters(id),
    planned_recall_chapter INTEGER,
    actual_recall_chapter_id INTEGER REFERENCES chapters(id),
    status VARCHAR(20) DEFAULT 'planted', -- planted/recalled/abandoned
    importance VARCHAR(10) DEFAULT 'medium', -- high/medium/low
    related_characters INTEGER[] DEFAULT '{}',
    tags TEXT[] DEFAULT '{}',
    created_at TIMESTAMP DEFAULT NOW(),
    updated_at TIMESTAMP DEFAULT NOW()
);

-- 时间线事件
CREATE TABLE IF NOT EXISTS timeline_events (
    id SERIAL PRIMARY KEY,
    novel_id INTEGER REFERENCES novels(id) ON DELETE CASCADE,
    chapter_id INTEGER REFERENCES chapters(id),
    event_time VARCHAR(200), -- 故事内时间描述
    event_order INTEGER, -- 事件序号（用于排序）
    event_description TEXT NOT NULL,
    characters_involved INTEGER[] DEFAULT '{}',
    location_id INTEGER REFERENCES world_settings(id),
    significance VARCHAR(10) DEFAULT 'normal', -- critical/major/normal/minor
    created_at TIMESTAMP DEFAULT NOW()
);

-- 场景大纲
CREATE TABLE IF NOT EXISTS scene_outlines (
    id SERIAL PRIMARY KEY,
    chapter_id INTEGER REFERENCES chapters(id) ON DELETE CASCADE,
    scene_number INTEGER NOT NULL,
    location VARCHAR(200),
    characters_involved INTEGER[] DEFAULT '{}',
    conflict TEXT,
    emotion_type VARCHAR(30), -- tension/cool/sad/fun/daily/touching
    word_target INTEGER DEFAULT 2000,
    key_beats JSONB DEFAULT '[]', -- [{beat, description}]
    notes TEXT,
    UNIQUE(chapter_id, scene_number)
);

-- 维度变更日志（追踪每章的时间/空间/能力变化）
CREATE TABLE IF NOT EXISTS dimension_changes (
    id SERIAL PRIMARY KEY,
    novel_id INTEGER REFERENCES novels(id) ON DELETE CASCADE,
    chapter_id INTEGER REFERENCES chapters(id),
    dimension VARCHAR(30) NOT NULL, -- time/space/ability/economy/character_status
    change_type VARCHAR(30) NOT NULL, -- create/update/delete
    entity_name VARCHAR(200),
    before_value JSONB,
    after_value JSONB,
    description TEXT,
    created_at TIMESTAMP DEFAULT NOW()
);

-- 索引
CREATE INDEX IF NOT EXISTS idx_world_settings_novel_category ON world_settings(novel_id, category);
CREATE INDEX IF NOT EXISTS idx_characters_novel ON characters(novel_id);
CREATE INDEX IF NOT EXISTS idx_character_relations_novel ON character_relations(novel_id);
CREATE INDEX IF NOT EXISTS idx_chapters_novel_number ON chapters(novel_id, number);
CREATE INDEX IF NOT EXISTS idx_foreshadows_novel_status ON foreshadows(novel_id, status);
CREATE INDEX IF NOT EXISTS idx_timeline_novel_order ON timeline_events(novel_id, event_order);
CREATE INDEX IF NOT EXISTS idx_dimension_changes_novel ON dimension_changes(novel_id, chapter_id);
