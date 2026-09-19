import { NextRequest } from "next/server";
import { apiError, apiSuccess } from "@/lib/apiResponse";
import { AnnounceSchema } from "@/lib/validation";
import { memoryStore } from "@/lib/store";
import { adminDb } from "@/lib/firebaseAdmin";
import { EventNotification } from "@/types/notification";

export async function POST(
  request: NextRequest,
  { params }: { params: Promise<{ id: string }> }
) {
  try {
    const { id } = await params;
    const body = await request.json();
    const parsed = AnnounceSchema.safeParse(body);

    if (!parsed.success) {
      return apiError(parsed.error.errors[0]?.message || "Invalid announcement", "VALIDATION_ERROR", 400);
    }

    const event = memoryStore.getEvent(id);
    if (!event) {
      return apiError("Event not found", "NOT_FOUND", 404);
    }

    const notif: EventNotification = {
      id: `notif-${Date.now()}`,
      type: "announcement",
      message: parsed.data.message,
      createdBy: "organizer",
      createdAt: Date.now(),
      priority: parsed.data.priority,
    };

    if (adminDb) {
      await adminDb.collection("events").doc(id).collection("notifications").doc(notif.id).set(notif);
    } else {
      memoryStore.addNotification(id, notif);
    }

    return apiSuccess(notif, 201);
  } catch (err) {
    return apiError("Failed to publish announcement", "SERVER_ERROR", 500);
  }
}
