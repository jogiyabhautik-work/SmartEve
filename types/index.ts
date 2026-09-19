export * from "./user";
export * from "./speaker";
export * from "./agenda";
export * from "./notification";
export * from "./script";
export * from "./event";

export interface AIRequest {
  eventId: string;
  type: import("./script").ScriptType;
  itemId?: string;
  tone?: string;
  notes?: string;
  delayMinutes?: number;
  customContext?: string;
}

export interface AIResponse {
  script: string;
  source: import("./script").ScriptSource;
  provider: "gemini" | "groq" | "template" | "manual";
}
