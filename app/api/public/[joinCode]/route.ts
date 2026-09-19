import { NextRequest } from "next/server";
import { apiError, apiSuccess } from "@/lib/apiResponse";
import { memoryStore } from "@/lib/store";
import { adminDb } from "@/lib/firebaseAdmin";

export async function GET(
  request: NextRequest,
  { params }: { params: Promise<{ joinCode: string }> }
) {
  try {
    const { joinCode } = await params;
    if (!joinCode) {
      return apiError("Join code is required", "MISSING_JOIN_CODE", 400);
    }

    // Try Firebase Admin first if available
    if (adminDb) {
      const snap = await adminDb
        .collection("events")
        .where("joinCode", "==", joinCode.toUpperCase())
        .limit(1)
        .get();

      if (!snap.empty) {
        const eventDoc = snap.docs[0];
        const eventData = { id: eventDoc.id, ...eventDoc.data() };

        // Fetch agenda
        const agendaSnap = await eventDoc.ref.collection("agenda").orderBy("order", "asc").get();
        const agenda = agendaSnap.docs.map((d) => ({ id: d.id, ...d.data() }));

        // Fetch notifications
        const notifSnap = await eventDoc.ref.collection("notifications").orderBy("createdAt", "desc").limit(5).get();
        const notifications = notifSnap.docs.map((d) => ({ id: d.id, ...d.data() }));

        return apiSuccess({
          event: eventData,
          agenda,
          notifications,
        });
      }
    }

    // In-memory fallback
    const event = memoryStore.getEventByJoinCode(joinCode);
    if (!event) {
      return apiError("No active event found with this join code", "NOT_FOUND", 404);
    }

    const agenda = memoryStore.getAgenda(event.id);
    const notifications = memoryStore.getNotifications(event.id);
    const speakers = memoryStore.getSpeakers(event.id);

    return apiSuccess({
      event,
      agenda,
      notifications,
      speakers,
    });
  } catch (err) {
    console.error("Public stage API error:", err);
    return apiError("Failed to load stage display data", "INTERNAL_SERVER_ERROR", 500);
  }
}
