import { query, hasDbConfig } from "../../config/db.js";
import { sendFcmNotification } from "./fcm.js";
import {
  NotificationType,
  NotificationPayload,
  NotificationPreferences,
  PriorityLevel,
  PushTokenRecord,
} from "../../types/notification_system.js";

export interface DBNotification {
  id: string;
  recipient_id: string;
  sender_id?: string | null;
  notification_type: string;
  title: string;
  message: string;
  data: any;
  recipient_role: string;
  is_read: boolean;
  is_deleted: boolean;
  read_at?: Date | null;
  action_url?: string | null;
  action_type?: string | null;
  priority: PriorityLevel;
  event_id?: string | null;
  created_at: Date | number;
}

// In-memory fallback store when Neon DB is not initialized or in test environment
const memoryNotifications: DBNotification[] = [];
const memoryPreferences: Map<string, Partial<NotificationPreferences>> = new Map();
const memoryTokens: PushTokenRecord[] = [];

function isUuid(str?: string): boolean {
  if (!str) return false;
  return /^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$/.test(str.trim());
}

/**
 * Checks if current time falls within user's configured Quiet Hours.
 */
export function isInQuietHours(prefs: Partial<NotificationPreferences>): boolean {
  if (!prefs.quietHoursEnabled) return false;
  if (!prefs.quietHoursStart || !prefs.quietHoursEnd) return false;

  const now = new Date();
  const currentMin = now.getHours() * 60 + now.getMinutes();

  const [sH, sM] = prefs.quietHoursStart.split(":").map(Number);
  const [eH, eM] = prefs.quietHoursEnd.split(":").map(Number);
  const startMin = (sH || 0) * 60 + (sM || 0);
  const endMin = (eH || 0) * 60 + (eM || 0);

  if (startMin < endMin) {
    return currentMin >= startMin && currentMin < endMin;
  } else {
    return currentMin >= startMin || currentMin < endMin;
  }
}

/**
 * Get user notification preferences from DB or memory fallback.
 */
export async function getPreferences(userId: string): Promise<NotificationPreferences> {
  const defaults: NotificationPreferences = {
    userId,
    pushEnabled: true,
    inAppEnabled: true,
    emailEnabled: true,
    invitationsEnabled: true,
    messagesEnabled: true,
    updatesEnabled: true,
    announcementsEnabled: true,
    alertsEnabled: true,
    remindersEnabled: true,
    soundEnabled: true,
    vibrationEnabled: true,
    quietHoursEnabled: false,
    quietHoursStart: "22:00:00",
    quietHoursEnd: "07:00:00",
    quietHoursTimezone: "UTC",
    dailyDigestEnabled: false,
    digestTime: "09:00:00",
  };

  if (hasDbConfig && isUuid(userId) && process.env.NODE_ENV !== "test") {
    try {
      const rows = await query<any>(
        `SELECT * FROM notification_preferences WHERE user_id = $1`,
        [userId]
      );
      if (rows && rows.length > 0) {
        const r = rows[0];
        return {
          userId,
          pushEnabled: r.push_enabled ?? true,
          inAppEnabled: r.in_app_enabled ?? true,
          emailEnabled: r.email_enabled ?? true,
          invitationsEnabled: r.invitations_enabled ?? true,
          messagesEnabled: r.messages_enabled ?? true,
          updatesEnabled: r.updates_enabled ?? true,
          announcementsEnabled: r.announcements_enabled ?? true,
          alertsEnabled: r.alerts_enabled ?? true,
          remindersEnabled: r.reminders_enabled ?? true,
          soundEnabled: r.sound_enabled ?? true,
          vibrationEnabled: r.vibration_enabled ?? true,
          quietHoursEnabled: r.quiet_hours_enabled ?? false,
          quietHoursStart: r.quiet_hours_start || "22:00:00",
          quietHoursEnd: r.quiet_hours_end || "07:00:00",
          quietHoursTimezone: r.quiet_hours_timezone || "UTC",
          dailyDigestEnabled: r.daily_digest_enabled ?? false,
          digestTime: r.digest_time || "09:00:00",
        };
      }
    } catch (err) {
      console.warn("DB preferences lookup failed, using fallback:", (err as Error).message);
    }
  }

  const mem = memoryPreferences.get(userId);
  return { ...defaults, ...mem };
}

/**
 * Save or update user notification preferences.
 */
export async function updatePreferences(
  userId: string,
  updates: Partial<NotificationPreferences>
): Promise<NotificationPreferences> {
  const current = await getPreferences(userId);
  const updated = { ...current, ...updates, userId };

  if (hasDbConfig && isUuid(userId) && process.env.NODE_ENV !== "test") {
    try {
      await query(
        `INSERT INTO notification_preferences (
          user_id, push_enabled, in_app_enabled, email_enabled,
          invitations_enabled, messages_enabled, updates_enabled,
          announcements_enabled, alerts_enabled, reminders_enabled,
          sound_enabled, vibration_enabled, quiet_hours_enabled,
          quiet_hours_start, quiet_hours_end, quiet_hours_timezone,
          daily_digest_enabled, digest_time
        ) VALUES (
          $1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11, $12, $13, $14, $15, $16, $17, $18
        )
        ON CONFLICT (user_id) DO UPDATE SET
          push_enabled = EXCLUDED.push_enabled,
          in_app_enabled = EXCLUDED.in_app_enabled,
          email_enabled = EXCLUDED.email_enabled,
          invitations_enabled = EXCLUDED.invitations_enabled,
          messages_enabled = EXCLUDED.messages_enabled,
          updates_enabled = EXCLUDED.updates_enabled,
          announcements_enabled = EXCLUDED.announcements_enabled,
          alerts_enabled = EXCLUDED.alerts_enabled,
          reminders_enabled = EXCLUDED.reminders_enabled,
          sound_enabled = EXCLUDED.sound_enabled,
          vibration_enabled = EXCLUDED.vibration_enabled,
          quiet_hours_enabled = EXCLUDED.quiet_hours_enabled,
          quiet_hours_start = EXCLUDED.quiet_hours_start,
          quiet_hours_end = EXCLUDED.quiet_hours_end,
          quiet_hours_timezone = EXCLUDED.quiet_hours_timezone,
          daily_digest_enabled = EXCLUDED.daily_digest_enabled,
          digest_time = EXCLUDED.digest_time,
          updated_at = CURRENT_TIMESTAMP`,
        [
          userId,
          updated.pushEnabled,
          updated.inAppEnabled,
          updated.emailEnabled,
          updated.invitationsEnabled,
          updated.messagesEnabled,
          updated.updatesEnabled,
          updated.announcementsEnabled,
          updated.alertsEnabled,
          updated.remindersEnabled,
          updated.soundEnabled,
          updated.vibrationEnabled,
          updated.quietHoursEnabled,
          updated.quietHoursStart,
          updated.quietHoursEnd,
          updated.quietHoursTimezone,
          updated.dailyDigestEnabled,
          updated.digestTime,
        ]
      );
    } catch (err) {
      console.warn("DB preferences update failed, using memory:", (err as Error).message);
    }
  }

  memoryPreferences.set(userId, updated);
  return updated;
}

/**
 * Register FCM Device Token for a user.
 */
export async function registerPushToken(
  tokenRecord: PushTokenRecord
): Promise<boolean> {
  if (hasDbConfig && isUuid(tokenRecord.userId) && process.env.NODE_ENV !== "test") {
    try {
      await query(
        `INSERT INTO push_notification_tokens (user_id, device_id, device_type, fcm_token, is_active, last_used_at)
         VALUES ($1, $2, $3, $4, TRUE, CURRENT_TIMESTAMP)
         ON CONFLICT (device_id) DO UPDATE SET
           user_id = EXCLUDED.user_id,
           fcm_token = EXCLUDED.fcm_token,
           is_active = TRUE,
           last_used_at = CURRENT_TIMESTAMP,
           updated_at = CURRENT_TIMESTAMP`,
        [
          tokenRecord.userId,
          tokenRecord.deviceId,
          tokenRecord.deviceType || "android",
          tokenRecord.fcmToken,
        ]
      );
      return true;
    } catch (err) {
      console.warn("Register push token DB error:", (err as Error).message);
    }
  }

  const existingIdx = memoryTokens.findIndex(
    (t) => t.deviceId === tokenRecord.deviceId
  );
  if (existingIdx !== -1) {
    memoryTokens[existingIdx] = { ...tokenRecord, isActive: true };
  } else {
    memoryTokens.push({ ...tokenRecord, isActive: true });
  }
  return true;
}

/**
 * Dispatch a notification across In-App & FCM Push channels.
 */
export async function sendNotification(
  payload: NotificationPayload
): Promise<string> {
  const priority = payload.priority || "medium";
  const prefs = await getPreferences(payload.recipientId);

  // Check global enabled
  if (!prefs.inAppEnabled && !prefs.pushEnabled) {
    console.log(`ℹ️ Notifications disabled for user ${payload.recipientId}`);
    return "";
  }

  // Check category enabled
  const typeStr = payload.type.toString();
  if (
    (typeStr.includes("invitation") && !prefs.invitationsEnabled) ||
    (typeStr.includes("message") && !prefs.messagesEnabled) ||
    (typeStr.includes("update") && !prefs.updatesEnabled) ||
    (typeStr.includes("announcement") && !prefs.announcementsEnabled) ||
    (typeStr.includes("alert") && !prefs.alertsEnabled) ||
    (typeStr.includes("reminder") && !prefs.remindersEnabled)
  ) {
    console.log(`ℹ️ Type ${typeStr} disabled for user ${payload.recipientId}`);
    return "";
  }

  // Check quiet hours unless urgent
  if (isInQuietHours(prefs) && priority !== "urgent") {
    console.log(`🌙 Quiet hours active for user ${payload.recipientId}. Skipping non-urgent alert.`);
    return "";
  }

  const id = `notif-${Date.now()}-${Math.random().toString(36).substring(2, 8)}`;
  const createdAt = new Date();

  // 1. In-app persistence
  if (hasDbConfig && isUuid(payload.recipientId) && process.env.NODE_ENV !== "test" && prefs.inAppEnabled) {
    try {
      await query(
        `INSERT INTO notifications (
          id, recipient_id, sender_id, notification_type, title, message, data,
          recipient_role, is_read, is_deleted, action_url, action_type, priority, event_id
        ) VALUES ($1, $2, $3, $4, $5, $6, $7, $8, FALSE, FALSE, $9, $10, $11, $12)`,
        [
          id,
          payload.recipientId,
          isUuid(payload.senderId) ? payload.senderId : null,
          typeStr,
          payload.title,
          payload.message,
          JSON.stringify(payload.data || {}),
          payload.recipientRole || "organizer",
          payload.actionUrl || null,
          payload.actionType || null,
          priority,
          isUuid(payload.eventId) ? payload.eventId : null,
        ]
      );
    } catch (err) {
      console.warn("In-app notification DB insert failed, using memory:", (err as Error).message);
    }
  }

  memoryNotifications.unshift({
    id,
    recipient_id: payload.recipientId,
    sender_id: payload.senderId || null,
    notification_type: typeStr,
    title: payload.title,
    message: payload.message,
    data: payload.data || {},
    recipient_role: payload.recipientRole || "organizer",
    is_read: false,
    is_deleted: false,
    priority,
    action_url: payload.actionUrl || null,
    action_type: payload.actionType || null,
    event_id: payload.eventId || null,
    created_at: createdAt,
  });

  // 2. Push notification via FCM
  if (prefs.pushEnabled && payload.eventId) {
    sendFcmNotification(payload.eventId, {
      id,
      type: (typeStr.includes("delay") ? "delay" : "announcement") as any,
      message: `${payload.title}: ${payload.message}`,
      createdBy: payload.senderId || "system",
      createdAt: Date.now(),
      priority: (priority === "low" ? "normal" : priority) as any,
    }).catch(() => {});
  }

  return id;
}

/**
 * Query notifications list for recipient with filter, sort & search.
 */
export async function getNotifications(params: {
  recipientId?: string;
  category?: string;
  unreadOnly?: boolean;
  sort?: string;
  search?: string;
  page?: number;
  limit?: number;
}): Promise<{ notifications: DBNotification[]; unreadCount: number }> {
  const { recipientId, category, unreadOnly, sort = "newest", search, page = 1, limit = 50 } = params;

  if (hasDbConfig && isUuid(recipientId) && process.env.NODE_ENV !== "test") {
    try {
      let whereClause = `WHERE recipient_id = $1 AND is_deleted = FALSE`;
      const queryParams: any[] = [recipientId];
      let paramIdx = 2;

      if (category && category !== "all") {
        whereClause += ` AND notification_type LIKE $${paramIdx}`;
        queryParams.push(`%${category}%`);
        paramIdx++;
      }

      if (unreadOnly) {
        whereClause += ` AND is_read = FALSE`;
      }

      if (search && search.trim().length > 0) {
        whereClause += ` AND (title ILIKE $${paramIdx} OR message ILIKE $${paramIdx})`;
        queryParams.push(`%${search.trim()}%`);
        paramIdx++;
      }

      let orderBy = `ORDER BY created_at DESC`;
      if (sort === "oldest") orderBy = `ORDER BY created_at ASC`;
      if (sort === "unread") orderBy = `ORDER BY is_read ASC, created_at DESC`;

      const offset = (page - 1) * limit;
      const sql = `SELECT * FROM notifications ${whereClause} ${orderBy} LIMIT $${paramIdx} OFFSET $${paramIdx + 1}`;
      queryParams.push(limit, offset);

      const rows = await query<any>(sql, queryParams);
      const unreadResult = await query<any>(
        `SELECT COUNT(*) as count FROM notifications WHERE recipient_id = $1 AND is_read = FALSE AND is_deleted = FALSE`,
        [recipientId]
      );
      const unreadCount = Number(unreadResult[0]?.count || 0);

      const mapped = rows.map((r: any) => ({
        id: r.id,
        recipient_id: r.recipient_id,
        sender_id: r.sender_id,
        notification_type: r.notification_type,
        title: r.title,
        message: r.message,
        data: typeof r.data === "string" ? JSON.parse(r.data) : r.data || {},
        recipient_role: r.recipient_role,
        is_read: Boolean(r.is_read),
        is_deleted: Boolean(r.is_deleted),
        read_at: r.read_at,
        action_url: r.action_url,
        action_type: r.action_type,
        priority: r.priority || "medium",
        event_id: r.event_id,
        created_at: r.created_at,
      }));

      return { notifications: mapped, unreadCount };
    } catch (err) {
      console.warn("DB getNotifications query failed, using memory:", (err as Error).message);
    }
  }

  // Memory fallback
  let items = [...memoryNotifications].filter((n) => !n.is_deleted);
  if (recipientId) {
    items = items.filter((n) => n.recipient_id === recipientId || n.recipient_id === "all");
  }
  if (category && category !== "all") {
    items = items.filter((n) => n.notification_type.includes(category));
  }
  if (unreadOnly) {
    items = items.filter((n) => !n.is_read);
  }
  if (search && search.trim().length > 0) {
    const q = search.trim().toLowerCase();
    items = items.filter((n) => n.title.toLowerCase().includes(q) || n.message.toLowerCase().includes(q));
  }

  if (sort === "oldest") {
    items.sort((a, b) => new Date(a.created_at).getTime() - new Date(b.created_at).getTime());
  } else if (sort === "unread") {
    items.sort((a, b) => (a.is_read === b.is_read ? 0 : a.is_read ? 1 : -1));
  } else {
    items.sort((a, b) => new Date(b.created_at).getTime() - new Date(a.created_at).getTime());
  }

  const unreadCount = items.filter((n) => !n.is_read).length;
  return { notifications: items, unreadCount };
}

/**
 * Mark a single notification read.
 */
export async function markNotificationAsRead(id: string): Promise<boolean> {
  if (hasDbConfig && isUuid(id) && process.env.NODE_ENV !== "test") {
    try {
      await query(
        `UPDATE notifications SET is_read = TRUE, read_at = CURRENT_TIMESTAMP WHERE id = $1`,
        [id]
      );
    } catch (_) {}
  }
  const idx = memoryNotifications.findIndex((n) => n.id === id);
  if (idx !== -1) {
    memoryNotifications[idx].is_read = true;
    memoryNotifications[idx].read_at = new Date();
  }
  return true;
}

/**
 * Mark all notifications read for recipient.
 */
export async function markAllAsRead(recipientId: string): Promise<boolean> {
  if (hasDbConfig && isUuid(recipientId) && process.env.NODE_ENV !== "test") {
    try {
      await query(
        `UPDATE notifications SET is_read = TRUE, read_at = CURRENT_TIMESTAMP WHERE recipient_id = $1 AND is_read = FALSE`,
        [recipientId]
      );
    } catch (_) {}
  }
  for (const n of memoryNotifications) {
    if (n.recipient_id === recipientId || recipientId === "all") {
      n.is_read = true;
      n.read_at = new Date();
    }
  }
  return true;
}

/**
 * Delete a notification.
 */
export async function deleteNotification(id: string): Promise<boolean> {
  if (hasDbConfig && isUuid(id) && process.env.NODE_ENV !== "test") {
    try {
      await query(`UPDATE notifications SET is_deleted = TRUE WHERE id = $1`, [id]);
    } catch (_) {}
  }
  const idx = memoryNotifications.findIndex((n) => n.id === id);
  if (idx !== -1) {
    memoryNotifications[idx].is_deleted = true;
  }
  return true;
}
