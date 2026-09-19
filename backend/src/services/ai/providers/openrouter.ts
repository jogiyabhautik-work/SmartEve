import { buildSystemInstruction, buildUserPrompt, ScriptContext } from "../prompts.js";

/**
 * OpenRouter Universal AI Provider
 * Unified gateway for models across Anthropic, Meta, Mistral, and Google.
 */
export async function callOpenRouter(ctx: ScriptContext, timeoutMs = 4500): Promise<string> {
  const apiKey = process.env.OPENROUTER_API_KEY;
  if (!apiKey) {
    throw new Error("OPENROUTER_API_KEY not configured");
  }

  const systemInstruction = buildSystemInstruction();
  const userPrompt = buildUserPrompt(ctx);

  const controller = new AbortController();
  const timeout = setTimeout(() => controller.abort(), timeoutMs);

  try {
    const response = await fetch("https://openrouter.ai/api/v1/chat/completions", {
      method: "POST",
      headers: {
        Authorization: `Bearer ${apiKey}`,
        "HTTP-Referer": "https://smarteve.io",
        "X-Title": "SmartEve Stage Flow",
        "Content-Type": "application/json",
      },
      signal: controller.signal,
      body: JSON.stringify({
        model: "meta-llama/llama-3.3-70b-instruct",
        messages: [
          { role: "system", content: systemInstruction },
          { role: "user", content: userPrompt },
        ],
        temperature: 0.7,
        max_tokens: 250,
      }),
    });

    if (!response.ok) {
      const errText = await response.text();
      throw new Error(`OpenRouter API error ${response.status}: ${errText}`);
    }

    const data = await response.json();
    const content = data.choices?.[0]?.message?.content;
    if (!content) {
      throw new Error("OpenRouter returned empty response");
    }

    const cleaned = content.replace(/```json/gi, "").replace(/```/g, "").trim();
    const parsed = JSON.parse(cleaned);
    if (!parsed.script) {
      throw new Error("OpenRouter output lacks 'script' field");
    }

    return parsed.script;
  } finally {
    clearTimeout(timeout);
  }
}
