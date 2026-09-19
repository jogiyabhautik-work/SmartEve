import { ScriptContext } from "./prompts.js";
import { callGemini } from "./providers/gemini.js";
import { callGroq } from "./providers/groq.js";
import { callNvidiaNim } from "./providers/nvidia.js";
import { callOpenRouter } from "./providers/openrouter.js";
import { generateFromTemplate } from "./templates.js";
import { AIResponse } from "../../types/index.js";

/**
 * Quad-Tier Fail-Safe Script Generator
 *
 * Sequence:
 * 1. Gemini (Primary multimodal & creative reasoning)
 * 2. Groq (Secondary ultra-fast low-latency fallback)
 * 3. Nvidia NIM (Enterprise DGX microservice inference)
 * 4. OpenRouter (Universal multi-model fallback gateway)
 * 5. Contextual Deterministic Templates (Instant zero-latency offline guarantee)
 *
 * Guarantees stage continuity even during total internet dips or provider outages!
 */
export async function generateStageScript(ctx: ScriptContext): Promise<AIResponse> {
  // 1. Try Google Gemini
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
    console.warn("Gemini provider failed, cascading to Groq:", (err as Error).message);
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
    console.warn("Groq provider failed, cascading to Nvidia NIM:", (err as Error).message);
  }

  // 3. Try Nvidia NIM
  try {
    const text = await callNvidiaNim(ctx);
    if (text && text.trim().length > 0) {
      return {
        script: text.trim(),
        source: "ai",
        provider: "nvidia",
      };
    }
  } catch (err) {
    console.warn("Nvidia NIM provider failed, cascading to OpenRouter:", (err as Error).message);
  }

  // 4. Try OpenRouter
  try {
    const text = await callOpenRouter(ctx);
    if (text && text.trim().length > 0) {
      return {
        script: text.trim(),
        source: "ai",
        provider: "openrouter",
      };
    }
  } catch (err) {
    console.warn("OpenRouter provider failed, falling back to local Template:", (err as Error).message);
  }

  // 5. Ultimate Fallback: Context-Aware Deterministic Template Engine
  const templateScript = generateFromTemplate(ctx);
  return {
    script: templateScript,
    source: "template",
    provider: "template",
  };
}
