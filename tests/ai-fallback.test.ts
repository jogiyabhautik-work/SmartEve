import { describe, it, expect } from "vitest";
import { generateStageScript } from "../lib/ai/generate";
import { generateFromTemplate } from "../lib/ai/templates";
import { INITIAL_DEMO_EVENT, INITIAL_DEMO_SPEAKERS } from "../lib/store";

describe("AI Triple Fallback Engine (lib/ai/)", () => {
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
    // Both GEMINI_API_KEY and GROQ_API_KEY unset in test env
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
