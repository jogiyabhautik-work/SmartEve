import { describe, it, expect } from "vitest";
import { calculateReflow, handleItemCancellation } from "../src/services/reflow.js";
import { AgendaItem } from "../src/types/agenda.js";

const createMockAgenda = (): AgendaItem[] => [
  {
    id: "item-1",
    order: 1,
    title: "Opening Remarks",
    type: "opening",
    speakerIds: [],
    duration: 15,
    plannedStart: "2026-09-19T10:00:00.000Z",
    startTime: "2026-09-19T10:00:00.000Z",
    endTime: "2026-09-19T10:15:00.000Z",
    status: "live",
    absorbable: false,
  },
  {
    id: "item-2",
    order: 2,
    title: "Keynote: Dr. Aris Vance",
    type: "keynote",
    speakerIds: ["spk-1"],
    duration: 45,
    plannedStart: "2026-09-19T10:15:00.000Z",
    startTime: "2026-09-19T10:15:00.000Z",
    endTime: "2026-09-19T11:00:00.000Z",
    status: "upcoming",
    absorbable: false,
  },
  {
    id: "item-3",
    order: 3,
    title: "Networking Tea Break",
    type: "break",
    speakerIds: [],
    duration: 30,
    plannedStart: "2026-09-19T11:00:00.000Z",
    startTime: "2026-09-19T11:00:00.000Z",
    endTime: "2026-09-19T11:30:00.000Z",
    status: "upcoming",
    absorbable: true,
    minDuration: 15,
  },
  {
    id: "item-4",
    order: 4,
    title: "Technical Talk",
    type: "talk",
    speakerIds: ["spk-2"],
    duration: 30,
    plannedStart: "2026-09-19T11:30:00.000Z",
    startTime: "2026-09-19T11:30:00.000Z",
    endTime: "2026-09-19T12:00:00.000Z",
    status: "upcoming",
    absorbable: false,
  },
  {
    id: "item-5",
    order: 5,
    title: "Hard-Start Live Broadcast",
    type: "talk",
    speakerIds: [],
    duration: 30,
    plannedStart: "2026-09-19T12:00:00.000Z",
    startTime: "2026-09-19T12:00:00.000Z",
    endTime: "2026-09-19T12:30:00.000Z",
    status: "upcoming",
    absorbable: false,
    hardStart: true,
  },
];

describe("Smart Delay & Reflow Engine (services/reflow.ts)", () => {
  it("handles +5 minute delay without violating constraints", () => {
    const items = createMockAgenda();
    const result = calculateReflow(items, 5, { fromItemId: "item-1" });

    expect(result.totalDelay).toBe(5);
    const item1 = result.items.find((it) => it.id === "item-1")!;
    expect(item1.endTime).toBe("2026-09-19T10:20:00.000Z");

    const item2 = result.items.find((it) => it.id === "item-2")!;
    expect(item2.startTime).toBe("2026-09-19T10:20:00.000Z");
    expect(item2.endTime).toBe("2026-09-19T11:05:00.000Z");

    const item3 = result.items.find((it) => it.id === "item-3")!;
    expect(item3.startTime).toBe("2026-09-19T11:05:00.000Z");
    expect(item3.duration).toBe(25);
    expect(item3.endTime).toBe("2026-09-19T11:30:00.000Z");

    const item4 = result.items.find((it) => it.id === "item-4")!;
    expect(item4.startTime).toBe("2026-09-19T11:30:00.000Z");
  });

  it("handles +15 minute delay with full break absorption", () => {
    const items = createMockAgenda();
    const result = calculateReflow(items, 15, { fromItemId: "item-1" });

    expect(result.totalDelay).toBe(15);
    const item3 = result.items.find((it) => it.id === "item-3")!;
    expect(item3.duration).toBe(15);
    expect(item3.endTime).toBe("2026-09-19T11:30:00.000Z");

    const item4 = result.items.find((it) => it.id === "item-4")!;
    expect(item4.startTime).toBe("2026-09-19T11:30:00.000Z");
    expect(result.conflicts).toHaveLength(0);
  });

  it("handles +20 minute delay exceeding break absorption capacity", () => {
    const items = createMockAgenda();
    const result = calculateReflow(items, 20, { fromItemId: "item-1" });

    const item3 = result.items.find((it) => it.id === "item-3")!;
    expect(item3.duration).toBe(15);
    expect(item3.endTime).toBe("2026-09-19T11:35:00.000Z");

    const item4 = result.items.find((it) => it.id === "item-4")!;
    expect(item4.startTime).toBe("2026-09-19T11:35:00.000Z");
    expect(item4.endTime).toBe("2026-09-19T12:05:00.000Z");

    expect(result.conflicts.length).toBeGreaterThan(0);
    expect(result.conflicts[0].itemId).toBe("item-5");
  });

  it("preserves completed activities untouched", () => {
    const items = createMockAgenda();
    items[0].status = "done";
    items[1].status = "live";

    const originalItem0 = { ...items[0] };
    const result = calculateReflow(items, 10, { fromItemId: "item-2" });

    const doneItem = result.items.find((it) => it.id === "item-1")!;
    expect(doneItem.startTime).toBe(originalItem0.startTime);
    expect(doneItem.endTime).toBe(originalItem0.endTime);
  });

  it("handles cancelled activity pulling subsequent items forward", () => {
    const items = createMockAgenda();
    const result = handleItemCancellation(items, "item-2");

    const cancelledItem = result.items.find((it) => it.id === "item-2")!;
    expect(cancelledItem.status).toBe("cancelled");

    const item3 = result.items.find((it) => it.id === "item-3")!;
    const item3Start = new Date(item3.startTime).getTime();
    const originalItem3Start = new Date("2026-09-19T11:00:00.000Z").getTime();
    expect(item3Start).toBeLessThan(originalItem3Start);
  });

  it("throws on invalid non-positive duration", () => {
    const items = createMockAgenda();
    items[2].duration = -5;

    expect(() => calculateReflow(items, 10)).toThrow(/Invalid duration/);
  });
});
