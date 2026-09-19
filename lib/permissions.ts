import { EventData } from "@/types/event";
import { User, UserRole } from "@/types/user";

export function canManageEvent(user: User | null, event: EventData | null): boolean {
  if (!user || !event) return false;
  if (user.role === "organizer" && event.ownerId === user.uid) return true;
  return false;
}

export function canControlLive(user: User | null, event: EventData | null): boolean {
  if (!user || !event) return false;
  if (canManageEvent(user, event)) return true;
  if (user.role === "anchor" && event.anchorIds.includes(user.uid)) return true;
  return false;
}

export function canCompleteCurrent(user: User | null, event: EventData | null): boolean {
  return canControlLive(user, event);
}

export function canGenerateScript(user: User | null, event: EventData | null): boolean {
  return canControlLive(user, event);
}

export function canAddDelay(user: User | null, event: EventData | null): boolean {
  // Organizer primary control; anchor can also trigger if assigned
  return canControlLive(user, event);
}
