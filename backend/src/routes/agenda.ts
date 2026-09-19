import { Router, Request, Response } from "express";
import { memoryStore } from "../services/store.js";
import { AgendaItemSchema } from "../services/validation.js";
import { sendError, sendSuccess } from "../utils/apiResponse.js";
import { AgendaItem } from "../types/agenda.js";

export const agendaRouter = Router();

// GET event agenda
agendaRouter.get("/:id/agenda", (req: Request, res: Response) => {
  try {
    const { id } = req.params;
    const agenda = memoryStore.getAgenda(id);
    return sendSuccess(res, agenda);
  } catch (err) {
    return sendError(res, (err as Error).message, "SERVER_ERROR", 500);
  }
});

// POST add agenda item
agendaRouter.post("/:id/agenda", (req: Request, res: Response) => {
  try {
    const { id } = req.params;
    const parsed = AgendaItemSchema.safeParse(req.body);
    if (!parsed.success) {
      return sendError(res, parsed.error.errors[0]?.message || "Invalid agenda item", "VALIDATION_ERROR", 400);
    }

    const currentAgenda = memoryStore.getAgenda(id);
    const newItem: AgendaItem = {
      id: `item-${Date.now()}`,
      order: currentAgenda.length + 1,
      ...parsed.data,
      status: "upcoming",
    };

    memoryStore.addAgendaItem(id, newItem);
    return sendSuccess(res, newItem, 201);
  } catch (err) {
    return sendError(res, (err as Error).message, "SERVER_ERROR", 500);
  }
});

// PUT update agenda item
agendaRouter.put("/:id/agenda/:itemId", (req: Request, res: Response) => {
  try {
    const { id, itemId } = req.params;
    const updated = memoryStore.updateAgendaItem(id, itemId, req.body);
    if (!updated) {
      return sendError(res, "Agenda item not found", "NOT_FOUND", 404);
    }
    return sendSuccess(res, updated);
  } catch (err) {
    return sendError(res, (err as Error).message, "SERVER_ERROR", 500);
  }
});
