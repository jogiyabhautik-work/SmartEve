import { NextRequest } from "next/server";
import { apiError, apiSuccess } from "@/lib/apiResponse";
import { CreateEventSchema } from "@/lib/validation";
import { memoryStore } from "@/lib/store";
import { adminDb } from "@/lib/firebaseAdmin";
import { EventData } from "@/types/event";

export async function GET() {
  try {
    if (adminDb) {
      const snap = await adminDb.collection("events").orderBy("createdAt", "desc").get();
      const events = snap.docs.map((d) => ({ id: d.id, ...d.data() }));
      return apiSuccess(events);
    }

    const events = Object.values(memoryStore.getState().events);
    return apiSuccess(events);
  } catch (err) {
    return apiError("Failed to fetch events", "FETCH_ERROR", 500);
  }
}

export async function POST(request: NextRequest) {
  try {
    const body = await request.json();
    const parsed = CreateEventSchema.safeParse(body);

    if (!parsed.success) {
      return apiError(parsed.error.errors[0]?.message || "Invalid event data", "VALIDATION_ERROR", 400);
    }

    const eventId = `event-${Date.now()}`;
    const newEvent: EventData = {
      id: eventId,
      ...parsed.data,
      ownerId: "user-organizer-1",
      anchorIds: ["user-anchor-1"],
      liveState: {
        status: "draft",
        currentItemId: null,
        startedAt: null,
        totalDelayMin: 0,
      },
      createdAt: Date.now(),
    };

    if (adminDb) {
      await adminDb.collection("events").doc(eventId).set(newEvent);
    } else {
      memoryStore.getState().events[eventId] = newEvent;
    }

    return apiSuccess(newEvent, 201);
  } catch (err) {
    return apiError("Failed to create event", "SERVER_ERROR", 500);
  }
}
