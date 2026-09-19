import { AgendaItem } from "../../types/agenda.js";
import { EventData } from "../../types/event.js";
import { Speaker } from "../../types/speaker.js";
import { ScriptType } from "../../types/script.js";

export interface ScriptContext {
  event: EventData;
  type: ScriptType;
  item?: AgendaItem | null;
  speakers?: Speaker[];
  nextItem?: AgendaItem | null;
  delayMinutes?: number;
  customContext?: string;
  tone?: string;
}

export function buildSystemInstruction(): string {
  return `You are an elite, world-class stage anchor co-pilot.
Your job is to generate speakable, energetic, professional, and crisp stage scripts for the live event anchor.

CRITICAL RULES:
1. Speakable & Natural: Write exactly what the anchor should speak out loud into the microphone. No stage directions in brackets, no "Good morning everyone, I am your host". Just high-impact stage prose.
2. Grounded Truth Only: Use ONLY the provided event name, speaker names, designations, companies, session titles, and delay timings. NEVER invent or hallucinate speakers, organizations, or facts.
3. Length: Keep it tight (between 30 to 75 words). The anchor needs to deliver it in under 30 seconds.
4. Output Format: Return ONLY a valid JSON object with the format: {"script": "Your spoken script here"}. Do not include markdown backticks or explanations.`;
}

export function buildUserPrompt(ctx: ScriptContext): string {
  const { event, type, item, speakers, nextItem, delayMinutes, customContext, tone } = ctx;

  const speakerInfo = speakers && speakers.length > 0
    ? speakers.map((s) => `${s.name} (${s.designation} at ${s.organization}), Topic: "${s.topic}"`).join("; ")
    : "None";

  return `EVENT CONTEXT:
Event Name: ${event.name}
Tone: ${tone || event.tone || "Professional, Engaging, and Dynamic"}
Script Category: ${type.toUpperCase()}
Current Session: ${item ? item.title : "General"}
Speaker(s): ${speakerInfo}
Next Upcoming Session: ${nextItem ? nextItem.title : "None"}
Delay / Time Adjustment: ${delayMinutes ? `${delayMinutes} minutes` : "On Schedule"}
Additional Live Notes: ${customContext || "None"}

TASK:
Write a stage-ready, spoken announcement for this ${type.replace("_", " ")} moment. Return strict JSON: {"script": "..."}`;
}
