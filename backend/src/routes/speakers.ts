import { Router, Request, Response } from "express";
import { memoryStore } from "../services/store.js";
import { SpeakerSchema } from "../services/validation.js";
import { sendError, sendSuccess } from "../utils/apiResponse.js";
import { Speaker } from "../types/speaker.js";
import { dbPool, query } from "../config/db.js";

export const speakersRouter = Router();

// GET event speakers
speakersRouter.get("/:id/speakers", async (req: Request, res: Response) => {
  try {
    const { id } = req.params;

    if (dbPool) {
      try {
        const rows = await query<any>(
          `SELECT * FROM speakers WHERE event_id = $1::uuid ORDER BY order_in_event ASC`,
          [id]
        );
        if (rows && rows.length > 0) {
          const mapped: Speaker[] = rows.map((s) => ({
            id: s.id,
            name: s.name,
            designation: s.designation || "Featured Speaker",
            organization: s.organization || "BliXo Tech",
            topic: s.bio || "Keynote Presentation",
            bio: s.bio || "Pioneer in distributed edge intelligence.",
            highlights: ["Keynote", "AI Architecture"],
            photoUrl: s.profile_image_url || undefined,
            status: "arrived",
          }));
          return sendSuccess(res, mapped);
        }
      } catch (dbErr) {
        console.warn("⚠️ [Neon DB] GET /:id/speakers error, falling back to memory:", (dbErr as Error).message);
      }
    }

    const speakers = memoryStore.getSpeakers(id);
    return sendSuccess(res, speakers);
  } catch (err) {
    return sendError(res, (err as Error).message, "SERVER_ERROR", 500);
  }
});

// POST add speaker
speakersRouter.post("/:id/speakers", (req: Request, res: Response) => {
  try {
    const { id } = req.params;
    const parsed = SpeakerSchema.safeParse(req.body);
    if (!parsed.success) {
      return sendError(res, parsed.error.errors[0]?.message || "Invalid speaker data", "VALIDATION_ERROR", 400);
    }

    const newSpeaker: Speaker = {
      id: `spk-${Date.now()}`,
      ...parsed.data,
    };

    memoryStore.addSpeaker(id, newSpeaker);
    return sendSuccess(res, newSpeaker, 201);
  } catch (err) {
    return sendError(res, (err as Error).message, "SERVER_ERROR", 500);
  }
});

// PUT update speaker
speakersRouter.put("/:id/speakers/:speakerId", (req: Request, res: Response) => {
  try {
    const { id, speakerId } = req.params;
    const updated = memoryStore.updateSpeaker(id, speakerId, req.body);
    if (!updated) {
      return sendError(res, "Speaker not found", "NOT_FOUND", 404);
    }
    return sendSuccess(res, updated);
  } catch (err) {
    return sendError(res, (err as Error).message, "SERVER_ERROR", 500);
  }
});
