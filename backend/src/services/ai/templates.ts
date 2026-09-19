import { ScriptContext } from "./prompts.js";

/**
 * Context-Aware Deterministic Template Engine (Fail-Safe Tier 3)
 * Guarantees instantaneous, reliable, realistic stage scripts even when offline or during API outage.
 */
export function generateFromTemplate(ctx: ScriptContext): string {
  const { event, type, item, speakers, nextItem, delayMinutes } = ctx;
  const speaker = speakers && speakers.length > 0 ? speakers[0] : null;

  switch (type) {
    case "opening":
      return `Good morning, ladies and gentlemen, and an electric welcome to ${event.name}! We have gathered the brightest minds and visionaries today at ${event.venue || "our main stage"}. Settle in, get inspired, and let's kick off an unforgettable day of breakthroughs!`;

    case "welcome":
      return `Welcome everyone to ${event.name}. Please take your seats, silence your mobile devices, and prepare for a series of high-impact keynotes and collaborative discussions. We are officially underway!`;

    case "speaker_intro":
      if (speaker) {
        return `It is my distinct privilege to introduce our next speaker. Please give a massive round of applause to ${speaker.name}, ${speaker.designation} at ${speaker.organization}, presenting "${speaker.topic || item?.title}"!`;
      }
      return `Please put your hands together as we welcome our distinguished guests to the stage for "${item?.title || "our next session"}"!`;

    case "transition":
      if (nextItem) {
        return `Thank you for those incredible insights. Moving right along in our agenda, let's prepare our minds for our next session: "${nextItem.title}". Let's give them a warm welcome!`;
      }
      return `Thank you for that phenomenal presentation. We are moving swiftly into our next segment—stay tuned!`;

    case "delay":
      const min = delayMinutes ? Math.abs(delayMinutes) : 10;
      return `Quick update from our stage team: To ensure every attendee gets the most value from our ongoing discussions, we are extending our current session by ${min} minutes. Our reflowed schedule is live on your displays. Thank you for your flexibility!`;

    case "unexpected":
      return `While our technical team sets up the next demonstration on stage, take a moment to connect with someone sitting next to you. Incredible breakthroughs happen in these spontaneous hallway conversations!`;

    case "engagement":
      return `Quick show of hands in the room—how many of you traveled from outside the city to be at ${event.name} today? Fantastic to see such a vibrant, passionate community gathered together!`;

    case "closing":
      return `What an exhilarating day at ${event.name}! A heartfelt thank you to our visionary speakers, sponsors, volunteers, and every single one of you in the audience for making this an extraordinary summit. Safe travels home!`;

    default:
      return `Thank you all for being part of ${event.name}. Please stay tuned as we progress smoothly through today's live flow!`;
  }
}
