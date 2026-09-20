import { Router, Request, Response } from "express";
import { sendError, sendSuccess } from "../utils/apiResponse.js";
import { dbPool, query } from "../config/db.js";

export const checklistRouter = Router();

const UUID_RE =
  /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i;

// In-memory fallback checklist store: eventId -> itemKey -> completion
const checklistStore = new Map<string, Map<string, { isCompleted: boolean; completedAt: number | null }>>();

/**
 * Resolves the real DB identifiers required by anchor_checklist_items:
 * the event must be a UUID-backed row and must already have an assigned anchor.
 * Demo/memory events (string ids like "technova-2026") return null so the route
 * gracefully falls back to the in-memory store.
 */
async function resolveDbContext(
  eventId: string
): Promise<{ eventId: string; anchorId: string } | null> {
  if (!dbPool || !UUID_RE.test(eventId)) return null;
  try {
    const rows = await query<{ id: string; anchor_id: string | null }>(
      `SELECT e.id,
              (SELECT a.anchor_id
                 FROM event_anchors a
                WHERE a.event_id = e.id
                ORDER BY a.invited_at ASC
                LIMIT 1) AS anchor_id
         FROM events e
        WHERE e.id = $1`,
      [eventId]
    );
    if (rows.length === 0 || !rows[0].anchor_id) return null;
    return { eventId: rows[0].id, anchorId: rows[0].anchor_id };
  } catch (dbErr) {
    console.warn("⚠️ [Neon DB] checklist context lookup error:", (dbErr as Error).message);
    return null;
  }
}


const DEFAULT_CHECKLIST = [
  { itemKey: "review_speakers", label: "Review all speakers & their details", orderIndex: 1 },
  { itemKey: "memorize_opening", label: "Memorize opening script", orderIndex: 2 },
  { itemKey: "check_audio", label: "Check audio setup (mic working)", orderIndex: 3 },
  { itemKey: "check_video", label: "Check video setup (camera working)", orderIndex: 4 },
  { itemKey: "review_scripts", label: "Review all generated scripts", orderIndex: 5 },
  { itemKey: "agenda_flow", label: "Familiarize with agenda flow", orderIndex: 6 },
  { itemKey: "check_internet", label: "Check internet connection", orderIndex: 7 },
  { itemKey: "notify_organizer", label: "Notify organizer when ready", orderIndex: 8 },
];

function getEventChecklist(eventId: string) {
  if (!checklistStore.has(eventId)) {
    checklistStore.set(eventId, new Map());
  }
  return checklistStore.get(eventId)!;
}

// GET /api/events/:id/checklist
checklistRouter.get("/:id/checklist", async (req: Request, res: Response) => {
  try {
    const { id } = req.params;
    const mem = getEventChecklist(id);

    // Always return the full canonical checklist so consumers (anchor UI,
    // organizer/admin status views) get a stable 8-item shape.
    const items = DEFAULT_CHECKLIST.map((def) => {
      const state = mem.get(def.itemKey);
      return {
        id: `${id}-${def.itemKey}`,
        itemKey: def.itemKey,
        label: def.label,
        isCompleted: state?.isCompleted ?? false,
        completedAt: state?.completedAt ?? null,
        orderIndex: def.orderIndex,
      };
    });

    // Overlay persisted DB state where the event/anchor pair is UUID-backed.
    const ctx = await resolveDbContext(id);
    if (ctx) {
      try {
        const rows = await query<Record<string, unknown>>(
          `SELECT item_key, is_completed, completed_at
           FROM anchor_checklist_items
           WHERE event_id = $1 AND anchor_id = $2`,
          [ctx.eventId, ctx.anchorId]
        );
        const byKey = new Map(
          rows.map((row) => [String(row.item_key), row])
        );
        for (const item of items) {
          const row = byKey.get(item.itemKey);
          if (row) {
            item.isCompleted = Boolean(row.is_completed);
            item.completedAt = row.completed_at
              ? new Date(row.completed_at as string).getTime()
              : null;
          }
        }
      } catch (dbErr) {
        console.warn("⚠️ [Neon DB] checklist fetch error:", (dbErr as Error).message);
      }
    }

    return sendSuccess(res, items);
  } catch (err) {
    return sendError(res, (err as Error).message, "SERVER_ERROR", 500);
  }
});

// PUT /api/events/:id/checklist/:itemId  { isCompleted: boolean }
checklistRouter.put("/:id/checklist/:itemId", async (req: Request, res: Response) => {
  try {
    const { id, itemId } = req.params;
    const { isCompleted } = req.body as { isCompleted?: boolean };
    const itemKey = itemId.replace(`${id}-`, "");
    const completedAt = isCompleted ? new Date() : null;

    const ctx = await resolveDbContext(id);
    if (ctx) {
      try {
        await query(
          `INSERT INTO anchor_checklist_items (event_id, anchor_id, item_key, label, is_completed, completed_at, order_index)
           VALUES ($1, $2, $3, $4, $5, $6, $7)
           ON CONFLICT (event_id, anchor_id, item_key)
           DO UPDATE SET is_completed = EXCLUDED.is_completed, completed_at = EXCLUDED.completed_at`,
          [
            ctx.eventId,
            ctx.anchorId,
            itemKey,
            DEFAULT_CHECKLIST.find((d) => d.itemKey === itemKey)?.label ?? itemKey,
            isCompleted ?? false,
            completedAt,
            DEFAULT_CHECKLIST.find((d) => d.itemKey === itemKey)?.orderIndex ?? 0,
          ]
        );
      } catch (dbErr) {
        console.warn("⚠️ [Neon DB] checklist update error:", (dbErr as Error).message);
      }
    }

    const mem = getEventChecklist(id);
    mem.set(itemKey, {
      isCompleted: isCompleted ?? false,
      completedAt: isCompleted ? Date.now() : null,
    });

    // If anchor marked "notify organizer", surface a ready signal.
    const ready = mem.get("notify_organizer")?.isCompleted ?? false;
    return sendSuccess(res, { itemKey, isCompleted: isCompleted ?? false, anchorReady: ready });
  } catch (err) {
    return sendError(res, (err as Error).message, "SERVER_ERROR", 500);
  }
});

// POST /api/events/:id/checklist/complete-all
checklistRouter.post("/:id/checklist/complete-all", async (req: Request, res: Response) => {
  try {
    const { id } = req.params;
    const mem = getEventChecklist(id);
    const now = Date.now();
    for (const def of DEFAULT_CHECKLIST) {
      mem.set(def.itemKey, { isCompleted: true, completedAt: now });
    }

    const ctx = await resolveDbContext(id);
    if (ctx) {
      try {
        for (const def of DEFAULT_CHECKLIST) {
          await query(
            `INSERT INTO anchor_checklist_items (event_id, anchor_id, item_key, label, is_completed, completed_at, order_index)
             VALUES ($1, $2, $3, $4, TRUE, CURRENT_TIMESTAMP, $5)
             ON CONFLICT (event_id, anchor_id, item_key)
             DO UPDATE SET is_completed = TRUE, completed_at = CURRENT_TIMESTAMP`,
            [ctx.eventId, ctx.anchorId, def.itemKey, def.label, def.orderIndex]
          );
        }
      } catch (dbErr) {
        console.warn("⚠️ [Neon DB] checklist complete-all error:", (dbErr as Error).message);
      }
    }

    return sendSuccess(res, { completedCount: DEFAULT_CHECKLIST.length, anchorReady: true });
  } catch (err) {
    return sendError(res, (err as Error).message, "SERVER_ERROR", 500);
  }
});
