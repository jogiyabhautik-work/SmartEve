import { NextRequest } from "next/server";
import { apiError, apiSuccess } from "@/lib/apiResponse";
import { SpeakerSchema } from "@/lib/validation";
import { memoryStore } from "@/lib/store";
import { adminDb } from "@/lib/firebaseAdmin";
import { Speaker } from "@/types/speaker";

export async function GET(
  request: NextRequest,
  { params }: { params: Promise<{ id: string }> }
) {
  try {
    const { id } = await params;
    if (adminDb) {
      const snap = await adminDb.collection("events").doc(id).collection("speakers").get();
      const items = snap.docs.map((d) => ({ id: d.id, ...d.data() }));
      return apiSuccess(items);
    }

    const items = memoryStore.getSpeakers(id);
    return apiSuccess(items);
  } catch (err) {
    return apiError("Failed to fetch speakers", "SERVER_ERROR", 500);
  }
}

export async function POST(
  request: NextRequest,
  { params }: { params: Promise<{ id: string }> }
) {
  try {
    const { id } = await params;
    const body = await request.json();
    const parsed = SpeakerSchema.safeParse(body);

    if (!parsed.success) {
      return apiError(parsed.error.errors[0]?.message || "Invalid speaker data", "VALIDATION_ERROR", 400);
    }

    const speakerId = `spk-${Date.now()}`;
    const newSpeaker: Speaker = {
      id: speakerId,
      ...parsed.data,
    };

    if (adminDb) {
      await adminDb.collection("events").doc(id).collection("speakers").doc(speakerId).set(newSpeaker);
    } else {
      if (!memoryStore.getState().speakers[id]) memoryStore.getState().speakers[id] = {};
      memoryStore.getState().speakers[id][speakerId] = newSpeaker;
    }

    return apiSuccess(newSpeaker, 201);
  } catch (err) {
    return apiError("Failed to add speaker", "SERVER_ERROR", 500);
  }
}
