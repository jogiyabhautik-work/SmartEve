import { User, UserRole } from "@/types/user";
import { INITIAL_DEMO_USERS } from "./store";

export function getMockUser(role: UserRole = "organizer"): User {
  if (role === "anchor") {
    return INITIAL_DEMO_USERS["user-anchor-1"];
  }
  return INITIAL_DEMO_USERS["user-organizer-1"];
}

export function getCurrentUser(): User {
  if (typeof window !== "undefined") {
    const savedRole = localStorage.getItem("smart_anchor_role") as UserRole;
    if (savedRole === "anchor") {
      return INITIAL_DEMO_USERS["user-anchor-1"];
    }
  }
  return INITIAL_DEMO_USERS["user-organizer-1"];
}

export function switchUserRole(role: UserRole): User {
  if (typeof window !== "undefined") {
    localStorage.setItem("smart_anchor_role", role);
    window.dispatchEvent(new Event("storage"));
  }
  return getMockUser(role);
}
