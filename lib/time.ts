/**
 * Time and Date Utilities for Smart Anchor & Stage Flow
 */

/**
 * Formats an ISO string or Date to HH:mm (24h or 12h)
 */
export function formatTimeDisplay(dateOrIso: string | Date | number, use12Hour = true): string {
  if (!dateOrIso) return "--:--";
  const date = typeof dateOrIso === "string" || typeof dateOrIso === "number" ? new Date(dateOrIso) : dateOrIso;
  if (isNaN(date.getTime())) return "--:--";

  return date.toLocaleTimeString([], {
    hour: "2-digit",
    minute: "2-digit",
    hour12: use12Hour,
  });
}

/**
 * Formats a Date or ISO string into a concise readable date (e.g. "Sep 19, 2026")
 */
export function formatDateDisplay(dateOrIso: string | Date | number): string {
  if (!dateOrIso) return "";
  const date = typeof dateOrIso === "string" || typeof dateOrIso === "number" ? new Date(dateOrIso) : dateOrIso;
  if (isNaN(date.getTime())) return "";

  return date.toLocaleDateString(undefined, {
    month: "short",
    day: "numeric",
    year: "numeric",
  });
}

/**
 * Adds minutes to an ISO string or Date, returning a new ISO string
 */
export function addMinutesToIso(isoString: string, minutes: number): string {
  const date = new Date(isoString);
  if (isNaN(date.getTime())) return isoString;
  const newDate = new Date(date.getTime() + minutes * 60 * 1000);
  return newDate.toISOString();
}

/**
 * Calculates remaining seconds until endTimeMs
 * If nowMs > endTimeMs, returns negative seconds (overtime)
 */
export function getRemainingSeconds(endTimeIso: string, currentTimestampMs: number = Date.now()): number {
  if (!endTimeIso) return 0;
  const endMs = new Date(endTimeIso).getTime();
  if (isNaN(endMs)) return 0;
  return Math.floor((endMs - currentTimestampMs) / 1000);
}

/**
 * Formats remaining seconds into MM:SS or -MM:SS if in overtime
 */
export function formatCountdown(seconds: number): {
  formatted: string;
  isOvertime: boolean;
  minutes: number;
  remainingSeconds: number;
} {
  const isOvertime = seconds < 0;
  const absSeconds = Math.abs(seconds);
  const minutes = Math.floor(absSeconds / 60);
  const remainingSec = absSeconds % 60;

  const paddedMin = String(minutes).padStart(2, "0");
  const paddedSec = String(remainingSec).padStart(2, "0");

  return {
    formatted: `${isOvertime ? "+" : ""}${paddedMin}:${paddedSec}`,
    isOvertime,
    minutes,
    remainingSeconds: remainingSec,
  };
}

/**
 * Calculates percentage progress of an activity
 */
export function calculateProgress(startTimeIso: string, endTimeIso: string, currentMs: number = Date.now()): number {
  const startMs = new Date(startTimeIso).getTime();
  const endMs = new Date(endTimeIso).getTime();
  if (isNaN(startMs) || isNaN(endMs) || endMs <= startMs) return 0;

  if (currentMs <= startMs) return 0;
  if (currentMs >= endMs) return 100;

  return Math.min(100, Math.max(0, Math.round(((currentMs - startMs) / (endMs - startMs)) * 100)));
}
