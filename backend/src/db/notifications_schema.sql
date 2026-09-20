-- =========================================================
-- SmartEve Notification System PostgreSQL Schema (Neon.tech)
-- =========================================================

-- Ensure UUID extensions exist
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "pgcrypto";

-- Enum types for priorities and device types
DO $$ BEGIN CREATE TYPE priority_level AS ENUM ('low', 'medium', 'high', 'urgent'); EXCEPTION WHEN duplicate_object THEN null; END $$;
DO $$ BEGIN CREATE TYPE device_type_enum AS ENUM ('ios', 'android', 'web'); EXCEPTION WHEN duplicate_object THEN null; END $$;

-- ==================== 1. NOTIFICATIONS TABLE ====================
CREATE TABLE IF NOT EXISTS notifications (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    recipient_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    sender_id UUID REFERENCES users(id) ON DELETE SET NULL,
    notification_type VARCHAR(50) NOT NULL, -- e.g. anchor_invitation, direct_message, etc.
    title VARCHAR(255) NOT NULL,
    message TEXT NOT NULL,
    data JSONB DEFAULT '{}'::jsonb, -- Extra payload data (event_id, anchor_id, speaker_id, etc.)
    
    -- Targeting & Status
    recipient_role VARCHAR(20), -- 'organizer', 'anchor', 'admin'
    is_read BOOLEAN DEFAULT FALSE,
    is_deleted BOOLEAN DEFAULT FALSE,
    read_at TIMESTAMP NULL,
    
    -- Action Links
    action_url VARCHAR(500), -- Deep link URL (e.g. app://events/{eventId}/details)
    action_type VARCHAR(50), -- 'invite', 'message', 'update', 'alert', 'script', 'sos'
    priority priority_level DEFAULT 'medium',
    
    -- Related Entities
    event_id UUID REFERENCES events(id) ON DELETE CASCADE,
    anchor_id UUID REFERENCES users(id) ON DELETE SET NULL,
    organizer_id UUID REFERENCES users(id) ON DELETE SET NULL,
    speaker_id UUID REFERENCES speakers(id) ON DELETE SET NULL,
    
    -- Timestamps
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    expires_at TIMESTAMP NULL, -- Auto-delete/archive after expiry
    scheduled_for TIMESTAMP NULL -- For scheduled notifications
);

-- ==================== 2. PUSH NOTIFICATION TOKENS ====================
CREATE TABLE IF NOT EXISTS push_notification_tokens (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    device_id VARCHAR(255) UNIQUE NOT NULL,
    device_type VARCHAR(20) NOT NULL DEFAULT 'android', -- 'ios', 'android', 'web'
    fcm_token VARCHAR(500) NOT NULL UNIQUE, -- Firebase Cloud Messaging Token
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    last_used_at TIMESTAMP NULL,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- ==================== 3. NOTIFICATION PREFERENCES ====================
CREATE TABLE IF NOT EXISTS notification_preferences (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL UNIQUE REFERENCES users(id) ON DELETE CASCADE,
    
    -- Global channels
    push_enabled BOOLEAN DEFAULT TRUE,
    in_app_enabled BOOLEAN DEFAULT TRUE,
    email_enabled BOOLEAN DEFAULT TRUE,
    
    -- By notification type
    invitations_enabled BOOLEAN DEFAULT TRUE,
    messages_enabled BOOLEAN DEFAULT TRUE,
    updates_enabled BOOLEAN DEFAULT TRUE,
    announcements_enabled BOOLEAN DEFAULT TRUE,
    alerts_enabled BOOLEAN DEFAULT TRUE,
    reminders_enabled BOOLEAN DEFAULT TRUE,
    
    -- Sound & Vibration
    sound_enabled BOOLEAN DEFAULT TRUE,
    vibration_enabled BOOLEAN DEFAULT TRUE,
    
    -- Quiet hours
    quiet_hours_enabled BOOLEAN DEFAULT FALSE,
    quiet_hours_start TIME DEFAULT '22:00:00',
    quiet_hours_end TIME DEFAULT '07:00:00',
    quiet_hours_timezone VARCHAR(50) DEFAULT 'UTC',
    
    -- Digest options
    daily_digest_enabled BOOLEAN DEFAULT FALSE,
    digest_time TIME DEFAULT '09:00:00',
    
    -- Push notification specific toggles
    push_for_invitations BOOLEAN DEFAULT TRUE,
    push_for_messages BOOLEAN DEFAULT TRUE,
    push_for_urgent_alerts BOOLEAN DEFAULT TRUE,
    push_for_event_reminders BOOLEAN DEFAULT TRUE,
    
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- ==================== 4. NOTIFICATION READ STATUS ====================
CREATE TABLE IF NOT EXISTS notification_read_status (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    notification_id UUID NOT NULL REFERENCES notifications(id) ON DELETE CASCADE,
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    is_read BOOLEAN DEFAULT FALSE,
    read_at TIMESTAMP NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    UNIQUE(notification_id, user_id)
);

-- ==================== 5. NOTIFICATION ARCHIVE ====================
CREATE TABLE IF NOT EXISTS notifications_archive (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    original_notification_id UUID,
    recipient_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    sender_id UUID REFERENCES users(id) ON DELETE SET NULL,
    notification_type VARCHAR(50),
    title VARCHAR(255),
    message TEXT,
    data JSONB,
    action_url VARCHAR(500),
    event_id UUID REFERENCES events(id) ON DELETE SET NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    archived_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- ==================== INDEXES ====================
CREATE INDEX IF NOT EXISTS idx_notifications_recipient_id ON notifications(recipient_id);
CREATE INDEX IF NOT EXISTS idx_notifications_is_read ON notifications(is_read);
CREATE INDEX IF NOT EXISTS idx_notifications_created_at ON notifications(created_at DESC);
CREATE INDEX IF NOT EXISTS idx_notifications_type ON notifications(notification_type);
CREATE INDEX IF NOT EXISTS idx_notifications_event_id ON notifications(event_id);
CREATE INDEX IF NOT EXISTS idx_notifications_recipient_created ON notifications(recipient_id, created_at DESC);
CREATE INDEX IF NOT EXISTS idx_push_tokens_user_id ON push_notification_tokens(user_id);
CREATE INDEX IF NOT EXISTS idx_push_tokens_active ON push_notification_tokens(is_active);
CREATE INDEX IF NOT EXISTS idx_notification_prefs_user ON notification_preferences(user_id);
