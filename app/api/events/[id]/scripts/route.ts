import { NextRequest } from "next/server";
import { apiError, apiSuccess } from "@/lib/apiResponse";
import { memoryStore } from "@/lib/store";
import { adminDb } from "@/lib/firebaseAdmin";
import { Script } from "@/types/script";

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
        .collection("scripts")
        .orderBy("createdAt", "desc")
        .get();
      const items = snap.docs.map((d) => ({ id: d.id, ...d.data() }));
      return apiSuccess(items);
    }

    const items = memoryStore.getScripts(id);
    return apiSuccess(items);
  } catch (err) {
    return apiError("Failed to fetch scripts", "SERVER_ERROR", 500);
  }
}

export async function POST(
  request: NextRequest,
  { params }: { params: Promise<{ id: string }> }
) {
  try {
    const { id } = await params;
    const body = await request.json();
    const existing = memoryStore.getScripts(id);

    const scriptId = `script-${Date.now()}`;
    const newScript: Script = {
      id: scriptId,
      type: body.type || "opening",
      itemId: body.itemId || null,
      text: body.text || "",
      source: body.source || "manual",
      provider: body.provider || "manual",
      version: existing.filter((s) => s.type === body.type && s.itemId === body.itemId).length + 1,
      createdBy: body.createdBy || "anchor",
      createdAt: Date.now(),
    };

    if (adminDb) {
      await adminDb.collection("events").doc(id).collection("scripts").doc(scriptId).set(newScript);
    } else {
      memoryStore.addScript(id, newScript);
    }

    return apiSuccess(newScript, 201);
  } catch (err) {
    return apiError("Failed to save script", "SERVER_ERROR", 500);
  }
}
