"use client";

import { db, hasLiveFirebaseConfig } from "./firebase";
import { onSnapshot, doc, collection, query, orderBy } from "firebase/firestore";
import { EventData } from "@/types/event";
import { AgendaItem } from "@/types/agenda";
import { Speaker } from "@/types/speaker";
import { EventNotification } from "@/types/notification";
import { Script } from "@/types/script";
import {
  INITIAL_DEMO_EVENT,
  INITIAL_DEMO_AGENDA,
  INITIAL_DEMO_SPEAKERS,
} from "./store";

// Cross-tab broadcast channel for local instant synchronization
let channel: BroadcastChannel | null = null;
if (typeof window !== "undefined" && "BroadcastChannel" in window) {
  channel = new BroadcastChannel("smart_anchor_realtime_bus");
}

export function broadcastStateChange(action: string, payload?: any) {
  if (channel) {
    channel.postMessage({ action, payload, timestamp: Date.now() });
  }
}

// Local cache storage to persist state across refreshes in demo mode
const CACHE_PREFIX = "sa_state_";

function getLocal<T>(key: string, fallback: T): T {
  if (typeof window === "undefined") return fallback;
  try {
    const raw = localStorage.getItem(CACHE_PREFIX + key);
    return raw ? JSON.parse(raw) : fallback;
  } catch {
    return fallback;
  }
}

function setLocal<T>(key: string, val: T): void {
  if (typeof window === "undefined") return;
  try {
    localStorage.setItem(CACHE_PREFIX + key, JSON.stringify(val));
  } catch (e) {
    console.error("Local save error:", e);
  }
}

export function subscribeToEvent(eventId: string, callback: (event: EventData | null) => void) {
  if (hasLiveFirebaseConfig && db) {
    const docRef = doc(db, "events", eventId);
    return onSnapshot(docRef, (snap) => {
      if (snap.exists()) {
        callback({ id: snap.id, ...snap.data() } as EventData);
      } else {
        callback(null);
      }
    });
  }

  // Fallback / Demo Mode Realtime Sync
  const emit = () => {
    // Try fetching from local API first
    fetch(`/api/events/${eventId}`)
      .then((res) => res.json())
      .then((res) => {
        if (res.success && res.data) {
          setLocal(`event_${eventId}`, res.data);
          callback(res.data);
        } else {
          callback(getLocal(`event_${eventId}`, INITIAL_DEMO_EVENT));
        }
      })
      .catch(() => {
        callback(getLocal(`event_${eventId}`, INITIAL_DEMO_EVENT));
      });
  };

  emit();

  const handleMsg = () => emit();
  if (channel) channel.addEventListener("message", handleMsg);
  window.addEventListener("storage", handleMsg);

  return () => {
    if (channel) channel.removeEventListener("message", handleMsg);
    window.removeEventListener("storage", handleMsg);
  };
}

export function subscribeToAgenda(eventId: string, callback: (items: AgendaItem[]) => void) {
  if (hasLiveFirebaseConfig && db) {
    const colRef = collection(db, "events", eventId, "agenda");
    const q = query(colRef, orderBy("order", "asc"));
    return onSnapshot(q, (snap) => {
      const items = snap.docs.map((d) => ({ id: d.id, ...d.data() })) as AgendaItem[];
      callback(items);
    });
  }

  const emit = () => {
    fetch(`/api/events/${eventId}/agenda`)
      .then((res) => res.json())
      .then((res) => {
        if (res.success && res.data) {
          setLocal(`agenda_${eventId}`, res.data);
          callback(res.data);
        } else {
          callback(getLocal(`agenda_${eventId}`, Object.values(INITIAL_DEMO_AGENDA)));
        }
      })
      .catch(() => {
        callback(getLocal(`agenda_${eventId}`, Object.values(INITIAL_DEMO_AGENDA)));
      });
  };

  emit();

  const handleMsg = () => emit();
  if (channel) channel.addEventListener("message", handleMsg);
  window.addEventListener("storage", handleMsg);

  return () => {
    if (channel) channel.removeEventListener("message", handleMsg);
    window.removeEventListener("storage", handleMsg);
  };
}

export function subscribeToSpeakers(eventId: string, callback: (speakers: Speaker[]) => void) {
  if (hasLiveFirebaseConfig && db) {
    const colRef = collection(db, "events", eventId, "speakers");
    return onSnapshot(colRef, (snap) => {
      const spks = snap.docs.map((d) => ({ id: d.id, ...d.data() })) as Speaker[];
      callback(spks);
    });
  }

  const emit = () => {
    fetch(`/api/events/${eventId}/speakers`)
      .then((res) => res.json())
      .then((res) => {
        if (res.success && res.data) {
          callback(res.data);
        } else {
          callback(Object.values(INITIAL_DEMO_SPEAKERS));
        }
      })
      .catch(() => {
        callback(Object.values(INITIAL_DEMO_SPEAKERS));
      });
  };

  emit();

  const handleMsg = () => emit();
  if (channel) channel.addEventListener("message", handleMsg);

  return () => {
    if (channel) channel.removeEventListener("message", handleMsg);
  };
}

export function subscribeToNotifications(eventId: string, callback: (notifs: EventNotification[]) => void) {
  if (hasLiveFirebaseConfig && db) {
    const colRef = collection(db, "events", eventId, "notifications");
    const q = query(colRef, orderBy("createdAt", "desc"));
    return onSnapshot(q, (snap) => {
      const notifs = snap.docs.map((d) => ({ id: d.id, ...d.data() })) as EventNotification[];
      callback(notifs);
    });
  }

  const emit = () => {
    fetch(`/api/events/${eventId}/notifications`)
      .then((res) => res.json())
      .then((res) => {
        if (res.success && res.data) {
          callback(res.data);
        }
      })
      .catch(() => {});
  };

  emit();

  const handleMsg = () => emit();
  if (channel) channel.addEventListener("message", handleMsg);

  return () => {
    if (channel) channel.removeEventListener("message", handleMsg);
  };
}
