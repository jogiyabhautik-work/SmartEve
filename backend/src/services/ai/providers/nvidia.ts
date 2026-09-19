import { buildSystemInstruction, buildUserPrompt, ScriptContext } from "../prompts.js";

/**
 * Nvidia NIM (Inference Microservice) Provider
 * Fast enterprise inference using models hosted on NVIDIA DGX Cloud.
 */
export async function callNvidiaNim(ctx: ScriptContext, timeoutMs = 4500): Promise<string> {
  const apiKey = process.env.NVIDIA_NIM_API_KEY;
  if (!apiKey) {
    throw new Error("NVIDIA_NIM_API_KEY not configured");
  }

  const systemInstruction = buildSystemInstruction();
  const userPrompt = buildUserPrompt(ctx);

  const controller = new AbortController();
  const timeout = setTimeout(() => controller.abort(), timeoutMs);

  try {
    const response = await fetch("https://integrate.api.nvidia.com/v1/chat/completions", {
      method: "POST",
      headers: {
        Authorization: `Bearer ${apiKey}`,
        "Content-Type": "application/json",
      },
      signal: controller.signal,
      body: JSON.stringify({
        model: "meta/llama-3.3-70b-instruct",
        messages: [
          { role: "system", content: systemInstruction },
          { role: "user", content: userPrompt },
        ],
        temperature: 0.6,
        max_tokens: 250,
      }),
    });

    if (!response.ok) {
      const errText = await response.text();
      throw new Error(`Nvidia NIM API error ${response.status}: ${errText}`);
    }

    const data = await response.json();
    const content = data.choices?.[0]?.message?.content;
    if (!content) {
      throw new Error("Nvidia NIM returned empty response");
    }

    const cleaned = content.replace(/```json/gi, "").replace(/```/g, "").trim();
    const parsed = JSON.parse(cleaned);
    if (!parsed.script) {
      throw new Error("Nvidia NIM output lacks 'script' field");
    }

    return parsed.script;
  } finally {
    clearTimeout(timeout);
  }
}
