import { NextRequest } from "next/server";
import { apiError, apiSuccess } from "@/lib/apiResponse";
import { AgendaItemSchema } from "@/lib/validation";
import { memoryStore } from "@/lib/store";
import { adminDb } from "@/lib/firebaseAdmin";
import { AgendaItem } from "@/types/agenda";

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
        .collection("agenda")
        .orderBy("order", "asc")
        .get();
      const items = snap.docs.map((d) => ({ id: d.id, ...d.data() }));
      return apiSuccess(items);
    }

    const items = memoryStore.getAgenda(id);
    return apiSuccess(items);
  } catch (err) {
    return apiError("Failed to fetch agenda", "SERVER_ERROR", 500);
  }
}

export async function POST(
  request: NextRequest,
  { params }: { params: Promise<{ id: string }> }
) {
  try {
    const { id } = await params;
    const body = await request.json();
    const parsed = AgendaItemSchema.safeParse(body);

    if (!parsed.success) {
      return apiError(parsed.error.errors[0]?.message || "Invalid agenda item", "VALIDATION_ERROR", 400);
    }

    const currentItems = memoryStore.getAgenda(id);
    const newItemId = `item-${Date.now()}`;
    const newItem: AgendaItem = {
      id: newItemId,
      order: currentItems.length + 1,
      ...parsed.data,
      status: "upcoming",
    };

    if (adminDb) {
      await adminDb.collection("events").doc(id).collection("agenda").doc(newItemId).set(newItem);
    } else {
      if (!memoryStore.getState().agenda[id]) memoryStore.getState().agenda[id] = {};
      memoryStore.getState().agenda[id][newItemId] = newItem;
    }

    return apiSuccess(newItem, 201);
  } catch (err) {
    return apiError("Failed to add agenda item", "SERVER_ERROR", 500);
  }
}
