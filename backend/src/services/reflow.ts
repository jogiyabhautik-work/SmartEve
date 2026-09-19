import { AgendaItem, ReflowConflict, ReflowResult, ScheduleChange } from "../types/agenda.js";
import { addMinutesToIso } from "../utils/time.js";

export interface ReflowOptions {
  fromItemId?: string;
  pullScheduleOnEarlyFinish?: boolean;
}

/**
 * Deterministic Smart Delay and Schedule Reflow Engine
 *
 * Rules:
 * 1. Completed activities never change.
 * 2. Live activity can have its end time extended.
 * 3. Upcoming activities shift forward/backward.
 * 4. Absorbable breaks can absorb delays without shifting later sessions unnecessarily.
 * 5. Breaks cannot go below minDuration.
 * 6. Cancelled activities can pull later activities forward.
 * 7. Early finish can optionally pull schedule forward.
 * 8. Hard-start activities must be detected as conflicts.
 * 9. Negative durations are never allowed.
 * 10. Conflicts must be detected and returned in structured format.
 * 11. Every schedule modification creates a change record.
 * 12. Original plannedStart must remain untouched.
 */
export function calculateReflow(
  items: AgendaItem[],
  delayMinutes: number,
  options?: ReflowOptions
): ReflowResult {
  if (!items || items.length === 0) {
    return {
      items: [],
      changes: [],
      conflicts: [],
      totalDelay: 0,
      affectedItems: [],
    };
  }

  // Validate durations
  for (const item of items) {
    if (item.duration <= 0) {
      throw new Error(`Invalid duration (${item.duration}) for item "${item.title}". Duration must be positive.`);
    }
  }

  // Clone items to maintain immutability of inputs
  const cloned: AgendaItem[] = items
    .map((item) => ({ ...item }))
    .sort((a, b) => a.order - b.order);

  const changes: ScheduleChange[] = [];
  const conflicts: ReflowConflict[] = [];
  const affectedSet = new Set<string>();

  // Determine the pivot item
  let pivotIndex = -1;
  if (options?.fromItemId) {
    pivotIndex = cloned.findIndex((it) => it.id === options.fromItemId);
  }

  if (pivotIndex === -1) {
    // Look for currently live item
    pivotIndex = cloned.findIndex((it) => it.status === "live");
  }

  if (pivotIndex === -1) {
    // Look for first upcoming item
    pivotIndex = cloned.findIndex((it) => it.status === "upcoming");
  }

  if (pivotIndex === -1) {
    return {
      items: cloned,
      changes: [],
      conflicts: [],
      totalDelay: 0,
      affectedItems: [],
    };
  }

  let remainingDelay = delayMinutes;
  const pivotItem = cloned[pivotIndex];

  // If pivot item is cancelled, find the last active item before it
  let lastActiveEndTime: string;
  if (pivotItem.status === "cancelled") {
    let priorIndex = pivotIndex - 1;
    while (priorIndex >= 0 && (cloned[priorIndex].status === "cancelled" || cloned[priorIndex].status === "skipped")) {
      priorIndex--;
    }
    lastActiveEndTime = priorIndex >= 0 ? cloned[priorIndex].endTime : pivotItem.startTime;
  } else {
    // If pivot item is live or target of positive delay, adjust its end time
    if (pivotItem.status === "live" || pivotItem.id === options?.fromItemId) {
      const oldEnd = pivotItem.endTime;
      const newEnd = addMinutesToIso(oldEnd, remainingDelay);

      const startMs = new Date(pivotItem.startTime).getTime();
      const newEndMs = new Date(newEnd).getTime();

      if (newEndMs > startMs) {
        pivotItem.endTime = newEnd;
        pivotItem.duration = Math.max(1, Math.round((newEndMs - startMs) / (60 * 1000)));

        changes.push({
          itemId: pivotItem.id,
          title: pivotItem.title,
          oldStartTime: pivotItem.startTime,
          newStartTime: pivotItem.startTime,
          oldEndTime: oldEnd,
          newEndTime: newEnd,
        });
        affectedSet.add(pivotItem.id);
      }
    }
    lastActiveEndTime = pivotItem.endTime;
  }

  // Propagate to subsequent items
  for (let i = pivotIndex + 1; i < cloned.length; i++) {
    const current = cloned[i];

    // Done or cancelled items are preserved
    if (current.status === "done") {
      lastActiveEndTime = current.endTime;
      continue;
    }

    if (current.status === "cancelled" || current.status === "skipped") {
      continue;
    }

    const oldStart = current.startTime;
    const oldEnd = current.endTime;
    const initialDuration = current.duration;

    // Check if item is an absorbable break and we still have positive delay to absorb
    if (remainingDelay > 0 && current.absorbable) {
      const minDuration = current.minDuration ?? Math.max(5, Math.floor(current.duration / 2));
      const absorbCapacity = Math.max(0, current.duration - minDuration);

      if (absorbCapacity > 0) {
        const absorbed = Math.min(absorbCapacity, remainingDelay);
        current.duration -= absorbed;
        remainingDelay -= absorbed;
      }
    }

    // Schedule current item immediately following previous active item
    current.startTime = lastActiveEndTime;
    current.endTime = addMinutesToIso(current.startTime, current.duration);
    lastActiveEndTime = current.endTime;

    // Check hard-start constraint violation
    if (current.hardStart) {
      const plannedStartMs = new Date(current.plannedStart).getTime();
      const currentStartMs = new Date(current.startTime).getTime();

      if (Math.abs(currentStartMs - plannedStartMs) > 60 * 1000) {
        conflicts.push({
          itemId: current.id,
          title: current.title,
          reason: `Hard-start violation: Scheduled at ${current.startTime}, but fixed hard-start is ${current.plannedStart}`,
          hardStartTime: current.plannedStart,
          projectedStartTime: current.startTime,
        });
      }
    }

    // Check if timing or duration changed
    if (
      oldStart !== current.startTime ||
      oldEnd !== current.endTime ||
      initialDuration !== current.duration
    ) {
      changes.push({
        itemId: current.id,
        title: current.title,
        oldStartTime: oldStart,
        newStartTime: current.startTime,
        oldEndTime: oldEnd,
        newEndTime: current.endTime,
        durationChange: current.duration - initialDuration,
      });
      affectedSet.add(current.id);
    }
  }

  return {
    items: cloned,
    changes,
    conflicts,
    totalDelay: delayMinutes,
    affectedItems: Array.from(affectedSet),
  };
}

export function handleItemCancellation(
  items: AgendaItem[],
  cancelledItemId: string
): ReflowResult {
  const targetIndex = items.findIndex((it) => it.id === cancelledItemId);
  if (targetIndex === -1) {
    return { items, changes: [], conflicts: [], totalDelay: 0, affectedItems: [] };
  }

  const cloned = items.map((it) => ({ ...it }));
  const target = cloned[targetIndex];
  target.status = "cancelled";

  return calculateReflow(cloned, 0, {
    fromItemId: target.id,
  });
}
