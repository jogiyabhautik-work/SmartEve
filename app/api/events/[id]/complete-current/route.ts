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
    const liveIndex = agenda.findIndex((it) => it.id === event.liveState.currentItemId || it.status === "live");

    if (liveIndex === -1) {
      return apiError("No active live session to complete", "NO_ACTIVE_SESSION", 400);
    }

    const nowIso = new Date().toISOString();
    const completedItem = agenda[liveIndex];
    completedItem.status = "done";
    completedItem.actualEnd = nowIso;
    completedItem.endTime = nowIso;

    // Find next non-cancelled session
    let nextIndex = liveIndex + 1;
    while (nextIndex < agenda.length && (agenda[nextIndex].status === "cancelled" || agenda[nextIndex].status === "skipped")) {
      nextIndex++;
    }

    let nextItemId: string | null = null;
    let nextItem = null;

    if (nextIndex < agenda.length) {
      nextItem = agenda[nextIndex];
      nextItem.status = "live";
      nextItem.startTime = nowIso;
      nextItem.endTime = addMinutesToIso(nowIso, nextItem.duration);
      nextItemId = nextItem.id;
    }

    // Reflow the remaining upcoming items
    const reflow = calculateReflow(agenda, 0, {
      fromItemId: nextItemId || completedItem.id,
    });

    const isFinished = !nextItemId;
    const updatedLiveState = {
      ...event.liveState,
      status: isFinished ? ("completed" as const) : ("live" as const),
      currentItemId: nextItemId,
    };

    const notif: EventNotification = {
      id: `notif-${Date.now()}`,
      type: isFinished ? "done" : "change",
      message: isFinished
        ? `All sessions completed! ${event.name} has concluded.`
        : `Completed "${completedItem.title}". Now live: "${nextItem?.title}".`,
      createdBy: "anchor",
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
    console.error("Complete current error:", err);
    return apiError("Failed to complete current session", "SERVER_ERROR", 500);
  }
}
