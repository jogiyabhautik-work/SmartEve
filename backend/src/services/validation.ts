import { z } from "zod";

export const CreateEventSchema = z.object({
  name: z.string().min(2, "Event name must be at least 2 characters"),
  type: z.string().default("Conference"),
  date: z.string().min(1, "Date is required"),
  venue: z.string().min(1, "Venue is required"),
  tone: z.string().default("Professional & Energetic"),
  description: z.string().optional().default(""),
  joinCode: z.string().min(3).max(8).toUpperCase(),
});

export const UpdateEventSchema = CreateEventSchema.partial();

export const AgendaItemSchema = z.object({
  title: z.string().min(2, "Title is required"),
  type: z.enum([
    "opening",
    "keynote",
    "talk",
    "panel",
    "break",
    "workshop",
    "announcement",
    "closing",
  ]),
  speakerIds: z.array(z.string()).default([]),
  duration: z.number().min(1, "Duration must be at least 1 minute"),
  plannedStart: z.string().min(1, "Planned start is required"),
  startTime: z.string().min(1, "Start time is required"),
  endTime: z.string().min(1, "End time is required"),
  absorbable: z.boolean().default(false),
  minDuration: z.number().min(0).optional(),
  hardStart: z.boolean().default(false),
  notes: z.string().optional(),
});

export const DelayRequestSchema = z.object({
  delayMinutes: z.number().int().refine((n) => n !== 0, {
    message: "Delay minutes must be non-zero",
  }),
  targetItemId: z.string().optional(),
  reason: z.string().optional(),
});

export const CancelItemSchema = z.object({
  itemId: z.string().min(1, "Item ID is required"),
  pullScheduleForward: z.boolean().default(true),
});

export const AnnounceSchema = z.object({
  message: z.string().min(2, "Message is required"),
  priority: z.enum(["normal", "high", "urgent"]).default("normal"),
});

export const SpeakerSchema = z.object({
  name: z.string().min(2, "Name is required"),
  designation: z.string().min(2, "Designation is required"),
  organization: z.string().min(1, "Organization is required"),
  topic: z.string().default(""),
  bio: z.string().default(""),
  highlights: z.array(z.string()).default([]),
  photoUrl: z.string().url().optional().or(z.literal("")),
  status: z.enum(["expected", "arrived", "absent"]).default("expected"),
});

export const AIRequestSchema = z.object({
  eventId: z.string().min(1, "Event ID is required"),
  type: z.enum([
    "opening",
    "welcome",
    "speaker_intro",
    "transition",
    "delay",
    "unexpected",
    "engagement",
    "closing",
  ]),
  itemId: z.string().optional(),
  tone: z.string().optional(),
  notes: z.string().optional(),
  delayMinutes: z.number().optional(),
  customContext: z.string().optional(),
});
