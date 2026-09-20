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
import { dbPool, query } from "../config/db.js";

export const eventsRouter = Router();

// GET all events
eventsRouter.get("/", async (req: Request, res: Response) => {
  try {
    if (dbPool) {
      try {
        const rows = await query<any>(
          `SELECT e.*, u.full_name as organizer_name, u.phone as organizer_phone, u.email as organizer_email
           FROM events e
           LEFT JOIN users u ON e.created_by = u.id
           WHERE e.deleted_at IS NULL
           ORDER BY e.start_date ASC`
        );
        if (rows && rows.length > 0) {
          const mappedList: EventData[] = rows.map((ev: any) => ({
            id: ev.id,
            name: ev.title,
            type: ev.event_type || "Conference",
            date: ev.start_date ? new Date(ev.start_date).toISOString().split("T")[0] : "2026-09-20",
            venue: ev.location || "Main Stage & Auditorium",
            tone: "Visionary & Polished",
            description: ev.description || "",
            ownerId: ev.created_by || "user-organizer-1",
            joinCode: (ev.title ? ev.title.replace(/[^a-zA-Z]/g, "").substring(0, 2).toUpperCase() : "EV") + "26",
            anchorIds: [],
            liveState: {
              status: ev.status === "live" ? "live" : "draft",
              currentItemId: null,
              startedAt: ev.start_date ? new Date(ev.start_date).getTime() : null,
              totalDelayMin: 0,
            },
            createdAt: new Date(ev.created_at || Date.now()).getTime(),
          }));
          return sendSuccess(res, mappedList);
        }
      } catch (dbErr) {
        console.warn("⚠️ [Neon DB] GET /events error, falling back to memory:", (dbErr as Error).message);
      }
    }

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
eventsRouter.get("/:id", async (req: Request, res: Response) => {
  try {
    const { id } = req.params;

    if (dbPool) {
      try {
        const rows = await query<any>(
          `SELECT e.*, u.full_name as organizer_name, u.phone as organizer_phone, u.email as organizer_email
           FROM events e
           LEFT JOIN users u ON e.created_by = u.id
           WHERE e.id = $1::uuid AND e.deleted_at IS NULL`,
          [id]
        );
        if (rows && rows.length > 0) {
          const ev = rows[0];
          const mapped: EventData = {
            id: ev.id,
            name: ev.title,
            type: ev.event_type || "Conference",
            date: ev.start_date ? new Date(ev.start_date).toISOString().split("T")[0] : "2026-09-20",
            venue: ev.location || "Main Stage & Auditorium",
            tone: "Visionary & Polished",
            description: ev.description || "",
            ownerId: ev.created_by || "user-organizer-1",
            joinCode: (ev.title ? ev.title.replace(/[^a-zA-Z]/g, "").substring(0, 2).toUpperCase() : "EV") + "26",
            anchorIds: [],
            liveState: {
              status: ev.status === "live" ? "live" : "draft",
              currentItemId: null,
              startedAt: ev.start_date ? new Date(ev.start_date).getTime() : null,
              totalDelayMin: 0,
            },
            createdAt: new Date(ev.created_at || Date.now()).getTime(),
          };
          return sendSuccess(res, mapped);
        }
      } catch (_) {}
    }

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
    let event = memoryStore.getEvent(id);

    // If not found in memoryStore, check Neon DB
    if (!event && dbPool) {
      try {
        const rows = await query<any>(`SELECT * FROM events WHERE id = $1::uuid AND deleted_at IS NULL`, [id]);
        if (rows.length > 0) {
          event = {
            id: rows[0].id,
            name: rows[0].title,
            type: rows[0].event_type || "Conference",
            date: rows[0].start_date ? new Date(rows[0].start_date).toISOString().split("T")[0] : "2026-09-20",
            venue: rows[0].location || "Main Stage",
            tone: "Visionary & Polished",
            description: rows[0].description || "",
            ownerId: rows[0].created_by || "organizer",
            joinCode: "TN26",
            anchorIds: [],
            liveState: {
              status: rows[0].status === "live" ? "live" : "draft",
              currentItemId: null,
              startedAt: rows[0].start_date ? new Date(rows[0].start_date).getTime() : null,
              totalDelayMin: 0,
            },
            createdAt: Date.now(),
          };
          memoryStore.createEvent(event);
        }
      } catch (_) {}
    }

    if (!event) {
      return sendError(res, "Event not found", "NOT_FOUND", 404);
    }

    // Persist delay to Neon PostgreSQL if available
    if (dbPool) {
      try {
        if (targetItemId) {
          await query(
            `UPDATE agenda_items 
             SET duration_minutes = duration_minutes + $1,
                 status = 'delayed'
             WHERE (id = $2::uuid OR id = $2) AND event_id = $3::uuid`,
            [delayMinutes, targetItemId, id]
          );
        }

        const orgRows = await query<any>(`SELECT created_by FROM events WHERE id = $1::uuid`, [id]);
        const orgId = orgRows[0]?.created_by;
        if (orgId) {
          await query(
            `INSERT INTO event_timeline_updates (event_id, agenda_item_id, delay_minutes, reason, updated_by, status, is_applied, applied_at)
             VALUES ($1::uuid, $2, $3, $4, $5::uuid, 'approved', true, CURRENT_TIMESTAMP)`,
            [id, targetItemId ? targetItemId : null, delayMinutes, reason || "Schedule delay adjustment", orgId]
          );
        }
      } catch (neonErr) {
        console.warn("⚠️ [Neon DB] Delay persistence warning:", (neonErr as Error).message);
      }
    }

    const agenda = memoryStore.getAgenda(id);
    if (agenda.length === 0) {
      return sendSuccess(res, {
        reflow: { items: [], changes: [] },
        notification: {
          id: `notif-${Date.now()}`,
          type: "delay",
          message: `Schedule adjusted: +${delayMinutes} minutes added.`,
          createdBy: "organizer",
          createdAt: Date.now(),
          priority: "normal",
        },
        event,
      });
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
    let event = memoryStore.getEvent(id);

    if (!event && dbPool) {
      try {
        const rows = await query<any>(`SELECT * FROM events WHERE id = $1::uuid AND deleted_at IS NULL`, [id]);
        if (rows.length > 0) {
          event = {
            id: rows[0].id,
            name: rows[0].title,
            type: rows[0].event_type || "Conference",
            date: rows[0].start_date ? new Date(rows[0].start_date).toISOString().split("T")[0] : "2026-09-20",
            venue: rows[0].location || "Main Stage",
            tone: "Visionary & Polished",
            description: rows[0].description || "",
            ownerId: rows[0].created_by || "organizer",
            joinCode: "TN26",
            anchorIds: [],
            liveState: {
              status: rows[0].status === "live" ? "live" : "draft",
              currentItemId: null,
              startedAt: rows[0].start_date ? new Date(rows[0].start_date).getTime() : null,
              totalDelayMin: 0,
            },
            createdAt: Date.now(),
          };
          memoryStore.createEvent(event);
        }
      } catch (_) {}
    }

    if (!event) {
      return sendError(res, "Event not found", "NOT_FOUND", 404);
    }

    const agenda = memoryStore.getAgenda(id);
    const currentId = event.liveState.currentItemId;
    const currentItem = agenda.find((it) => it.id === currentId);

    if (!currentItem) {
      // If dbPool, check if we can complete the in_progress agenda item in Neon
      if (dbPool) {
        try {
          const inProg = await query<any>(
            `SELECT id, order_in_agenda FROM agenda_items WHERE event_id = $1::uuid AND status = 'in_progress' LIMIT 1`,
            [id]
          );
          if (inProg.length > 0) {
            await query(
              `UPDATE agenda_items SET status = 'completed', actual_end_time = CURRENT_TIMESTAMP WHERE id = $1::uuid`,
              [inProg[0].id]
            );
            const nextRows = await query<any>(
              `SELECT id FROM agenda_items WHERE event_id = $1::uuid AND status = 'scheduled' ORDER BY order_in_agenda ASC LIMIT 1`,
              [id]
            );
            if (nextRows.length > 0) {
              await query(
                `UPDATE agenda_items SET status = 'in_progress', actual_start_time = CURRENT_TIMESTAMP WHERE id = $1::uuid`,
                [nextRows[0].id]
              );
            }
            return sendSuccess(res, {
              success: true,
              message: "Completed session in Neon DB",
            });
          }
        } catch (_) {}
      }
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

    // Update Neon PostgreSQL if available
    if (dbPool) {
      try {
        await query(
          `UPDATE agenda_items 
           SET status = 'completed', actual_end_time = CURRENT_TIMESTAMP 
           WHERE (id = $1::uuid OR id = $1) AND event_id = $2::uuid`,
          [currentItem.id, id]
        );
        if (nextItem) {
          await query(
            `UPDATE agenda_items 
             SET status = 'in_progress', actual_start_time = CURRENT_TIMESTAMP 
             WHERE (id = $1::uuid OR id = $1) AND event_id = $2::uuid`,
            [nextItem.id, id]
          );
        } else {
          await query(
            `UPDATE events SET status = 'completed' WHERE id = $1::uuid`,
            [id]
          );
        }
      } catch (neonErr) {
        console.warn("⚠️ [Neon DB] Complete current warning:", (neonErr as Error).message);
      }
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
    let event = memoryStore.getEvent(id);

    if (!event && dbPool) {
      try {
        const rows = await query<any>(`SELECT id, created_by FROM events WHERE id = $1::uuid`, [id]);
        if (rows.length > 0) {
          event = {
            id: rows[0].id,
            name: "SmartEve Live Event",
            type: "Conference",
            date: "2026-09-20",
            venue: "Main Stage",
            tone: "Visionary",
            description: "",
            ownerId: rows[0].created_by,
            joinCode: "TN26",
            anchorIds: [],
            liveState: { status: "live", currentItemId: null, startedAt: null, totalDelayMin: 0 },
            createdAt: Date.now(),
          };
        }
      } catch (_) {}
    }

    if (!event) return sendError(res, "Event not found", "NOT_FOUND", 404);

    if (dbPool) {
      try {
        const orgRows = await query<any>(`SELECT created_by FROM events WHERE id = $1::uuid`, [id]);
        const orgId = orgRows[0]?.created_by;
        if (orgId) {
          await query(
            `INSERT INTO announcements (event_id, created_by, content, announcement_type, priority, is_approved, is_sent, sent_at)
             VALUES ($1::uuid, $2::uuid, $3, 'general', $4::priority_level, true, true, CURRENT_TIMESTAMP)`,
            [id, orgId, message, priority === 'urgent' ? 'urgent' : (priority === 'high' ? 'high' : 'medium')]
          );
        }
      } catch (neonErr) {
        console.warn("⚠️ [Neon DB] Announce warning:", (neonErr as Error).message);
      }
    }

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

// GET all scripts for an event
eventsRouter.get("/:id/scripts", async (req: Request, res: Response) => {
  try {
    const { id } = req.params;

    if (dbPool) {
      try {
        const rows = await query<any>(
          `SELECT s.*, a.title as agenda_title, sp.name as speaker_name 
           FROM ai_scripts s
           LEFT JOIN agenda_items a ON s.agenda_item_id = a.id
           LEFT JOIN speakers sp ON a.speaker_id = sp.id
           WHERE s.event_id = $1::uuid
           ORDER BY s.created_at ASC`,
          [id]
        );
        if (rows && rows.length > 0) {
          const mapped = rows.map((r) => ({
            id: r.id,
            type: r.script_type || "opening",
            title: r.title || "Stage Script",
            speakerName: r.speaker_name || null,
            timeSlot: "10:30 AM - 10:45 AM",
            durationMinutes: 15,
            status: r.is_approved ? "approved" : "pending",
            itemId: r.agenda_item_id,
            text: r.content || "",
            tone: r.tone || "Motivational",
            targetAudience: r.target_audience || "All Attendees",
            organizerApprovedName: "Romal Tandel",
            source: "ai",
            provider: "gemini",
            version: r.version || 1,
            createdBy: r.created_by || "organizer",
            createdAt: new Date(r.created_at).getTime(),
            lastUpdated: new Date(r.updated_at || r.created_at).getTime(),
            isNew: false,
            isUpdated: false,
            isReviewedByAnchor: true,
            viewedByAnchor: true,
            usageCount: 1,
            modificationRequests: [],
          }));
          return sendSuccess(res, mapped);
        }
      } catch (_) {}
    }

    const event = memoryStore.getEvent(id);
    if (!event) return sendError(res, "Event not found", "NOT_FOUND", 404);
    const scripts = memoryStore.getScripts(id);
    return sendSuccess(res, scripts);
  } catch (err) {
    return sendError(res, (err as Error).message, "SERVER_ERROR", 500);
  }
});

// POST create script
eventsRouter.post("/:id/scripts", (req: Request, res: Response) => {
  try {
    const { id } = req.params;
    const event = memoryStore.getEvent(id);
    if (!event) return sendError(res, "Event not found", "NOT_FOUND", 404);

    const {
      type,
      title,
      text,
      speakerName,
      timeSlot,
      durationMinutes,
      status,
      tone,
      targetAudience,
      organizerApprovedName,
      organizerApprovedAvatarUrl,
    } = req.body;

    if (!type || !text) {
      return sendError(res, "Type and text are required", "VALIDATION_ERROR", 400);
    }

    const newScript = {
      id: `script-${Date.now()}`,
      type: type || "opening",
      title: title || (type === "opening" ? "Opening" : "Stage Script"),
      speakerName: speakerName || null,
      timeSlot: timeSlot || "10:30 AM - 10:35 AM",
      durationMinutes: Number(durationMinutes) || 5,
      status: status || "approved",
      text,
      tone: tone || "Motivational",
      targetAudience: targetAudience || "All Attendees",
      organizerApprovedName: organizerApprovedName || "Alex Rivera",
      organizerApprovedAvatarUrl: organizerApprovedAvatarUrl || null,
      source: "manual" as const,
      provider: "manual" as const,
      version: 1,
      createdBy: "organizer",
      createdAt: Date.now(),
      lastUpdated: Date.now(),
      isNew: true,
      isUpdated: false,
      isReviewedByAnchor: false,
      viewedByAnchor: false,
      usageCount: 0,
    };

    memoryStore.addScript(id, newScript);
    return sendSuccess(res, newScript, 201);
  } catch (err) {
    return sendError(res, (err as Error).message, "SERVER_ERROR", 500);
  }
});

// PATCH update script (reviewed status, text, approval, etc.)
eventsRouter.patch("/:id/scripts/:scriptId", (req: Request, res: Response) => {
  try {
    const { id, scriptId } = req.params;
    const event = memoryStore.getEvent(id);
    if (!event) return sendError(res, "Event not found", "NOT_FOUND", 404);

    const updated = memoryStore.updateScript(id, scriptId, req.body);
    if (!updated) return sendError(res, "Script not found", "NOT_FOUND", 404);

    return sendSuccess(res, updated);
  } catch (err) {
    return sendError(res, (err as Error).message, "SERVER_ERROR", 500);
  }
});

// POST submit modification request from anchor to organizer
eventsRouter.post("/:id/scripts/:scriptId/modify-request", (req: Request, res: Response) => {
  try {
    const { id, scriptId } = req.params;
    const event = memoryStore.getEvent(id);
    if (!event) return sendError(res, "Event not found", "NOT_FOUND", 404);

    const { anchorName, feedbackNote, priority } = req.body;
    if (!feedbackNote) {
      return sendError(res, "Feedback note is required", "VALIDATION_ERROR", 400);
    }

    const modRequest = {
      id: `req-${Date.now()}`,
      scriptId,
      anchorName: anchorName || "Jordan Hayes",
      feedbackNote,
      priority: priority || "medium",
      timestamp: Date.now(),
      status: "pending" as const,
    };

    const updated = memoryStore.addModificationRequest(id, scriptId, modRequest);
    if (!updated) return sendError(res, "Script not found", "NOT_FOUND", 404);

    // Also dispatch notification to organizer
    const notif: EventNotification = {
      id: `notif-${Date.now()}`,
      type: "announcement",
      message: `Anchor ${modRequest.anchorName} requested script change on "${updated.title}": ${feedbackNote}`,
      createdBy: "anchor",
      createdAt: Date.now(),
            priority: priority === "urgent" ? "urgent" : "normal",
    };
    memoryStore.addNotification(id, notif);

    return sendSuccess(res, { script: updated, modificationRequest: modRequest }, 201);
  } catch (err) {
    return sendError(res, (err as Error).message, "SERVER_ERROR", 500);
  }
});

// GET script usage analytics for admin
eventsRouter.get("/:id/scripts/analytics", (req: Request, res: Response) => {
  try {
    const { id } = req.params;
    const event = memoryStore.getEvent(id);
    if (!event) return sendError(res, "Event not found", "NOT_FOUND", 404);

    const analytics = memoryStore.getScriptAnalytics(id);
    return sendSuccess(res, analytics);
  } catch (err) {
    return sendError(res, (err as Error).message, "SERVER_ERROR", 500);
  }
});

