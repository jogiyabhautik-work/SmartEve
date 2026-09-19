"use client";

import { useEffect, useState, useMemo } from "react";
import { AgendaItem } from "@/types/agenda";
import { EventData } from "@/types/event";
import { formatCountdown, getRemainingSeconds, calculateProgress } from "@/lib/time";
import { useServerOffset } from "./useServerOffset";

export function useLiveState(event: EventData | null, agenda: AgendaItem[]) {
  const serverOffset = useServerOffset();
  const [nowMs, setNowMs] = useState(Date.now());

  // Derive current and next items
  const currentItem = useMemo(() => {
    if (!event || !agenda || agenda.length === 0) return null;
    if (event.liveState.currentItemId) {
      const found = agenda.find((it) => it.id === event.liveState.currentItemId);
      if (found) return found;
    }
    return agenda.find((it) => it.status === "live") || null;
  }, [event, agenda]);

  const nextItem = useMemo(() => {
    if (!currentItem || !agenda) return null;
    const currentIndex = agenda.findIndex((it) => it.id === currentItem.id);
    if (currentIndex === -1) return null;

    for (let i = currentIndex + 1; i < agenda.length; i++) {
      if (agenda[i].status !== "cancelled" && agenda[i].status !== "skipped") {
        return agenda[i];
      }
    }
    return null;
  }, [currentItem, agenda]);

  const upcomingItems = useMemo(() => {
    if (!currentItem || !agenda) return [];
    const currentIndex = agenda.findIndex((it) => it.id === currentItem.id);
    return agenda.slice(currentIndex + 1).filter((it) => it.status !== "cancelled");
  }, [currentItem, agenda]);

  // High-precision derived timer
  useEffect(() => {
    const timer = setInterval(() => {
      setNowMs(Date.now() + serverOffset);
    }, 1000);

    return () => clearInterval(timer);
  }, [serverOffset]);

  const remainingSeconds = useMemo(() => {
    if (!currentItem) return 0;
    return getRemainingSeconds(currentItem.endTime, nowMs);
  }, [currentItem, nowMs]);

  const timerDisplay = useMemo(() => {
    return formatCountdown(remainingSeconds);
  }, [remainingSeconds]);

  const progressPercent = useMemo(() => {
    if (!currentItem) return 0;
    return calculateProgress(currentItem.startTime, currentItem.endTime, nowMs);
  }, [currentItem, nowMs]);

  // Overall schedule health: ON TIME, +X MIN BEHIND, AHEAD
  const scheduleStatus = useMemo(() => {
    const totalDelay = event?.liveState.totalDelayMin || 0;
    if (totalDelay > 0) {
      return { label: `+${totalDelay} MIN BEHIND`, color: "amber" as const, delayMin: totalDelay };
    }
    if (totalDelay < 0) {
      return { label: `${Math.abs(totalDelay)} MIN AHEAD`, color: "indigo" as const, delayMin: totalDelay };
    }
    return { label: "ON TIME", color: "emerald" as const, delayMin: 0 };
  }, [event]);

  // Elapsed time since summit started
  const elapsedMinutes = useMemo(() => {
    if (!event?.liveState.startedAt) return 0;
    return Math.max(0, Math.floor((nowMs - event.liveState.startedAt) / (60 * 1000)));
  }, [event?.liveState.startedAt, nowMs]);

  return {
    currentItem,
    nextItem,
    upcomingItems,
    remainingSeconds,
    timerDisplay,
    progressPercent,
    scheduleStatus,
    elapsedMinutes,
  };
}
