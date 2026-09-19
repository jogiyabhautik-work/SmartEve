import { Router, Request, Response } from "express";
import { memoryStore } from "../services/store.js";
import { AIRequestSchema } from "../services/validation.js";
import { generateStageScript } from "../services/ai/generate.js";
import { sendError, sendSuccess } from "../utils/apiResponse.js";
import { Script } from "../types/script.js";

export const aiRouter = Router();

aiRouter.post("/generate", async (req: Request, res: Response) => {
  try {
    const parsed = AIRequestSchema.safeParse(req.body);
    if (!parsed.success) {
      return sendError(res, parsed.error.errors[0]?.message || "Invalid AI request", "VALIDATION_ERROR", 400);
    }

    const { eventId, type, itemId, tone, notes, delayMinutes, customContext } = parsed.data;
    const event = memoryStore.getEvent(eventId);
    if (!event) {
      return sendError(res, "Event not found", "NOT_FOUND", 404);
    }

    const agenda = memoryStore.getAgenda(eventId);
    const speakers = memoryStore.getSpeakers(eventId);

    const currentItem = itemId
      ? agenda.find((it) => it.id === itemId)
      : agenda.find((it) => it.id === event.liveState.currentItemId) || null;

    const currentSpeakers = currentItem
      ? speakers.filter((s) => currentItem.speakerIds.includes(s.id))
      : [];

    let nextItem = null;
    if (currentItem) {
      nextItem = agenda.find((it) => it.order > currentItem.order && it.status === "upcoming") || null;
    }

    const result = await generateStageScript({
      event,
      type,
      item: currentItem,
      speakers: currentSpeakers,
      nextItem,
      delayMinutes,
      customContext: notes || customContext,
      tone,
    });

    const scriptRecord: Script = {
      id: `script-${Date.now()}`,
      type,
      itemId: currentItem?.id || null,
      text: result.script,
      source: result.source,
      provider: result.provider,
      version: 1,
      createdBy: "ai",
      createdAt: Date.now(),
    };

    memoryStore.addScript(eventId, scriptRecord);

    return sendSuccess(res, {
      ...result,
      id: scriptRecord.id,
    });
  } catch (err) {
    console.error("AI Generation Route Error:", err);
    return sendError(res, "Failed to generate AI script", "AI_ERROR", 500);
  }
});
