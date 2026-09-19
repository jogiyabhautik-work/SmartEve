-- =========================================================
-- SmartEve Neon.tech Serverless PostgreSQL Schema
-- =========================================================

-- Enable UUID & Crypto extensions
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "pgcrypto";

-- ==================== ENUM TYPES ====================
DO $$ BEGIN CREATE TYPE user_role AS ENUM ('admin', 'organizer', 'anchor'); EXCEPTION WHEN duplicate_object THEN null; END $$;
DO $$ BEGIN CREATE TYPE event_type AS ENUM ('hackathon', 'workshop', 'seminar', 'competition', 'cultural_program'); EXCEPTION WHEN duplicate_object THEN null; END $$;
DO $$ BEGIN CREATE TYPE event_status AS ENUM ('draft', 'scheduled', 'live', 'completed', 'cancelled'); EXCEPTION WHEN duplicate_object THEN null; END $$;
DO $$ BEGIN CREATE TYPE anchor_status AS ENUM ('invited', 'accepted', 'rejected', 'active', 'completed'); EXCEPTION WHEN duplicate_object THEN null; END $$;
DO $$ BEGIN CREATE TYPE agenda_item_type AS ENUM ('opening', 'speaker_session', 'activity', 'break', 'closing'); EXCEPTION WHEN duplicate_object THEN null; END $$;
DO $$ BEGIN CREATE TYPE agenda_item_status AS ENUM ('scheduled', 'in_progress', 'completed', 'delayed', 'cancelled'); EXCEPTION WHEN duplicate_object THEN null; END $$;
DO $$ BEGIN CREATE TYPE script_type AS ENUM ('opening', 'speaker_intro', 'transition', 'closing', 'announcement'); EXCEPTION WHEN duplicate_object THEN null; END $$;
DO $$ BEGIN CREATE TYPE announcement_type AS ENUM ('schedule_change', 'unexpected', 'info', 'emergency'); EXCEPTION WHEN duplicate_object THEN null; END $$;
DO $$ BEGIN CREATE TYPE priority_level AS ENUM ('low', 'medium', 'high', 'urgent'); EXCEPTION WHEN duplicate_object THEN null; END $$;
DO $$ BEGIN CREATE TYPE timeline_status AS ENUM ('pending', 'approved', 'rejected'); EXCEPTION WHEN duplicate_object THEN null; END $$;
DO $$ BEGIN CREATE TYPE media_asset_type AS ENUM ('poster', 'speaker_image', 'event_photo', 'document'); EXCEPTION WHEN duplicate_object THEN null; END $$;
DO $$ BEGIN CREATE TYPE audit_action_type AS ENUM ('create', 'update', 'delete', 'approve', 'publish', 'start', 'end'); EXCEPTION WHEN duplicate_object THEN null; END $$;

-- ==================== 1. USERS TABLE ====================
CREATE TABLE IF NOT EXISTS users (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    firebase_uid VARCHAR(255) UNIQUE NOT NULL,
    email VARCHAR(255) UNIQUE NOT NULL,
    full_name VARCHAR(255) NOT NULL,
    role user_role NOT NULL,
    profile_image_url VARCHAR(500),
    phone_number VARCHAR(20),
    bio TEXT,
    profile_data JSONB DEFAULT '{}'::jsonb,
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    deleted_at TIMESTAMP NULL
);

-- ==================== 2. EVENTS TABLE ====================
CREATE TABLE IF NOT EXISTS events (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    title VARCHAR(255) NOT NULL,
    description TEXT,
    event_type event_type NOT NULL,
    start_date TIMESTAMP NOT NULL,
    end_date TIMESTAMP NOT NULL,
    location VARCHAR(255),
    max_attendees INT,
    poster_url VARCHAR(500), -- Cloudinary URL
    created_by UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    status event_status DEFAULT 'draft',
    is_published BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    deleted_at TIMESTAMP NULL
);

-- ==================== 3. EVENT ORGANIZERS (Many-to-Many) ====================
CREATE TABLE IF NOT EXISTS event_organizers (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    event_id UUID NOT NULL REFERENCES events(id) ON DELETE CASCADE,
    organizer_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    role VARCHAR(100) DEFAULT 'co-organizer', -- primary_organizer, co-organizer
    joined_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    UNIQUE(event_id, organizer_id)
);

-- ==================== 4. EVENT ANCHORS (Many-to-Many) ====================
CREATE TABLE IF NOT EXISTS event_anchors (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    event_id UUID NOT NULL REFERENCES events(id) ON DELETE CASCADE,
    anchor_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    assigned_by UUID REFERENCES users(id) ON DELETE SET NULL,
    status anchor_status DEFAULT 'invited',
    invited_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    accepted_at TIMESTAMP NULL,
    activated_at TIMESTAMP NULL, -- When they go live
    completed_at TIMESTAMP NULL,
    notes TEXT,
    UNIQUE(event_id, anchor_id)
);

-- ==================== 5. SPEAKERS TABLE ====================
CREATE TABLE IF NOT EXISTS speakers (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    event_id UUID NOT NULL REFERENCES events(id) ON DELETE CASCADE,
    name VARCHAR(255) NOT NULL,
    email VARCHAR(255),
    phone_number VARCHAR(20),
    bio TEXT,
    profile_image_url VARCHAR(500), -- Cloudinary URL
    designation VARCHAR(255),
    organization VARCHAR(255),
    expertise_area VARCHAR(255),
    social_links JSONB, -- {linkedin: "", twitter: "", website: ""}
    order_in_event INT, -- Speaking order
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- ==================== 6. AGENDA ITEMS TABLE ====================
CREATE TABLE IF NOT EXISTS agenda_items (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    event_id UUID NOT NULL REFERENCES events(id) ON DELETE CASCADE,
    title VARCHAR(255) NOT NULL,
    description TEXT,
    type agenda_item_type NOT NULL,
    speaker_id UUID REFERENCES speakers(id) ON DELETE SET NULL,
    start_time TIMESTAMP NOT NULL,
    end_time TIMESTAMP NOT NULL,
    duration_minutes INT,
    order_in_agenda INT NOT NULL,
    status agenda_item_status DEFAULT 'scheduled',
    actual_start_time TIMESTAMP NULL,
    actual_end_time TIMESTAMP NULL,
    notes TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- ==================== 7. AI SCRIPTS TABLE ====================
CREATE TABLE IF NOT EXISTS ai_scripts (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    event_id UUID NOT NULL REFERENCES events(id) ON DELETE CASCADE,
    agenda_item_id UUID REFERENCES agenda_items(id) ON DELETE SET NULL,
    script_type script_type NOT NULL,
    title VARCHAR(255),
    content TEXT NOT NULL,
    version INT DEFAULT 1,
    is_approved BOOLEAN DEFAULT FALSE,
    approved_by UUID REFERENCES users(id),
    created_by UUID NOT NULL REFERENCES users(id),
    generated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    approved_at TIMESTAMP NULL,
    used_at TIMESTAMP NULL, -- When anchor used it live
    ai_model VARCHAR(100) DEFAULT 'claude', -- claude, gpt, etc.
    ai_prompt TEXT, -- The prompt used to generate
    tone VARCHAR(100), -- formal, casual, motivational
    target_audience VARCHAR(255),
    custom_params JSONB, -- Additional customization
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- ==================== 8. SCRIPT VERSIONS (History) ====================
CREATE TABLE IF NOT EXISTS script_versions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    script_id UUID NOT NULL REFERENCES ai_scripts(id) ON DELETE CASCADE,
    version_number INT NOT NULL,
    content TEXT NOT NULL,
    edited_by UUID REFERENCES users(id),
    edit_reason VARCHAR(255),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    UNIQUE(script_id, version_number)
);

-- ==================== 9. ANNOUNCEMENTS TABLE ====================
CREATE TABLE IF NOT EXISTS announcements (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    event_id UUID NOT NULL REFERENCES events(id) ON DELETE CASCADE,
    created_by UUID NOT NULL REFERENCES users(id),
    content TEXT NOT NULL,
    announcement_type announcement_type NOT NULL,
    priority priority_level DEFAULT 'medium',
    ai_generated BOOLEAN DEFAULT FALSE,
    ai_suggestion TEXT, -- AI-suggested announcement
    is_approved BOOLEAN DEFAULT FALSE,
    approved_by UUID REFERENCES users(id),
    is_sent BOOLEAN DEFAULT FALSE,
    sent_at TIMESTAMP NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- ==================== 10. EVENT TIMELINE/DELAYS TABLE ====================
CREATE TABLE IF NOT EXISTS event_timeline_updates (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    event_id UUID NOT NULL REFERENCES events(id) ON DELETE CASCADE,
    agenda_item_id UUID REFERENCES agenda_items(id) ON DELETE CASCADE,
    delay_minutes INT, -- Positive for delay, negative for speedup
    reason VARCHAR(255),
    updated_by UUID NOT NULL REFERENCES users(id),
    status timeline_status DEFAULT 'pending',
    approved_by UUID REFERENCES users(id),
    approved_at TIMESTAMP NULL,
    is_applied BOOLEAN DEFAULT FALSE,
    applied_at TIMESTAMP NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- ==================== 11. MEDIA/ASSETS TABLE ====================
CREATE TABLE IF NOT EXISTS media_assets (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    event_id UUID NOT NULL REFERENCES events(id) ON DELETE CASCADE,
    asset_type media_asset_type NOT NULL,
    cloudinary_url VARCHAR(500) NOT NULL,
    cloudinary_public_id VARCHAR(255), -- For deletion later
    uploaded_by UUID NOT NULL REFERENCES users(id),
    uploaded_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- ==================== 12. EVENT LOGS/AUDIT TABLE ====================
CREATE TABLE IF NOT EXISTS event_logs (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    event_id UUID NOT NULL REFERENCES events(id) ON DELETE CASCADE,
    user_id UUID REFERENCES users(id),
    action VARCHAR(255) NOT NULL,
    action_type audit_action_type NOT NULL,
    details JSONB,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- ==================== INDEXES ====================
CREATE INDEX IF NOT EXISTS idx_users_email ON users(email);
CREATE INDEX IF NOT EXISTS idx_users_firebase_uid ON users(firebase_uid);
CREATE INDEX IF NOT EXISTS idx_events_created_by ON events(created_by);
CREATE INDEX IF NOT EXISTS idx_events_status ON events(status);
CREATE INDEX IF NOT EXISTS idx_events_start_date ON events(start_date);
CREATE INDEX IF NOT EXISTS idx_event_organizers_event_id ON event_organizers(event_id);
CREATE INDEX IF NOT EXISTS idx_event_anchors_event_id ON event_anchors(event_id);
CREATE INDEX IF NOT EXISTS idx_speakers_event_id ON speakers(event_id);
CREATE INDEX IF NOT EXISTS idx_agenda_items_event_id ON agenda_items(event_id);
CREATE INDEX IF NOT EXISTS idx_agenda_items_status ON agenda_items(status);
CREATE INDEX IF NOT EXISTS idx_ai_scripts_event_id ON ai_scripts(event_id);
CREATE INDEX IF NOT EXISTS idx_ai_scripts_script_type ON ai_scripts(script_type);
CREATE INDEX IF NOT EXISTS idx_announcements_event_id ON announcements(event_id);
CREATE INDEX IF NOT EXISTS idx_event_timeline_event_id ON event_timeline_updates(event_id);
CREATE INDEX IF NOT EXISTS idx_event_logs_event_id ON event_logs(event_id);