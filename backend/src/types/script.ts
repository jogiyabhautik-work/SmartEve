export type ScriptType =
  | "opening"
  | "welcome"
  | "speaker_intro"
  | "transition"
  | "delay"
  | "unexpected"
  | "engagement"
  | "closing"
  | "announcement";

export type ScriptSource = "ai" | "template" | "manual";

export type ScriptStatus = "approved" | "pending" | "revised";

export interface ScriptModificationRequest {
  id: string;
  scriptId: string;
  anchorName: string;
  feedbackNote: string;
  priority: "low" | "medium" | "urgent";
  timestamp: number;
  status: "pending" | "resolved";
}

export interface Script {
  id: string;
  type: ScriptType;
  title: string;
  speakerName?: string | null;
  timeSlot?: string | null;
  durationMinutes?: number;
  status: ScriptStatus;
  itemId?: string | null;
  text: string;
  tone?: string;
  targetAudience?: string;
  organizerApprovedName?: string;
  organizerApprovedAvatarUrl?: string;
  source: ScriptSource;
  provider?: "gemini" | "groq" | "nvidia" | "openrouter" | "template" | "manual";
  version: number;
  createdBy: string;
  createdAt: number;
  lastUpdated: number;
  isNew?: boolean;
  isUpdated?: boolean;
  isReviewedByAnchor?: boolean;
  viewedByAnchor?: boolean;
  viewedAt?: number | null;
  usageCount?: number;
  modificationRequests?: ScriptModificationRequest[];
}

