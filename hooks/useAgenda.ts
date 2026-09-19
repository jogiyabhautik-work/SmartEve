"use client";

import { useEffect, useState } from "react";
import { AgendaItem } from "@/types/agenda";
import { subscribeToAgenda } from "@/lib/syncClient";

export function useAgenda(eventId: string) {
  const [agenda, setAgenda] = useState<AgendaItem[]>([]);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    if (!eventId) {
      setLoading(false);
      return;
    }

    const unsubscribe = subscribeToAgenda(eventId, (items) => {
      setAgenda(items);
      setLoading(false);
    });

    return () => unsubscribe();
  }, [eventId]);

  return { agenda, loading };
}
