import { NextRequest } from "next/server";
import { apiError, apiSuccess } from "@/lib/apiResponse";
import { memoryStore } from "@/lib/store";
import { adminDb } from "@/lib/firebaseAdmin";
import { calculateReflow } from "@/lib/reflow";
import { addMinutesToIso } from "@/lib/time";
import { EventNotification } from "@/types/notification";

export async function POST(
  request: NextRequest,
  { params }: { params: Promise<{ id: string }> }
) {
  try {
    const { id } = await params;
    const event = memoryStore.getEvent(id);
    if (!event) {
      return apiError("Event not found", "NOT_FOUND", 404);
    }

    const agenda = memoryStore.getAgenda(id);
    if (agenda.length === 0) {
      return apiError("Cannot start an event with empty agenda", "EMPTY_AGENDA", 400);
    }

    const startTimeIso = new Date().toISOString();
    const firstItem = agenda[0];
    firstItem.status = "live";
    firstItem.startTime = startTimeIso;
    firstItem.endTime = addMinutesToIso(startTimeIso, firstItem.duration);

    // Reflow the rest of the schedule from first item
    const reflow = calculateReflow(agenda, 0, { fromItemId: firstItem.id });

    // Update liveState
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
    } else {
      memoryStore.updateEvent(id, { liveState: updatedLiveState });
      memoryStore.batchUpdateAgenda(id, reflow.items);
      memoryStore.addNotification(id, notif);
    }

    return apiSuccess({
      event: memoryStore.getEvent(id),
      agenda: reflow.items,
      notification: notif,
    });
  } catch (err) {
    console.error("Start event error:", err);
    return apiError("Failed to start event", "SERVER_ERROR", 500);
  }
}
