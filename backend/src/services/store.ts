import { AgendaItem } from "../types/agenda.js";
import { EventData } from "../types/event.js";
import { EventNotification } from "../types/notification.js";
import { Script } from "../types/script.js";
import { Speaker } from "../types/speaker.js";
import { User } from "../types/user.js";

export interface EventStoreState {
  users: Record<string, User>;
  events: Record<string, EventData>;
  speakers: Record<string, Record<string, Speaker>>;
  agenda: Record<string, Record<string, AgendaItem>>;
  notifications: Record<string, EventNotification[]>;
  scripts: Record<string, Script[]>;
}

const now = new Date();
const baseTime = new Date(now.getTime() - 5 * 60 * 1000);

function makeIso(minutesOffset: number): string {
  return new Date(baseTime.getTime() + minutesOffset * 60 * 1000).toISOString();
}

export const INITIAL_DEMO_USERS: Record<string, User> = {
  "user-organizer-1": {
    uid: "user-organizer-1",
    name: "Alex Rivera",
    email: "alex@technova.io",
    role: "organizer",
    createdAt: Date.now() - 86400000,
  },
  "user-anchor-1": {
    uid: "user-anchor-1",
    name: "Jordan Hayes",
    email: "jordan@stageflow.io",
    role: "anchor",
    createdAt: Date.now() - 86400000,
  },
};

export const INITIAL_DEMO_EVENT: EventData = {
  id: "technova-2026",
  name: "TechNova 2026 — AI Innovation Summit",
  type: "Flagship AI Conference",
  date: "2026-09-19",
  venue: "Main Auditorium, Hall A",
  tone: "Visionary, Energetic & Polished",
  description: "Global summit exploring autonomous agents, deterministic real-time systems, and human-in-the-loop co-pilots.",
  ownerId: "user-organizer-1",
  joinCode: "TN26",
  anchorIds: ["user-anchor-1"],
  liveState: {
    status: "draft",
    currentItemId: null,
    startedAt: null,
    totalDelayMin: 0,
  },
  createdAt: Date.now() - 86400000,
};

export const INITIAL_DEMO_SPEAKERS: Record<string, Speaker> = {
  "spk-1": {
    id: "spk-1",
    name: "Dr. Aris Vance",
    designation: "VP of Applied AI",
    organization: "DeepScale Labs",
    topic: "Autonomous Agents in High-Stakes Operations",
    bio: "Pioneer in deterministic reasoning and mission-critical AI co-pilots.",
    highlights: ["Former Head of Research at AI Frontier", "Author of 'Deterministic Co-Pilots'"],
    photoUrl: "https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=300&h=300&fit=crop",
    status: "arrived",
  },
  "spk-2": {
    id: "spk-2",
    name: "Priya Sharma",
    designation: "Head of Distributed Systems",
    organization: "QuantumCloud",
    topic: "Sub-Millisecond Inference at Hyperscale",
    bio: "Leads edge inference architecture serving 10M+ concurrent enterprise events.",
    highlights: ["ACM Distinguished Engineer", "Keynote speaker at CloudNext"],
    photoUrl: "https://images.unsplash.com/photo-1573496359142-b8d87734a5a2?w=300&h=300&fit=crop",
    status: "arrived",
  },
  "spk-3": {
    id: "spk-3",
    name: "Marcus Chen",
    designation: "Chief Architect",
    organization: "NeuralMesh",
    topic: "Deterministic AI Workflows for Live Production",
    bio: "Specializes in fail-safe orchestration and multi-agent coordination.",
    highlights: ["Creator of MeshFlow", "Top 40 under 40 Tech Innovators"],
    photoUrl: "https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=300&h=300&fit=crop",
    status: "expected",
  },
  "spk-4": {
    id: "spk-4",
    name: "Sarah Jenkins",
    designation: "Director of Product Experience",
    organization: "SynthLogic",
    topic: "Human-in-the-Loop Co-Pilots for High-Pressure Stages",
    bio: "Expert in real-time UI/UX design for live broadcasters and controllers.",
    highlights: ["Designed NASA Mission Control UI overhaul", "Stanford HCI Alum"],
    photoUrl: "https://images.unsplash.com/photo-1580489944761-15a19d654956?w=300&h=300&fit=crop",
    status: "arrived",
  },
};

export const INITIAL_DEMO_AGENDA: Record<string, AgendaItem> = {
  "item-1": {
    id: "item-1",
    order: 1,
    title: "Summit Opening & Housekeeping",
    type: "opening",
    speakerIds: [],
    duration: 15,
    plannedStart: makeIso(0),
    startTime: makeIso(0),
    endTime: makeIso(15),
    status: "upcoming",
    absorbable: false,
    notes: "Welcoming 800+ attendees and establishing the vision.",
  },
  "item-2": {
    id: "item-2",
    order: 2,
    title: "Keynote: Autonomous Agents in High-Stakes Operations",
    type: "keynote",
    speakerIds: ["spk-1"],
    duration: 40,
    plannedStart: makeIso(15),
    startTime: makeIso(15),
    endTime: makeIso(55),
    status: "upcoming",
    absorbable: false,
    notes: "Signature keynote followed by a 5-min audience Q&A.",
  },
  "item-3": {
    id: "item-3",
    order: 3,
    title: "Networking & Interactive Tea Break",
    type: "break",
    speakerIds: [],
    duration: 30,
    plannedStart: makeIso(55),
    startTime: makeIso(55),
    endTime: makeIso(85),
    status: "upcoming",
    absorbable: true,
    minDuration: 15,
    notes: "Designed with 15-minute buffer capacity to absorb morning delays.",
  },
  "item-4": {
    id: "item-4",
    order: 4,
    title: "Deep-Dive: Sub-Millisecond Inference at Hyperscale",
    type: "talk",
    speakerIds: ["spk-2"],
    duration: 35,
    plannedStart: makeIso(85),
    startTime: makeIso(85),
    endTime: makeIso(120),
    status: "upcoming",
    absorbable: false,
    notes: "Live demo of multi-region edge clusters.",
  },
  "item-5": {
    id: "item-5",
    order: 5,
    title: "Architecture: Deterministic AI Workflows for Live Production",
    type: "talk",
    speakerIds: ["spk-3"],
    duration: 35,
    plannedStart: makeIso(120),
    startTime: makeIso(120),
    endTime: makeIso(155),
    status: "upcoming",
    absorbable: false,
  },
  "item-6": {
    id: "item-6",
    order: 6,
    title: "Executive Panel: Human-in-the-Loop Co-Pilots",
    type: "panel",
    speakerIds: ["spk-1", "spk-2", "spk-3", "spk-4"],
    duration: 45,
    plannedStart: makeIso(155),
    startTime: makeIso(155),
    endTime: makeIso(200),
    status: "upcoming",
    absorbable: false,
  },
  "item-7": {
    id: "item-7",
    order: 7,
    title: "Summit Closing Ceremony & Showcase",
    type: "closing",
    speakerIds: [],
    duration: 15,
    plannedStart: makeIso(200),
    startTime: makeIso(200),
    endTime: makeIso(215),
    status: "upcoming",
    absorbable: false,
  },
};

export class MemoryStore {
  private state: EventStoreState = {
    users: { ...INITIAL_DEMO_USERS },
    events: { "technova-2026": { ...INITIAL_DEMO_EVENT } },
    speakers: { "technova-2026": { ...INITIAL_DEMO_SPEAKERS } },
    agenda: { "technova-2026": { ...INITIAL_DEMO_AGENDA } },
    notifications: { "technova-2026": [] },
    scripts: { "technova-2026": [] },
  };

  private listeners: Set<() => void> = new Set();

  getState(): EventStoreState {
    return this.state;
  }

  getEvents(): EventData[] {
    return Object.values(this.state.events);
  }

  getEvent(id: string): EventData | null {
    return this.state.events[id] || null;
  }

  getEventByJoinCode(code: string): EventData | null {
    return (
      Object.values(this.state.events).find(
        (e) => e.joinCode.toUpperCase() === code.toUpperCase()
      ) || null
    );
  }

  createEvent(event: EventData): EventData {
    this.state.events[event.id] = event;
    if (!this.state.agenda[event.id]) this.state.agenda[event.id] = {};
    if (!this.state.speakers[event.id]) this.state.speakers[event.id] = {};
    if (!this.state.notifications[event.id]) this.state.notifications[event.id] = [];
    if (!this.state.scripts[event.id]) this.state.scripts[event.id] = [];
    this.notify();
    return event;
  }

  updateEvent(id: string, updates: Partial<EventData>): EventData | null {
    if (!this.state.events[id]) return null;
    this.state.events[id] = { ...this.state.events[id], ...updates };
    this.notify();
    return this.state.events[id];
  }

  getAgenda(eventId: string): AgendaItem[] {
    const map = this.state.agenda[eventId] || {};
    return Object.values(map).sort((a, b) => a.order - b.order);
  }

  addAgendaItem(eventId: string, item: AgendaItem): AgendaItem {
    if (!this.state.agenda[eventId]) this.state.agenda[eventId] = {};
    this.state.agenda[eventId][item.id] = item;
    this.notify();
    return item;
  }

  updateAgendaItem(eventId: string, itemId: string, updates: Partial<AgendaItem>): AgendaItem | null {
    if (!this.state.agenda[eventId] || !this.state.agenda[eventId][itemId]) return null;
    this.state.agenda[eventId][itemId] = { ...this.state.agenda[eventId][itemId], ...updates };
    this.notify();
    return this.state.agenda[eventId][itemId];
  }

  batchUpdateAgenda(eventId: string, items: AgendaItem[]): void {
    if (!this.state.agenda[eventId]) this.state.agenda[eventId] = {};
    for (const it of items) {
      this.state.agenda[eventId][it.id] = { ...it };
    }
    this.notify();
  }

  getSpeakers(eventId: string): Speaker[] {
    const map = this.state.speakers[eventId] || {};
    return Object.values(map);
  }

  addSpeaker(eventId: string, speaker: Speaker): Speaker {
    if (!this.state.speakers[eventId]) this.state.speakers[eventId] = {};
    this.state.speakers[eventId][speaker.id] = speaker;
    this.notify();
    return speaker;
  }

  updateSpeaker(eventId: string, speakerId: string, updates: Partial<Speaker>): Speaker | null {
    if (!this.state.speakers[eventId] || !this.state.speakers[eventId][speakerId]) return null;
    this.state.speakers[eventId][speakerId] = { ...this.state.speakers[eventId][speakerId], ...updates };
    this.notify();
    return this.state.speakers[eventId][speakerId];
  }

  getNotifications(eventId: string): EventNotification[] {
    return this.state.notifications[eventId] || [];
  }

  addNotification(eventId: string, notif: EventNotification): void {
    if (!this.state.notifications[eventId]) this.state.notifications[eventId] = [];
    this.state.notifications[eventId].unshift(notif);
    this.notify();
  }

  getScripts(eventId: string): Script[] {
    return this.state.scripts[eventId] || [];
  }

  addScript(eventId: string, script: Script): void {
    if (!this.state.scripts[eventId]) this.state.scripts[eventId] = [];
    this.state.scripts[eventId].unshift(script);
    this.notify();
  }

  subscribe(listener: () => void): () => void {
    this.listeners.add(listener);
    return () => {
      this.listeners.delete(listener);
    };
  }

  private notify(): void {
    for (const l of this.listeners) {
      try {
        l();
      } catch (e) {
        console.error(e);
      }
    }
  }
}

export const memoryStore = new MemoryStore();
