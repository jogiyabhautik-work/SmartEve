import { Router, Request, Response } from "express";
import { memoryStore } from "../services/store.js";
import { sendError, sendSuccess } from "../utils/apiResponse.js";

export const publicRouter = Router();

// Public time sync endpoint
publicRouter.get("/time", (req: Request, res: Response) => {
  return sendSuccess(res, {
    timestamp: Date.now(),
    iso: new Date().toISOString(),
  });
});

// Public stage display by join code
publicRouter.get("/:joinCode", (req: Request, res: Response) => {
  try {
    const { joinCode } = req.params;
    const event = memoryStore.getEventByJoinCode(joinCode);
    if (!event) {
      return sendError(res, "Invalid join code", "NOT_FOUND", 404);
    }

    const agenda = memoryStore.getAgenda(event.id);
    const speakers = memoryStore.getSpeakers(event.id);
    const notifications = memoryStore.getNotifications(event.id);

    const currentItem = agenda.find((it) => it.id === event.liveState.currentItemId) || null;
    const currentSpeakers = currentItem
      ? speakers.filter((s) => currentItem.speakerIds.includes(s.id))
      : [];

    const upcomingItems = agenda
      .filter((it) => it.status === "upcoming")
      .slice(0, 3);

    return sendSuccess(res, {
      event: {
        id: event.id,
        name: event.name,
        type: event.type,
        venue: event.venue,
        liveState: event.liveState,
      },
      currentSession: currentItem
        ? {
            ...currentItem,
            speakers: currentSpeakers,
          }
        : null,
      upcomingSessions: upcomingItems,
      latestNotification: notifications[0] || null,
      serverTime: Date.now(),
    });
  } catch (err) {
    return sendError(res, (err as Error).message, "SERVER_ERROR", 500);
  }
});
