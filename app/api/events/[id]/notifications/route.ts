import { NextRequest } from "next/server";
import { apiError, apiSuccess } from "@/lib/apiResponse";
import { memoryStore } from "@/lib/store";
import { adminDb } from "@/lib/firebaseAdmin";

export async function GET(
  request: NextRequest,
  { params }: { params: Promise<{ id: string }> }
) {
  try {
    const { id } = await params;
    if (adminDb) {
      const snap = await adminDb
        .collection("events")
        .doc(id)
        .collection("notifications")
        .orderBy("createdAt", "desc")
        .limit(20)
        .get();
      const items = snap.docs.map((d) => ({ id: d.id, ...d.data() }));
      return apiSuccess(items);
    }

    const items = memoryStore.getNotifications(id);
    return apiSuccess(items);
  } catch (err) {
    return apiError("Failed to fetch notifications", "SERVER_ERROR", 500);
  }
}
