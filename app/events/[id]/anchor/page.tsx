"use client";

import React, { use, useState, useEffect } from "react";
import { useEvent } from "@/hooks/useEvent";
import { useAgenda } from "@/hooks/useAgenda";
import { useLiveState } from "@/hooks/useLiveState";
import { useNotifications } from "@/hooks/useNotifications";
import { subscribeToSpeakers } from "@/lib/syncClient";
import { Speaker } from "@/types/speaker";
import { AnchorMobileView } from "@/components/anchor/AnchorMobileView";
import { Skeleton } from "@/components/ui/skeleton";

export default function AnchorPage({ params }: { params: Promise<{ id: string }> }) {
  const { id } = use(params);
  const { event, loading: eventLoading } = useEvent(id);
  const { agenda, loading: agendaLoading } = useAgenda(id);
  const { notifications } = useNotifications(id);
  const [speakers, setSpeakers] = useState<Speaker[]>([]);

  useEffect(() => {
    const unsub = subscribeToSpeakers(id, (spks) => setSpeakers(spks));
    return () => unsub();
  }, [id]);

  const { currentItem, nextItem, timerDisplay, progressPercent } = useLiveState(event, agenda);

  if (eventLoading || agendaLoading || !event) {
    return (
      <div className="min-h-screen bg-background text-slate-100 p-4 max-w-lg mx-auto flex flex-col justify-center space-y-4">
        <Skeleton className="h-10 w-full rounded-xl" />
        <Skeleton className="h-64 w-full rounded-2xl" />
        <Skeleton className="h-40 w-full rounded-2xl" />
      </div>
    );
  }

  return (
    <AnchorMobileView
      event={event}
      currentItem={currentItem}
      nextItem={nextItem}
      speakers={speakers}
      notifications={notifications}
      timerDisplay={timerDisplay}
      progressPercent={progressPercent}
    />
  );
}
