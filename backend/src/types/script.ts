export type ScriptType =
  | "opening"
  | "welcome"
  | "speaker_intro"
  | "transition"
  | "delay"
  | "unexpected"
  | "engagement"
  | "closing";

export type ScriptSource = "ai" | "template" | "manual";

export interface Script {
  id: string;
  type: ScriptType;
  itemId?: string | null;
  text: string;
  source: ScriptSource;
  provider?: "gemini" | "groq" | "nvidia" | "openrouter" | "template" | "manual";
  version: number;
  createdBy: string;
  createdAt: number;
}
