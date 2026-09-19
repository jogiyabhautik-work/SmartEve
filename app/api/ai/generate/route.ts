import { NextRequest } from "next/server";
import { apiError, apiSuccess } from "@/lib/apiResponse";
import { AIRequestSchema } from "@/lib/validation";
import { memoryStore } from "@/lib/store";
import { adminDb } from "@/lib/firebaseAdmin";
import { generateStageScript } from "@/lib/ai/generate";
import { ScriptContext } from "@/lib/ai/prompts";
import { Script } from "@/types/script";

export async function POST(request: NextRequest) {
  try {
    const body = await request.json();
    const parsed = AIRequestSchema.safeParse(body);

    if (!parsed.success) {
      return apiError(parsed.error.errors[0]?.message || "Invalid AI generation parameters", "VALIDATION_ERROR", 400);
    }

    const { eventId, type, itemId, customContext, tone, delayMinutes } = parsed.data;

    const event = memoryStore.getEvent(eventId);
    if (!event) {
      return apiError("Event not found", "NOT_FOUND", 404);
    }

    const agenda = memoryStore.getAgenda(eventId);
    const speakers = memoryStore.getSpeakers(eventId);

    const currentItem = itemId ? agenda.find((it) => it.id === itemId) : agenda.find((it) => it.status === "live");
    const currentIndex = currentItem ? agenda.findIndex((it) => it.id === currentItem.id) : -1;
    const nextItem = currentIndex !== -1 && currentIndex + 1 < agenda.length ? agenda[currentIndex + 1] : null;

    // Filter speakers associated with current item
    const itemSpeakers = currentItem
      ? speakers.filter((s) => currentItem.speakerIds.includes(s.id))
      : speakers.slice(0, 1);

    const ctx: ScriptContext = {
      event,
      type,
      item: currentItem || null,
      speakers: itemSpeakers,
      nextItem: nextItem || null,
      delayMinutes,
      customContext,
      tone,
    };

    // Run fail-safe generator (Gemini -> Groq -> Template)
    const result = await generateStageScript(ctx);

    const scriptId = `script-${Date.now()}`;
    const newScript: Script = {
      id: scriptId,
      type,
      itemId: currentItem?.id || null,
      text: result.script,
      source: result.source,
      provider: result.provider,
      version: 1,
      createdBy: "anchor",
      createdAt: Date.now(),
    };

    if (adminDb) {
      await adminDb.collection("events").doc(eventId).collection("scripts").doc(scriptId).set(newScript);
    } else {
      memoryStore.addScript(eventId, newScript);
    }

    return apiSuccess({
      script: result.script,
      source: result.source,
      provider: result.provider,
      scriptId: newScript.id,
    });
  } catch (err) {
    console.error("AI Generation error:", err);
    return apiError("Failed to generate stage script", "SERVER_ERROR", 500);
  }
}
