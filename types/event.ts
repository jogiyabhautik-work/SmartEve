export type EventStatus = "draft" | "live" | "completed";

export interface LiveState {
  status: EventStatus;
  currentItemId: string | null;
  startedAt: number | null;
  totalDelayMin: number;
}

export interface EventData {
  id: string;
  name: string;
  type: string;
  date: string;
  venue: string;
  tone: string;
  description: string;
  ownerId: string;
  joinCode: string;
  anchorIds: string[];
  liveState: LiveState;
  createdAt: number;
}
