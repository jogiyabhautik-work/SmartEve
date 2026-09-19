import { describe, it, expect } from "vitest";
import {
  CreateEventSchema,
  DelayRequestSchema,
  CancelItemSchema,
  SpeakerSchema,
  AIRequestSchema,
} from "../lib/validation";

describe("Validation Schemas (lib/validation.ts)", () => {
  it("validates event creation payload", () => {
    const valid = {
      name: "TechNova 2026",
      date: "2026-09-19",
      venue: "Main Auditorium",
      joinCode: "TN26",
    };
    const res = CreateEventSchema.safeParse(valid);
    expect(res.success).toBe(true);

    const invalid = {
      name: "T", // too short
      joinCode: "TOOLONG123", // too long
    };
    const invalidRes = CreateEventSchema.safeParse(invalid);
    expect(invalidRes.success).toBe(false);
  });

  it("validates delay requests", () => {
    expect(DelayRequestSchema.safeParse({ delayMinutes: 15 }).success).toBe(true);
    expect(DelayRequestSchema.safeParse({ delayMinutes: -10 }).success).toBe(true);
    // zero is rejected
    expect(DelayRequestSchema.safeParse({ delayMinutes: 0 }).success).toBe(false);
  });

  it("validates speaker data", () => {
    const speaker = {
      name: "Dr. Aris Vance",
      designation: "VP of AI",
      organization: "DeepScale Labs",
    };
    const res = SpeakerSchema.safeParse(speaker);
    expect(res.success).toBe(true);
  });

  it("validates AI generation request", () => {
    const aiReq = {
      eventId: "technova-2026",
      type: "speaker_intro",
    };
    expect(AIRequestSchema.safeParse(aiReq).success).toBe(true);
    // Invalid type
    expect(AIRequestSchema.safeParse({ eventId: "test", type: "invalid_type" }).success).toBe(false);
  });
});
