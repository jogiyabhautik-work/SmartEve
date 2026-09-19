import { NextRequest } from "next/server";
import { apiError, apiSuccess } from "@/lib/apiResponse";
import { DelayRequestSchema } from "@/lib/validation";
import { memoryStore } from "@/lib/store";
import { adminDb } from "@/lib/firebaseAdmin";
import { calculateReflow } from "@/lib/reflow";
import { EventNotification } from "@/types/notification";

export async function POST(
  request: NextRequest,
  { params }: { params: Promise<{ id: string }> }
) {
  try {
    const { id } = await params;
    const body = await request.json();
    const parsed = DelayRequestSchema.safeParse(body);

    if (!parsed.success) {
      return apiError(parsed.error.errors[0]?.message || "Invalid delay request", "VALIDATION_ERROR", 400);
    }

    const { delayMinutes, targetItemId, reason } = parsed.data;
    const event = memoryStore.getEvent(id);
    if (!event) {
      return apiError("Event not found", "NOT_FOUND", 404);
    }

    const agenda = memoryStore.getAgenda(id);
    if (agenda.length === 0) {
      return apiError("Cannot delay an empty agenda", "EMPTY_AGENDA", 400);
    }

    // Run deterministic reflow engine
    const reflow = calculateReflow(agenda, delayMinutes, {
      fromItemId: targetItemId || event.liveState.currentItemId || undefined,
    });

    const newTotalDelay = (event.liveState.totalDelayMin || 0) + delayMinutes;
    const updatedLiveState = {
      ...event.liveState,
      totalDelayMin: newTotalDelay,
    };

    // Construct intelligent notification message describing break absorption or shift
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
    } else {
      memoryStore.updateEvent(id, { liveState: updatedLiveState });
      memoryStore.batchUpdateAgenda(id, reflow.items);
      memoryStore.addNotification(id, notif);
    }

    return apiSuccess({
      reflow,
      notification: notif,
      event: memoryStore.getEvent(id),
    });
  } catch (err) {
    console.error("Delay API error:", err);
    return apiError("Failed to apply schedule delay", "SERVER_ERROR", 500);
  }
}
