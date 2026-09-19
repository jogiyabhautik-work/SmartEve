import { NextRequest } from "next/server";
import { apiError, apiSuccess } from "@/lib/apiResponse";
import { UpdateEventSchema } from "@/lib/validation";
import { memoryStore } from "@/lib/store";
import { adminDb } from "@/lib/firebaseAdmin";

export async function GET(
  request: NextRequest,
  { params }: { params: Promise<{ id: string }> }
) {
  try {
    const { id } = await params;
    if (adminDb) {
      const snap = await adminDb.collection("events").doc(id).get();
      if (snap.exists) {
        return apiSuccess({ id: snap.id, ...snap.data() });
      }
    }

    const event = memoryStore.getEvent(id);
    if (!event) {
      return apiError("Event not found", "NOT_FOUND", 404);
    }

    return apiSuccess(event);
  } catch (err) {
    return apiError("Failed to fetch event", "SERVER_ERROR", 500);
  }
}

export async function PUT(
  request: NextRequest,
  { params }: { params: Promise<{ id: string }> }
) {
  try {
    const { id } = await params;
    const body = await request.json();
    const parsed = UpdateEventSchema.safeParse(body);

    if (!parsed.success) {
      return apiError(parsed.error.errors[0]?.message || "Invalid update data", "VALIDATION_ERROR", 400);
    }

    if (adminDb) {
      await adminDb.collection("events").doc(id).update(parsed.data);
      const updated = await adminDb.collection("events").doc(id).get();
      return apiSuccess({ id: updated.id, ...updated.data() });
    }

    const updated = memoryStore.updateEvent(id, parsed.data);
    if (!updated) {
      return apiError("Event not found", "NOT_FOUND", 404);
    }

    return apiSuccess(updated);
  } catch (err) {
    return apiError("Failed to update event", "SERVER_ERROR", 500);
  }
}
