import { Router, Request, Response } from "express";
import { memoryStore } from "../services/store.js";
import { adminDb } from "../config/firebaseAdmin.js";
import { calculateReflow, handleItemCancellation } from "../services/reflow.js";
import { addMinutesToIso } from "../utils/time.js";
import { sendError, sendSuccess } from "../utils/apiResponse.js";
import {
  CreateEventSchema,
  DelayRequestSchema,
  CancelItemSchema,
  AnnounceSchema,
} from "../services/validation.js";
import { EventData } from "../types/event.js";
import { EventNotification } from "../types/notification.js";
import { sendFcmNotification } from "../services/notifications/fcm.js";

export const eventsRouter = Router();

// GET all events
eventsRouter.get("/", (req: Request, res: Response) => {
  try {
    const events = memoryStore.getEvents();
    return sendSuccess(res, events);
  } catch (err) {
    return sendError(res, (err as Error).message, "SERVER_ERROR", 500);
  }
});

// POST create event
eventsRouter.post("/", (req: Request, res: Response) => {
  try {
    const parsed = CreateEventSchema.safeParse(req.body);
    if (!parsed.success) {
      return sendError(res, parsed.error.errors[0]?.message || "Invalid event data", "VALIDATION_ERROR", 400);
    }

    const { name, type, date, venue, tone, description, joinCode } = parsed.data;
    const eventId = `event-${Date.now()}`;

    const newEvent: EventData = {
      id: eventId,
      name,
      type,
      date,
      venue,
      tone,
      description: description || "",
      ownerId: "user-organizer-1",
      joinCode,
      anchorIds: [],
      liveState: {
        status: "draft",
        currentItemId: null,
        startedAt: null,
        totalDelayMin: 0,
      },
      createdAt: Date.now(),
    };

    memoryStore.createEvent(newEvent);
    return sendSuccess(res, newEvent, 201);
  } catch (err) {
    return sendError(res, (err as Error).message, "SERVER_ERROR", 500);
  }
});

// GET single event
eventsRouter.get("/:id", (req: Request, res: Response) => {
  try {
    const { id } = req.params;
    const event = memoryStore.getEvent(id);
    if (!event) {
      return sendError(res, "Event not found", "NOT_FOUND", 404);
    }
    return sendSuccess(res, event);
  } catch (err) {
    return sendError(res, (err as Error).message, "SERVER_ERROR", 500);
  }
});

// POST start event
eventsRouter.post("/:id/start", async (req: Request, res: Response) => {
  try {
    const { id } = req.params;
    const event = memoryStore.getEvent(id);
    if (!event) {
      return sendError(res, "Event not found", "NOT_FOUND", 404);
    }

    const agenda = memoryStore.getAgenda(id);
    if (agenda.length === 0) {
      return sendError(res, "Cannot start an event with empty agenda", "EMPTY_AGENDA", 400);
    }

    const startTimeIso = new Date().toISOString();
    const firstItem = agenda[0];
    firstItem.status = "live";
    firstItem.startTime = startTimeIso;
    firstItem.endTime = addMinutesToIso(startTimeIso, firstItem.duration);

    const reflow = calculateReflow(agenda, 0, { fromItemId: firstItem.id });

    const updatedLiveState = {
      status: "live" as const,
      currentItemId: firstItem.id,
      startedAt: Date.now(),
      totalDelayMin: 0,
    };

    const notif: EventNotification = {
      id: `notif-${Date.now()}`,
      type: "starting",
      message: `${event.name} is now officially LIVE! Session "${firstItem.title}" has begun.`,
      createdBy: "system",
      createdAt: Date.now(),
      priority: "normal",
    };

    if (adminDb) {
      const batch = adminDb.batch();
      const eventRef = adminDb.collection("events").doc(id);
      batch.update(eventRef, { liveState: updatedLiveState });

      for (const it of reflow.items) {
        const itemRef = eventRef.collection("agenda").doc(it.id);
        batch.set(itemRef, it, { merge: true });
      }

      const notifRef = eventRef.collection("notifications").doc(notif.id);
      batch.set(notifRef, notif);
      await batch.commit();
    }

    memoryStore.updateEvent(id, { liveState: updatedLiveState });
    memoryStore.batchUpdateAgenda(id, reflow.items);
    memoryStore.addNotification(id, notif);

    return sendSuccess(res, {
      event: memoryStore.getEvent(id),
      agenda: reflow.items,
      notification: notif,
    });
  } catch (err) {
    return sendError(res, (err as Error).message, "SERVER_ERROR", 500);
  }
});

// POST delay schedule
eventsRouter.post("/:id/delay", async (req: Request, res: Response) => {
  try {
    const { id } = req.params;
    const parsed = DelayRequestSchema.safeParse(req.body);
    if (!parsed.success) {
      return sendError(res, parsed.error.errors[0]?.message || "Invalid delay request", "VALIDATION_ERROR", 400);
    }

    const { delayMinutes, targetItemId, reason } = parsed.data;
    const event = memoryStore.getEvent(id);
    if (!event) {
      return sendError(res, "Event not found", "NOT_FOUND", 404);
    }

    const agenda = memoryStore.getAgenda(id);
    if (agenda.length === 0) {
      return sendError(res, "Cannot delay an empty agenda", "EMPTY_AGENDA", 400);
    }

    const reflow = calculateReflow(agenda, delayMinutes, {
      fromItemId: targetItemId || event.liveState.currentItemId || undefined,
    });

    const newTotalDelay = (event.liveState.totalDelayMin || 0) + delayMinutes;
    const updatedLiveState = {
      ...event.liveState,
      totalDelayMin: newTotalDelay,
    };

    const absorbedChange = reflow.changes.find((c) => (c.durationChange || 0) < 0);
    let message = delayMinutes > 0
      ? `Schedule adjusted: +${delayMinutes} minutes added.`
      : `Schedule compressed: ${Math.abs(delayMinutes)} minutes pulled forward.`;

    if (absorbedChange) {
      message += ` Break "${absorbedChange.title}" absorbed ${Math.abs(absorbedChange.durationChange!)} min to protect subsequent sessions.`;
    }

    if (reason) {
      message += ` (${reason})`;
    }

    const notif: EventNotification = {
      id: `notif-${Date.now()}`,
      type: "delay",
      message,
      changes: reflow.changes,
      createdBy: "organizer",
      createdAt: Date.now(),
      priority: Math.abs(delayMinutes) >= 15 ? "high" : "normal",
    };

    if (adminDb) {
      const batch = adminDb.batch();
      const eventRef = adminDb.collection("events").doc(id);
      batch.update(eventRef, { liveState: updatedLiveState });

      for (const it of reflow.items) {
        const itemRef = eventRef.collection("agenda").doc(it.id);
        batch.set(itemRef, it, { merge: true });
      }

      const notifRef = eventRef.collection("notifications").doc(notif.id);
      batch.set(notifRef, notif);
      await batch.commit();
    }

    memoryStore.updateEvent(id, { liveState: updatedLiveState });
    memoryStore.batchUpdateAgenda(id, reflow.items);
    memoryStore.addNotification(id, notif);
    sendFcmNotification(id, notif).catch(() => {});

    return sendSuccess(res, {
      reflow,
      notification: notif,
      event: memoryStore.getEvent(id),
    });
  } catch (err) {
    return sendError(res, (err as Error).message, "SERVER_ERROR", 500);
  }
});

// POST complete current session
eventsRouter.post("/:id/complete-current", async (req: Request, res: Response) => {
  try {
    const { id } = req.params;
    const event = memoryStore.getEvent(id);
    if (!event) {
      return sendError(res, "Event not found", "NOT_FOUND", 404);
    }

    const agenda = memoryStore.getAgenda(id);
    const currentId = event.liveState.currentItemId;
    const currentItem = agenda.find((it) => it.id === currentId);

    if (!currentItem) {
      return sendError(res, "No active session to complete", "NO_ACTIVE_SESSION", 400);
    }

    const nowIso = new Date().toISOString();
    currentItem.status = "done";
    currentItem.actualEnd = nowIso;

    // Find next upcoming item
    const nextItem = agenda.find((it) => it.order > currentItem.order && it.status === "upcoming");

    if (nextItem) {
      nextItem.status = "live";
      nextItem.startTime = nowIso;
      nextItem.endTime = addMinutesToIso(nowIso, nextItem.duration);

      const reflow = calculateReflow(agenda, 0, { fromItemId: nextItem.id });
      event.liveState.currentItemId = nextItem.id;
      memoryStore.batchUpdateAgenda(id, reflow.items);
    } else {
      event.liveState.currentItemId = null;
      event.liveState.status = "completed";
      memoryStore.updateAgendaItem(id, currentItem.id, currentItem);
    }

    const notif: EventNotification = {
      id: `notif-${Date.now()}`,
      type: "change",
      message: nextItem
        ? `Session "${currentItem.title}" completed. Now live: "${nextItem.title}".`
        : `Final session "${currentItem.title}" completed. Event finished!`,
      createdBy: "organizer",
      createdAt: Date.now(),
      priority: "normal",
    };

    memoryStore.updateEvent(id, { liveState: event.liveState });
    memoryStore.addNotification(id, notif);

    return sendSuccess(res, {
      event: memoryStore.getEvent(id),
      agenda: memoryStore.getAgenda(id),
      notification: notif,
    });
  } catch (err) {
    return sendError(res, (err as Error).message, "SERVER_ERROR", 500);
  }
});

// POST cancel item
eventsRouter.post("/:id/cancel-item", async (req: Request, res: Response) => {
  try {
    const { id } = req.params;
    const parsed = CancelItemSchema.safeParse(req.body);
    if (!parsed.success) {
      return sendError(res, parsed.error.errors[0]?.message || "Invalid cancel request", "VALIDATION_ERROR", 400);
    }

    const { itemId } = parsed.data;
    const event = memoryStore.getEvent(id);
    if (!event) return sendError(res, "Event not found", "NOT_FOUND", 404);

    const agenda = memoryStore.getAgenda(id);
    const target = agenda.find((it) => it.id === itemId);
    if (!target) return sendError(res, "Agenda item not found", "NOT_FOUND", 404);

    const reflow = handleItemCancellation(agenda, itemId);
    memoryStore.batchUpdateAgenda(id, reflow.items);

    const notif: EventNotification = {
      id: `notif-${Date.now()}`,
      type: "cancel",
      message: `Session "${target.title}" was cancelled. Schedule was compressed forward.`,
      createdBy: "organizer",
      createdAt: Date.now(),
      priority: "high",
    };
    memoryStore.addNotification(id, notif);

    return sendSuccess(res, {
      reflow,
      notification: notif,
      event: memoryStore.getEvent(id),
    });
  } catch (err) {
    return sendError(res, (err as Error).message, "SERVER_ERROR", 500);
  }
});

// POST announce
eventsRouter.post("/:id/announce", async (req: Request, res: Response) => {
  try {
    const { id } = req.params;
    const parsed = AnnounceSchema.safeParse(req.body);
    if (!parsed.success) {
      return sendError(res, parsed.error.errors[0]?.message || "Invalid announcement", "VALIDATION_ERROR", 400);
    }

    const { message, priority } = parsed.data;
    const event = memoryStore.getEvent(id);
    if (!event) return sendError(res, "Event not found", "NOT_FOUND", 404);

    const notif: EventNotification = {
      id: `notif-${Date.now()}`,
      type: "announcement",
      message,
      createdBy: "organizer",
      createdAt: Date.now(),
      priority,
    };

    memoryStore.addNotification(id, notif);
    sendFcmNotification(id, notif).catch(() => {});
    return sendSuccess(res, notif, 201);
  } catch (err) {
    return sendError(res, (err as Error).message, "SERVER_ERROR", 500);
  }
});

// GET notifications
eventsRouter.get("/:id/notifications", (req: Request, res: Response) => {
  try {
    const { id } = req.params;
    const notifications = memoryStore.getNotifications(id);
    return sendSuccess(res, notifications);
  } catch (err) {
    return sendError(res, (err as Error).message, "SERVER_ERROR", 500);
  }
});
