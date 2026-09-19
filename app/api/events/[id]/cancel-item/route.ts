import { NextRequest } from "next/server";
import { apiError, apiSuccess } from "@/lib/apiResponse";
import { CancelItemSchema } from "@/lib/validation";
import { memoryStore } from "@/lib/store";
import { adminDb } from "@/lib/firebaseAdmin";
import { handleItemCancellation } from "@/lib/reflow";
import { EventNotification } from "@/types/notification";

export async function POST(
  request: NextRequest,
  { params }: { params: Promise<{ id: string }> }
) {
  try {
    const { id } = await params;
    const body = await request.json();
    const parsed = CancelItemSchema.safeParse(body);

    if (!parsed.success) {
      return apiError(parsed.error.errors[0]?.message || "Invalid cancellation data", "VALIDATION_ERROR", 400);
    }

    const { itemId } = parsed.data;
    const event = memoryStore.getEvent(id);
    if (!event) {
      return apiError("Event not found", "NOT_FOUND", 404);
    }

    const agenda = memoryStore.getAgenda(id);
    const target = agenda.find((it) => it.id === itemId);
    if (!target) {
      return apiError("Agenda item not found", "NOT_FOUND", 404);
    }

    const reflow = handleItemCancellation(agenda, itemId);

    const notif: EventNotification = {
      id: `notif-${Date.now()}`,
      type: "cancel",
      message: `Session "${target.title}" was cancelled. Schedule has been pulled forward.`,
      changes: reflow.changes,
      createdBy: "organizer",
      createdAt: Date.now(),
      priority: "high",
    };

    if (adminDb) {
      const batch = adminDb.batch();
      const eventRef = adminDb.collection("events").doc(id);

      for (const it of reflow.items) {
        const itemRef = eventRef.collection("agenda").doc(it.id);
        batch.set(itemRef, it, { merge: true });
      }

      const notifRef = eventRef.collection("notifications").doc(notif.id);
      batch.set(notifRef, notif);

      await batch.commit();
    } else {
      memoryStore.batchUpdateAgenda(id, reflow.items);
      memoryStore.addNotification(id, notif);
    }

    return apiSuccess({
      reflow,
      notification: notif,
    });
  } catch (err) {
    console.error("Cancel item error:", err);
    return apiError("Failed to cancel agenda item", "SERVER_ERROR", 500);
  }
}
