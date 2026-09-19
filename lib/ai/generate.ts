import { ScriptContext } from "./prompts";
import { callGemini } from "./providers/gemini";
import { callGroq } from "./providers/groq";
import { generateFromTemplate } from "./templates";
import { AIResponse } from "@/types";

/**
 * Multi-Tier Fail-Safe Script Generator
 *
 * Sequence:
 * 1. Gemini (Primary AI)
 * 2. Groq (Secondary ultra-fast AI fallback)
 * 3. Contextual Deterministic Templates (Instant fail-safe fallback)
 * 4. Manual entry ready
 *
 * Never breaks the stage flow even during complete network or API disruption!
 */
export async function generateStageScript(ctx: ScriptContext): Promise<AIResponse> {
  // 1. Try Gemini
  try {
    const text = await callGemini(ctx);
    if (text && text.trim().length > 0) {
      return {
        script: text.trim(),
        source: "ai",
        provider: "gemini",
      };
    }
  } catch (err) {
    console.warn("Gemini provider failed, falling back to Groq:", (err as Error).message);
  }

  // 2. Try Groq
  try {
    const text = await callGroq(ctx);
    if (text && text.trim().length > 0) {
      return {
        script: text.trim(),
        source: "ai",
        provider: "groq",
      };
    }
  } catch (err) {
    console.warn("Groq provider failed, falling back to Template:", (err as Error).message);
  }

  // 3. Fallback to Context-Aware Template Engine
  const templateScript = generateFromTemplate(ctx);
  return {
    script: templateScript,
    source: "template",
    provider: "template",
  };
}
