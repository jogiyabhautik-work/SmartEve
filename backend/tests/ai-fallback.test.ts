import { describe, it, expect } from "vitest";
import { generateStageScript } from "../src/services/ai/generate.js";
import { generateFromTemplate } from "../src/services/ai/templates.js";
import { INITIAL_DEMO_EVENT, INITIAL_DEMO_SPEAKERS } from "../src/services/store.js";

describe("Quad-Tier AI Fallback Engine (Gemini -> Groq -> Nvidia NIM -> OpenRouter -> Templates)", () => {
  const ctx = {
    event: INITIAL_DEMO_EVENT,
    type: "speaker_intro" as const,
    speakers: [INITIAL_DEMO_SPEAKERS["spk-1"]],
  };

  it("generates contextual template script on fallback", () => {
    const text = generateFromTemplate(ctx);
    expect(text).toContain("Dr. Aris Vance");
    expect(text).toContain("DeepScale Labs");
  });

  it("generates script without throwing when external AI credentials are unset", async () => {
    const result = await generateStageScript(ctx);

    expect(result.script).toBeDefined();
    expect(result.script.length).toBeGreaterThan(10);
    expect(result.source).toBe("template");
    expect(result.provider).toBe("template");
  });

  it("generates speakable delay announcement with real minutes", () => {
    const delayCtx = {
      event: INITIAL_DEMO_EVENT,
      type: "delay" as const,
      delayMinutes: 15,
    };
    const text = generateFromTemplate(delayCtx);
    expect(text).toContain("15 minutes");
  });
});
