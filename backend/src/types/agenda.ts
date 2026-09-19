export type AgendaStatus = "upcoming" | "live" | "done" | "cancelled" | "skipped";

export type AgendaItemType =
  | "opening"
  | "keynote"
  | "talk"
  | "panel"
  | "break"
  | "workshop"
  | "announcement"
  | "closing";

export interface AgendaItem {
  id: string;
  order: number;
  title: string;
  type: AgendaItemType;
  speakerIds: string[];
  duration: number; // in minutes
  plannedStart: string; // original ISO string or timestamp
  startTime: string; // current reflowed start time
  endTime: string; // current calculated end time
  status: AgendaStatus;
  absorbable: boolean;
  minDuration?: number; // minimum duration if absorbable (in minutes)
  hardStart?: boolean; // cannot be shifted forward/backward without conflict
  notes?: string;
  actualStart?: string;
  actualEnd?: string;
}

export interface ScheduleChange {
  itemId: string;
  title: string;
  oldStartTime: string;
  newStartTime: string;
  oldEndTime: string;
  newEndTime: string;
  durationChange?: number; // e.g., -10 if absorbed
}

export interface ReflowConflict {
  itemId: string;
  title: string;
  reason: string;
  hardStartTime?: string;
  projectedStartTime?: string;
}

export interface ReflowResult {
  items: AgendaItem[];
  changes: ScheduleChange[];
  conflicts: ReflowConflict[];
  totalDelay: number;
  affectedItems: string[];
}
