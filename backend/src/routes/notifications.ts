import { Router, Request, Response } from "express";
import { sendFcmNotification } from "../services/notifications/fcm.js";
import {
  sendNotification,
  getNotifications,
  markNotificationAsRead,
  markAllAsRead,
  deleteNotification,
  getPreferences,
  updatePreferences,
  registerPushToken,
} from "../services/notifications/notificationService.js";
import { NotificationType } from "../types/notification_system.js";
import { sendError, sendSuccess } from "../utils/apiResponse.js";

export interface MessageAttachment {
  id: string;
  type: "image" | "document";
  url: string;
  name: string;
  sizeBytes: number;
  createdAt: number;
}

export interface MessageBubble {
  id: string;
  senderId: string;
  senderName: string;
  text: string;
  createdAt: number;
  attachments: MessageAttachment[];
  isOwn: boolean;
}

export interface QuickAction {
  label: string;
  action: string;
  icon?: string;
}

export type NotificationCategory =
  | "invitation"
  | "update"
  | "announcement"
  | "message"
  | "alert"
  | "smart_eve_ai";

export interface AnchorNotification {
  id: string;
  category: NotificationCategory;
  title: string;
  message: string;
  detailedText?: string;
  type: string;
  createdBy: string;
  senderName?: string;
  senderAvatarUrl?: string;
  senderRole?: "organizer" | "admin" | "system";
  senderStatus?: "online" | "offline" | "away";
  eventId?: string;
  eventName?: string;
  attachments?: MessageAttachment[];
  replyCount?: number;
  thread?: MessageBubble[];
  quickActions?: QuickAction[];
  createdAt: number;
  read: boolean;
  priority: "normal" | "high" | "urgent";
}

const now = Date.now();

const anchorNotifications: AnchorNotification[] = [
  {
    id: "nt-1",
    category: "invitation",
    title: "New Invitation",
    message: "You've been invited to TechNova Live Summit 2026 by Alex Rivera",
    detailedText:
      "Alex Rivera from Stanford Engineering Concourse has invited you to anchor the morning keynotes at the TechNova Live Summit 2026. Event date: September 20, 2026, 09:30 AM.",
    type: "anchor_invitation",
    createdBy: "user-organizer-1",
    senderName: "Alex Rivera",
    senderAvatarUrl:
      "https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=100&h=100&fit=crop",
    senderRole: "organizer",
    senderStatus: "online",
    eventId: "technova-2026",
    eventName: "TechNova Live Summit 2026",
    createdAt: now - 1000 * 60 * 2,
    read: false,
    priority: "high",
    quickActions: [
      { label: "Accept", action: "accept" },
      { label: "Decline", action: "decline" },
    ],
  },
  {
    id: "nt-2",
    category: "update",
    title: "Script Updated",
    message:
      "Opening script for TechNova Live Summit 2026 has been updated by the organizer",
    detailedText:
      "Alex Rivera revised the opening script for the TechNova Live Summit 2026. The new version adds a welcome note for the VIP guests.",
    type: "scripts_updated",
    createdBy: "user-organizer-1",
    senderName: "Alex Rivera",
    senderRole: "organizer",
    senderStatus: "offline",
    eventId: "technova-2026",
    eventName: "TechNova Live Summit 2026",
    createdAt: now - 1000 * 60 * 35,
    read: true,
    priority: "normal",
    quickActions: [{ label: "View Updated Script", action: "view_script" }],
  },
  {
    id: "nt-3",
    category: "update",
    title: "Agenda Updated",
    message:
      "Agenda for TechNova Live Summit 2026 has been updated — Keynote moved to 10:15 AM",
    detailedText:
      "The keynote session has been rescheduled from 09:45 AM to 10:15 AM to accommodate a late-arriving speaker.",
    type: "agenda_updated",
    createdBy: "user-organizer-1",
    senderName: "Alex Rivera",
    senderRole: "organizer",
    senderStatus: "offline",
    eventId: "technova-2026",
    eventName: "TechNova Live Summit 2026",
    createdAt: now - 1000 * 60 * 120,
    read: true,
    priority: "normal",
    quickActions: [{ label: "Review New Agenda", action: "view_agenda" }],
  },
  {
    id: "nt-4",
    category: "alert",
    title: "Session Delayed",
    message: "Keynote session has been delayed by 8 minutes",
    detailedText:
      "The keynote 'Autonomous Agents in High-Stakes Operations' by Dr. Aris Vance is running 8 minutes behind schedule.",
    type: "event_delay",
    createdBy: "user-organizer-1",
    senderName: "Alex Rivera",
    senderRole: "organizer",
    senderStatus: "online",
    eventId: "technova-2026",
    eventName: "TechNova Live Summit 2026",
    createdAt: now - 1000 * 60 * 5,
    read: false,
    priority: "urgent",
    quickActions: [
      { label: "Acknowledge", action: "acknowledge" },
      { label: "Remind me later", action: "snooze" },
    ],
  },
  {
    id: "nt-5",
    category: "message",
    title: "Message from Alex Rivera",
    message: 'Alex: "The stage lights just changed — can you confirm the cue?"',
    detailedText:
      "Alex Rivera sent you a direct message about the stage lighting cue.",
    type: "direct_message",
    createdBy: "user-organizer-1",
    senderName: "Alex Rivera",
    senderAvatarUrl:
      "https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=100&h=100&fit=crop",
    senderRole: "organizer",
    senderStatus: "online",
    eventId: "technova-2026",
    eventName: "TechNova Live Summit 2026",
    createdAt: now - 1000 * 60 * 8,
    read: false,
    priority: "normal",
    replyCount: 2,
    thread: [
      {
        id: "msg-1",
        senderId: "user-organizer-1",
        senderName: "Alex Rivera",
        text: "The stage lights just changed — can you confirm the cue?",
        createdAt: now - 1000 * 60 * 8,
        attachments: [],
        isOwn: false,
      },
      {
        id: "msg-2",
        senderId: "anchor",
        senderName: "You",
        text: "Confirmed — lights are set to warm white for the keynote.",
        createdAt: now - 1000 * 60 * 7,
        attachments: [],
        isOwn: true,
      },
    ],
    quickActions: [],
  },
  {
    id: "nt-6",
    category: "alert",
    title: "Event Goes Live Soon",
    message: "TechNova Live Summit 2026 goes live in 15 minutes",
    detailedText: "Final checklist: Scripts ready? Audio/Video working? Anchor status check!",
    type: "event_reminder",
    createdBy: "system",
    senderName: "SmartEve",
    senderRole: "system",
    senderStatus: "online",
    eventId: "technova-2026",
    eventName: "TechNova Live Summit 2026",
    createdAt: now - 1000 * 60 * 15,
    read: false,
    priority: "urgent",
    quickActions: [
      { label: "Got it", action: "dismiss" },
      { label: "Remind me later", action: "snooze" },
    ],
  },
  {
    id: "nt-7",
    category: "smart_eve_ai",
    title: "SmartEve AI Ready",
    message: "SmartEve AI has prepared suggestions for your scripts",
    detailedText:
      "SmartEve AI has generated suggested intros and transitions for today's sessions.",
    type: "scripts_generated",
    createdBy: "ai",
    senderName: "SmartEve AI",
    senderAvatarUrl:
      "https://images.unsplash.com/photo-1677442136019-21780ecad995?w=100&h=100&fit=crop",
    senderRole: "system",
    senderStatus: "online",
    createdAt: now - 1000 * 60 * 90,
    read: true,
    priority: "normal",
    quickActions: [{ label: "View Suggestions", action: "view_suggestions" }],
  },
];

export const notificationsRouter = Router();

// ---------------------------------------------------------------------------
// 1. GET /api/notifications or /api/anchor/notifications
// ---------------------------------------------------------------------------
notificationsRouter.get("/", async (req: Request, res: Response) => {
  try {
    const filter = (req.query.filter as string) ?? "all";
    const sort = (req.query.sort as string) ?? "newest";
    const search = req.query.search as string;
    const recipientId = (req.query.recipientId as string) || (req.query.userId as string);
    const unreadOnly = req.query.unreadOnly === "true";

    const { notifications: dbItems, unreadCount } = await getNotifications({
      recipientId,
      category: filter,
      unreadOnly,
      sort,
      search,
    });

    // Merge in-memory anchor notifications for demo consistency
    let combined = [...anchorNotifications];
    if (filter !== "all") {
      combined = combined.filter((n) => n.category === filter || n.type.includes(filter));
    }
    if (unreadOnly) {
      combined = combined.filter((n) => !n.read);
    }
    if (search) {
      const q = search.toLowerCase();
      combined = combined.filter((n) => n.title.toLowerCase().includes(q) || n.message.toLowerCase().includes(q));
    }

    const mappedDb = dbItems.map((n) => ({
      id: n.id,
      category: (n.notification_type.includes("invitation")
        ? "invitation"
        : n.notification_type.includes("message")
        ? "message"
        : n.notification_type.includes("delay") || n.priority === "urgent"
        ? "alert"
        : n.notification_type.includes("script")
        ? "update"
        : "announcement") as NotificationCategory,
      title: n.title,
      message: n.message,
      detailedText: n.message,
      type: n.notification_type,
      createdBy: n.sender_id || "system",
      senderName: n.sender_id ? "Organizer" : "SmartEve System",
      senderRole: n.recipient_role === "anchor" ? "organizer" : "system",
      senderStatus: "online",
      eventId: n.event_id || "technova-2026",
      eventName: "TechNova Live Summit 2026",
      createdAt: new Date(n.created_at).getTime(),
      read: n.is_read,
      priority: n.priority || "normal",
      quickActions: n.notification_type.includes("invitation")
        ? [
            { label: "Accept", action: "accept" },
            { label: "Decline", action: "decline" },
          ]
        : n.priority === "urgent"
        ? [{ label: "Acknowledge", action: "acknowledge" }]
        : [{ label: "View", action: "view" }],
    }));

    const finalNotifications = [...mappedDb, ...combined];
    if (sort === "oldest") {
      finalNotifications.sort((a, b) => a.createdAt - b.createdAt);
    } else if (sort === "unread") {
      finalNotifications.sort((a, b) => (a.read === b.read ? 0 : a.read ? 1 : -1));
    } else {
      finalNotifications.sort((a, b) => b.createdAt - a.createdAt);
    }

    const totalUnread = finalNotifications.filter((n) => !n.read).length;

    return sendSuccess(res, {
      notifications: finalNotifications,
      unreadCount: totalUnread,
    });
  } catch (err) {
    return sendError(res, (err as Error).message, "SERVER_ERROR", 500);
  }
});

// ---------------------------------------------------------------------------
// 2. POST /api/notifications  (Dispatch Notification)
// ---------------------------------------------------------------------------
notificationsRouter.post("/", async (req: Request, res: Response) => {
  try {
    const { recipientId, senderId, type, title, message, data, priority, eventId, actionUrl } = req.body;

    if (!recipientId || !title || !message) {
      return sendError(res, "recipientId, title and message are required", "VALIDATION_ERROR", 400);
    }

    const notificationId = await sendNotification({
      recipientId,
      senderId,
      type: type || NotificationType.ANNOUNCEMENT,
      title,
      message,
      data,
      priority: priority || "medium",
      eventId,
      actionUrl,
    });

    return sendSuccess(res, { success: true, notificationId }, 201);
  } catch (err) {
    return sendError(res, (err as Error).message, "SERVER_ERROR", 500);
  }
});

// ---------------------------------------------------------------------------
// 3. GET /api/notifications/:id
// ---------------------------------------------------------------------------
notificationsRouter.get("/:id", (req: Request, res: Response) => {
  try {
    const notif = anchorNotifications.find((n) => n.id === req.params.id);
    if (!notif) {
      return sendError(res, "Notification not found", "NOT_FOUND", 404);
    }
    return sendSuccess(res, {
      ...notif,
      thread: notif.thread ?? [],
    });
  } catch (err) {
    return sendError(res, (err as Error).message, "SERVER_ERROR", 500);
  }
});

// ---------------------------------------------------------------------------
// 4. POST /api/notifications/:id/read
// ---------------------------------------------------------------------------
notificationsRouter.post("/:id/read", async (req: Request, res: Response) => {
  try {
    const { id } = req.params;
    await markNotificationAsRead(id);

    const idx = anchorNotifications.findIndex((n) => n.id === id);
    if (idx !== -1) {
      anchorNotifications[idx].read = true;
    }

    return sendSuccess(res, { success: true });
  } catch (err) {
    return sendError(res, (err as Error).message, "SERVER_ERROR", 500);
  }
});

// ---------------------------------------------------------------------------
// 5. POST /api/notifications/mark-all-read
// ---------------------------------------------------------------------------
notificationsRouter.post("/mark-all-read", async (req: Request, res: Response) => {
  try {
    const recipientId = (req.body.recipientId as string) || "user-anchor-1";
    await markAllAsRead(recipientId);

    for (const n of anchorNotifications) {
      n.read = true;
    }
    return sendSuccess(res, { success: true });
  } catch (err) {
    return sendError(res, (err as Error).message, "SERVER_ERROR", 500);
  }
});

// ---------------------------------------------------------------------------
// 6. DELETE /api/notifications/:id
// ---------------------------------------------------------------------------
notificationsRouter.delete("/:id", async (req: Request, res: Response) => {
  try {
    const { id } = req.params;
    await deleteNotification(id);
    const idx = anchorNotifications.findIndex((n) => n.id === id);
    if (idx !== -1) {
      anchorNotifications.splice(idx, 1);
    }
    return sendSuccess(res, { success: true });
  } catch (err) {
    return sendError(res, (err as Error).message, "SERVER_ERROR", 500);
  }
});

// ---------------------------------------------------------------------------
// 7. GET /api/notifications/preferences/:userId
// ---------------------------------------------------------------------------
notificationsRouter.get("/preferences/:userId", async (req: Request, res: Response) => {
  try {
    const prefs = await getPreferences(req.params.userId);
    return sendSuccess(res, prefs);
  } catch (err) {
    return sendError(res, (err as Error).message, "SERVER_ERROR", 500);
  }
});

// ---------------------------------------------------------------------------
// 8. PUT /api/notifications/preferences/:userId
// ---------------------------------------------------------------------------
notificationsRouter.put("/preferences/:userId", async (req: Request, res: Response) => {
  try {
    const updated = await updatePreferences(req.params.userId, req.body);
    return sendSuccess(res, updated);
  } catch (err) {
    return sendError(res, (err as Error).message, "SERVER_ERROR", 500);
  }
});

// ---------------------------------------------------------------------------
// 9. POST /api/notifications/tokens (Register FCM Device Token)
// ---------------------------------------------------------------------------
notificationsRouter.post("/tokens", async (req: Request, res: Response) => {
  try {
    const { userId, deviceId, deviceType, fcmToken } = req.body;
    if (!userId || !deviceId || !fcmToken) {
      return sendError(res, "userId, deviceId, and fcmToken are required", "VALIDATION_ERROR", 400);
    }

    await registerPushToken({
      userId,
      deviceId,
      deviceType: deviceType || "android",
      fcmToken,
      isActive: true,
    });

    return sendSuccess(res, { success: true });
  } catch (err) {
    return sendError(res, (err as Error).message, "SERVER_ERROR", 500);
  }
});

// ---------------------------------------------------------------------------
// 10. POST /api/notifications/test-trigger  (Test fire any of the 25 triggers)
// ---------------------------------------------------------------------------
notificationsRouter.post("/test-trigger", async (req: Request, res: Response) => {
  try {
    const { type, recipientId, eventId, customTitle, customMessage } = req.body;
    const targetType = type || NotificationType.ANCHOR_INVITATION;
    const targetRecipient = recipientId || "user-anchor-1";

    const title = customTitle || `Test Alert: ${targetType}`;
    const message = customMessage || `This is a test notification for type ${targetType}.`;

    const id = await sendNotification({
      recipientId: targetRecipient,
      senderId: "user-organizer-1",
      type: targetType,
      title,
      message,
      eventId: eventId || "technova-2026",
      priority: targetType === NotificationType.EMERGENCY_SOS ? "urgent" : "medium",
    });

    return sendSuccess(res, { success: true, notificationId: id, type: targetType });
  } catch (err) {
    return sendError(res, (err as Error).message, "SERVER_ERROR", 500);
  }
});

// ---------------------------------------------------------------------------
// POST /api/anchor/notifications/:id/reply
// ---------------------------------------------------------------------------
notificationsRouter.post("/:id/reply", (req: Request, res: Response) => {
  try {
    const { replyText } = req.body as { replyText?: string };
    const notif = anchorNotifications.find((n) => n.id === req.params.id);
    if (!notif) {
      return sendError(res, "Notification not found", "NOT_FOUND", 404);
    }
    if (!replyText || replyText.trim().length === 0) {
      return sendError(res, "Reply text is required", "VALIDATION_ERROR", 400);
    }

    const bubble: MessageBubble = {
      id: `msg-${Date.now()}-${Math.random().toString(36).slice(2, 8)}`,
      senderId: "anchor",
      senderName: "You",
      text: replyText.trim(),
      createdAt: Date.now(),
      attachments: [],
      isOwn: true,
    };

    if (!notif.thread) notif.thread = [];
    notif.thread.push(bubble);
    notif.replyCount = (notif.replyCount ?? 0) + 1;
    notif.read = true;

    sendFcmNotification(notif.eventId ?? "global", {
      id: `reply-${Date.now()}`,
      type: "announcement",
      message: `You have a reply from ${bubble.senderName} on: ${notif.title}`,
      createdBy: "anchor",
      createdAt: Date.now(),
      priority: "normal" as const,
    }).catch(() => {});

    return sendSuccess(res, { success: true, message: bubble });
  } catch (err) {
    return sendError(res, (err as Error).message, "SERVER_ERROR", 500);
  }
});
