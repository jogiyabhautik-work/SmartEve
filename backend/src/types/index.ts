import { ScriptSource, ScriptType } from "./script.js";

export * from "./user.js";
export * from "./speaker.js";
export * from "./agenda.js";
export * from "./notification.js";
export * from "./script.js";
export * from "./event.js";

export interface AIRequest {
  eventId: string;
  type: ScriptType;
  itemId?: string;
  tone?: string;
  notes?: string;
  delayMinutes?: number;
  customContext?: string;
}

export interface AIResponse {
  script: string;
  source: ScriptSource;
  provider: "gemini" | "groq" | "nvidia" | "openrouter" | "template" | "manual";
}
