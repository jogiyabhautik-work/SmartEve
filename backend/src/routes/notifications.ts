import { Router, Request, Response } from "express";
import { sendFcmNotification } from "../services/notifications/fcm.js";
import { sendError, sendSuccess } from "../utils/apiResponse.js";

// =============================================================================
// In-memory notification center store (anchor-facing global notifications,
// direct messages, and announcement alerts). In production this would live
// in a notifications table; the demo keeps it in memory.
// =============================================================================

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
    message:
      "You've been invited to TechNova Live Summit 2026 by Alex Rivera",
    detailedText:
      "Alex Rivera from Stanford Engineering Concourse has invited you to anchor the morning keynotes at the TechNova Live Summit 2026. Event date: September 20, 2026, 09:30 AM.",
    type: "invitation",
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
      "Alex Rivera revised the opening script for the TechNova Live Summit 2026. The new version adds a welcome note for the VIP guests. Review the updated script before the event.",
    type: "change",
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
      "The keynote session has been rescheduled from 09:45 AM to 10:15 AM to accommodate a late-arriving speaker. The tea break has been shortened to 20 minutes. Please review the new agenda flow.",
    type: "change",
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
      "The keynote 'Autonomous Agents in High-Stakes Operations' by Dr. Aris Vance is running 8 minutes behind schedule. The delay will be absorbed in the tea break. Please acknowledge so the organizer can adjust the downstream agenda.",
    type: "delay",
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
      "Alex Rivera sent you a direct message about the stage lighting cue. Reply to coordinate the next cue.",
    type: "announcement",
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
        text: "Confirmed — lights are set to warm white for the keynote. Ready for the cue.",
        createdAt: now - 1000 * 60 * 7,
        attachments: [],
        isOwn: true,
      },
      {
        id: "msg-3",
        senderId: "user-organizer-1",
        senderName: "Alex Rivera",
        text: "Perfect, thanks. I'll cue you at 09:28.",
        createdAt: now - 1000 * 60 * 6,
        attachments: [],
        isOwn: false,
      },
    ],
    quickActions: [],
  },
  {
    id: "nt-6",
    category: "alert",
    title: "Event Goes Live Soon",
    message: "TechNova Live Summit 2026 goes live in 30 minutes",
    detailedText:
      "The TechNova Live Summit 2026 starts in 30 minutes. Please review your scripts and confirm your readiness with the organizer.",
    type: "starting",
    createdBy: "system",
    senderName: "SmartEve",
    senderRole: "system",
    senderStatus: "online",
    eventId: "technova-2026",
    eventName: "TechNova Live Summit 2026",
    createdAt: now - 1000 * 60 * 30,
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
      "SmartEve AI has generated suggested intros and transitions for today's sessions based on the latest speaker bios. Review and approve before the event.",
    type: "announcement",
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
  {
    id: "nt-8",
    category: "announcement",
    title: "Announcement from Organizer",
    message:
      'Alex Rivera: "Welcome to the TechNova Live Summit! We have a special guest speaker joining us for the panel."',
    detailedText:
      "Alex Rivera announced a special guest speaker joining the executive panel. Please stay tuned for updates.",
    type: "announcement",
    createdBy: "user-organizer-1",
    senderName: "Alex Rivera",
    senderAvatarUrl:
      "https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=100&h=100&fit=crop",
    senderRole: "organizer",
    senderStatus: "offline",
    eventId: "technova-2026",
    eventName: "TechNova Live Summit 2026",
    createdAt: now - 1000 * 60 * 180,
    read: true,
    priority: "normal",
    quickActions: [],
  },
];

export const notificationsRouter = Router();

// ---------------------------------------------------------------------------
// GET /api/anchor/notifications?filter=all&sort=newest&since=<ts>
// ---------------------------------------------------------------------------
notificationsRouter.get("/", (req: Request, res: Response) => {
  try {
    const filter =
      (req.query.filter as string) ?? "all";
    const sort = (req.query.sort as string) ?? "newest";
    const since = req.query.since ? Number(req.query.since) : undefined;

    let items = [...anchorNotifications];

    if (filter !== "all") {
      items = items.filter((n) => n.category === filter);
    }

    if (since && isFinite(since)) {
      items = items.filter((n) => n.createdAt >= since);
    }

    if (sort === "newest") {
      items.sort((a, b) => b.createdAt - a.createdAt);
    } else if (sort === "oldest") {
      items.sort((a, b) => a.createdAt - b.createdAt);
    } else if (sort === "unread") {
      items.sort((a, b) => {
        const ra = a.read ? 0 : 1;
        const rb = b.read ? 0 : 1;
        if (ra !== rb) return rb - ra;
        return b.createdAt - a.createdAt;
      });
    } else {
      items.sort((a, b) => b.createdAt - a.createdAt);
    }

    const unreadCount = anchorNotifications.filter((n) => !n.read).length;

    return sendSuccess(res, {
      notifications: items,
      unreadCount,
    });
  } catch (err) {
    return sendError(
      res,
      (err as Error).message,
      "SERVER_ERROR",
      500
    );
  }
});

// ---------------------------------------------------------------------------
// GET /api/anchor/notifications/:id
// ---------------------------------------------------------------------------
notificationsRouter.get("/:id", (req: Request, res: Response) => {
  try {
    const notif = anchorNotifications.find(
      (n) => n.id === req.params.id
    );
    if (!notif) {
      return sendError(res, "Notification not found", "NOT_FOUND", 404);
    }
    return sendSuccess(res, {
      ...notif,
      thread: notif.thread ?? [],
    });
  } catch (err) {
    return sendError(
      res,
      (err as Error).message,
      "SERVER_ERROR",
      500
    );
  }
});

// ---------------------------------------------------------------------------
// POST /api/anchor/notifications/:id/read
// ---------------------------------------------------------------------------
notificationsRouter.post("/:id/read", (req: Request, res: Response) => {
  try {
    const idx = anchorNotifications.findIndex(
      (n) => n.id === req.params.id
    );
    if (idx === -1) {
      return sendError(res, "Notification not found", "NOT_FOUND", 404);
    }
    anchorNotifications[idx].read = true;
    return sendSuccess(res, { success: true });
  } catch (err) {
    return sendError(
      res,
      (err as Error).message,
      "SERVER_ERROR",
      500
    );
  }
});

// ---------------------------------------------------------------------------
// POST /api/anchor/notifications/mark-all-read
// ---------------------------------------------------------------------------
notificationsRouter.post("/mark-all-read", (req: Request, res: Response) => {
  try {
    for (const n of anchorNotifications) {
      n.read = true;
    }
    return sendSuccess(res, { success: true });
  } catch (err) {
    return sendError(
      res,
      (err as Error).message,
      "SERVER_ERROR",
      500
    );
  }
});

// ---------------------------------------------------------------------------
// POST /api/anchor/notifications/:id/reply
// ---------------------------------------------------------------------------
notificationsRouter.post("/:id/reply", (req: Request, res: Response) => {
  try {
    const { replyText } = req.body as { replyText?: string };
    const notif = anchorNotifications.find(
      (n) => n.id === req.params.id
    );
    if (!notif) {
      return sendError(res, "Notification not found", "NOT_FOUND", 404);
    }
    if (!replyText || replyText.trim().length === 0) {
      return sendError(
        res,
        "Reply text is required",
        "VALIDATION_ERROR",
        400
      );
    }

    const bubble: MessageBubble = {
      id:
        `msg-${Date.now()}-${Math.random()
          .toString(36)
          .slice(2, 8)}`,
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
    return sendError(
      res,
      (err as Error).message,
      "SERVER_ERROR",
      500
    );
  }
});

// ---------------------------------------------------------------------------
// POST /api/anchor/notifications/broadcast  (admin -> all anchors)
// ---------------------------------------------------------------------------
notificationsRouter.post("/broadcast", (req: Request, res: Response) => {
  try {
    const body = req.body as {
      title?: string;
      message?: string;
      priority?: string;
      type?: string;
    };

    const title = body.title ?? "SmartEve Alert";
    const message = body.message ?? "";
    const priority = (body.priority ?? "normal") as
      | "normal"
      | "high"
      | "urgent";

    const notif: AnchorNotification = {
      id: `alert-${Date.now()}-${Math.random()
        .toString(36)
        .slice(2, 8)}`,
      category: "alert",
      title,
      message,
      type: body.type ?? "announcement",
      createdBy: "admin",
      senderName: "SmartEve Admin",
      senderRole: "admin",
      senderStatus: "online",
      createdAt: Date.now(),
      read: false,
      priority,
      quickActions: [
        { label: "Got it", action: "dismiss" },
        ...(priority === "urgent"
          ? [{ label: "Remind me later", action: "snooze" }]
          : []),
      ],
    };

    anchorNotifications.unshift(notif);

    sendFcmNotification(notif.eventId ?? "global", {
      id: notif.id,
      type: "announcement",
      message: `${title}: ${message}`,
      createdBy: "admin",
      createdAt: notif.createdAt,
      priority,
    }).catch(() => {});

    return sendSuccess(res, { success: true, notification: notif }, 201);
  } catch (err) {
    return sendError(
      res,
      (err as Error).message,
      "SERVER_ERROR",
      500
    );
  }
});
