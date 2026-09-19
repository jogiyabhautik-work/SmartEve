"use client";

import { useEffect, useState } from "react";
import { EventData } from "@/types/event";
import { subscribeToEvent } from "@/lib/syncClient";

export function useEvent(eventId: string) {
  const [event, setEvent] = useState<EventData | null>(null);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    if (!eventId) {
      setLoading(false);
      return;
    }

    const unsubscribe = subscribeToEvent(eventId, (data) => {
      setEvent(data);
      setLoading(false);
    });

    return () => unsubscribe();
  }, [eventId]);

  return { event, loading };
}
