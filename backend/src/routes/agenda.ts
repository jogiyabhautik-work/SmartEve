import { Router, Request, Response } from "express";
import { memoryStore } from "../services/store.js";
import { AgendaItemSchema } from "../services/validation.js";
import { sendError, sendSuccess } from "../utils/apiResponse.js";
import { AgendaItem, AgendaItemType, AgendaStatus } from "../types/agenda.js";
import { dbPool, query } from "../config/db.js";

export const agendaRouter = Router();

// GET event agenda
agendaRouter.get("/:id/agenda", async (req: Request, res: Response) => {
  try {
    const { id } = req.params;

    if (dbPool) {
      try {
        const rows = await query<any>(
          `SELECT a.*, s.name as speaker_name, s.designation as speaker_designation, s.organization as speaker_company, s.profile_image_url as speaker_avatar
           FROM agenda_items a
           LEFT JOIN speakers s ON a.speaker_id = s.id
           WHERE a.event_id = $1::uuid
           ORDER BY a.order_in_agenda ASC`,
          [id]
        );
        if (rows && rows.length > 0) {
          const validTypes: AgendaItemType[] = ["opening", "keynote", "talk", "panel", "break", "workshop", "announcement", "closing"];
          const mapped: AgendaItem[] = rows.map((r, index) => {
            const startIso = r.start_time ? new Date(r.start_time).toISOString() : new Date().toISOString();
            const endIso = r.end_time ? new Date(r.end_time).toISOString() : new Date(Date.now() + (r.duration_minutes || 15) * 60000).toISOString();
            const rawType = (r.type || "talk").toLowerCase();
            const itemType: AgendaItemType = validTypes.includes(rawType as AgendaItemType) ? (rawType as AgendaItemType) : (rawType === "speaker_session" ? "keynote" : "talk");
            const status: AgendaStatus = r.status === "in_progress" ? "live" : (r.status === "completed" ? "done" : "upcoming");

            return {
              id: r.id,
              order: r.order_in_agenda || (index + 1),
              title: r.title,
              type: itemType,
              speakerIds: r.speaker_id ? [r.speaker_id] : [],
              duration: r.duration_minutes || 15,
              plannedStart: startIso,
              startTime: startIso,
              endTime: endIso,
              status,
              absorbable: itemType === "break",
              notes: r.notes || r.description || undefined,
            };
          });
          return sendSuccess(res, mapped);
        }
      } catch (dbErr) {
        console.warn("⚠️ [Neon DB] GET /:id/agenda error, falling back to memory:", (dbErr as Error).message);
      }
    }

    const agenda = memoryStore.getAgenda(id);
    return sendSuccess(res, agenda);
  } catch (err) {
    return sendError(res, (err as Error).message, "SERVER_ERROR", 500);
  }
});

// POST add agenda item
agendaRouter.post("/:id/agenda", async (req: Request, res: Response) => {
  try {
    const { id } = req.params;
    const parsed = AgendaItemSchema.safeParse(req.body);
    if (!parsed.success) {
      return sendError(res, parsed.error.errors[0]?.message || "Invalid agenda item", "VALIDATION_ERROR", 400);
    }

    const currentAgenda = memoryStore.getAgenda(id);
    const newItem: AgendaItem = {
      id: `item-${Date.now()}`,
      order: currentAgenda.length + 1,
      ...parsed.data,
      status: "upcoming",
    };

    if (dbPool) {
      try {
        const orderInAgenda = currentAgenda.length + 1;
        const inserted = await query<any>(
          `INSERT INTO agenda_items (event_id, title, description, type, order_in_agenda, duration_minutes, status, start_time, end_time)
           VALUES ($1::uuid, $2, $3, $4, $5, $6, 'scheduled', $7, $8)
           RETURNING id`,
          [
            id,
            parsed.data.title,
            parsed.data.notes || null,
            parsed.data.type || "talk",
            orderInAgenda,
            parsed.data.duration,
            parsed.data.startTime,
            parsed.data.endTime,
          ]
        );
        if (inserted && inserted.length > 0) {
          newItem.id = inserted[0].id;
        }
      } catch (dbErr) {
        console.warn("⚠️ [Neon DB] Insert agenda_item fallback:", (dbErr as Error).message);
      }
    }

    memoryStore.addAgendaItem(id, newItem);
    return sendSuccess(res, newItem, 201);
  } catch (err) {
    return sendError(res, (err as Error).message, "SERVER_ERROR", 500);
  }
});

// PUT update agenda item
agendaRouter.put("/:id/agenda/:itemId", (req: Request, res: Response) => {
  try {
    const { id, itemId } = req.params;
    const updated = memoryStore.updateAgendaItem(id, itemId, req.body);
    if (!updated) {
      return sendError(res, "Agenda item not found", "NOT_FOUND", 404);
    }
    return sendSuccess(res, updated);
  } catch (err) {
    return sendError(res, (err as Error).message, "SERVER_ERROR", 500);
  }
});
