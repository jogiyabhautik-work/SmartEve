"use client";

import React, { use, useState, useEffect } from "react";
import Link from "next/link";
import { Navbar } from "@/components/layout/Navbar";
import { CurrentSessionCard } from "@/components/live/CurrentSessionCard";
import { AnchorAssistPanel } from "@/components/live/AnchorAssistPanel";
import { UpcomingAgendaList } from "@/components/live/UpcomingAgendaList";
import { ChangesFeed } from "@/components/live/ChangesFeed";
import { DelayModal } from "@/components/live/DelayModal";
import { AnnounceModal } from "@/components/live/AnnounceModal";
import { useEvent } from "@/hooks/useEvent";
import { useAgenda } from "@/hooks/useAgenda";
import { useLiveState } from "@/hooks/useLiveState";
import { useNotifications } from "@/hooks/useNotifications";
import { subscribeToSpeakers } from "@/lib/syncClient";
import { Speaker } from "@/types/speaker";
import { Badge } from "@/components/ui/badge";
import { Button } from "@/components/ui/button";
import { Radio, Clock, ShieldCheck, Megaphone, Tv, Smartphone, AlertTriangle } from "lucide-react";
import { ControlRoomSkeleton } from "@/components/ui/skeleton";

export default function LiveControlRoomPage({ params }: { params: Promise<{ id: string }> }) {
  const { id } = use(params);
  const { event, loading: eventLoading } = useEvent(id);
  const { agenda, loading: agendaLoading } = useAgenda(id);
  const { notifications } = useNotifications(id);
  const [speakers, setSpeakers] = useState<Speaker[]>([]);

  const [delayModalOpen, setDelayModalOpen] = useState(false);
  const [announceModalOpen, setAnnounceModalOpen] = useState(false);

  useEffect(() => {
    const unsub = subscribeToSpeakers(id, (spks) => setSpeakers(spks));
    return () => unsub();
  }, [id]);

  const {
    currentItem,
    nextItem,
    upcomingItems,
    timerDisplay,
    progressPercent,
    scheduleStatus,
    elapsedMinutes,
  } = useLiveState(event, agenda);

  if (eventLoading || agendaLoading || !event) {
    return (
      <div className="min-h-screen bg-background text-slate-100 flex flex-col">
        <Navbar eventId={id} />
        <div className="max-w-7xl mx-auto px-4 py-8 w-full flex-1">
          <ControlRoomSkeleton />
        </div>
      </div>
    );
  }

  return (
    <div className="min-h-screen bg-background text-slate-100 flex flex-col justify-between">
      <Navbar eventId={id} joinCode={event.joinCode} />

      {/* Control Room Top Header */}
      <div className="bg-surface/60 border-b border-surface-border py-3 px-4 sm:px-6 lg:px-8 backdrop-blur-sm">
        <div className="max-w-7xl mx-auto flex flex-wrap items-center justify-between gap-4">
          {/* Summit Info & Live Indicator */}
          <div className="flex items-center gap-3">
            <Badge variant="live" pulse={true} className="text-xs py-1 px-3">
              LIVE AIR
            </Badge>
            <div>
              <h1 className="text-lg font-bold text-white leading-none">{event.name}</h1>
              <div className="text-xs text-slate-400 mt-0.5">
                {event.venue} · Code: <span className="font-bold text-white">{event.joinCode}</span>
              </div>
            </div>
          </div>

          {/* Schedule Status & Metrics */}
          <div className="flex items-center gap-3">
            {/* Elapsed Time */}
            <div className="hidden sm:flex items-center gap-1.5 px-3 py-1.5 rounded-xl bg-surface border border-surface-border text-xs text-slate-300 font-mono">
              <Clock className="w-3.5 h-3.5 text-slate-400" />
              <span>Elapsed: {elapsedMinutes}m</span>
            </div>

            {/* Schedule Status Badge */}
            <Badge
              variant={
                scheduleStatus.color === "amber"
                  ? "warning"
                  : scheduleStatus.color === "emerald"
                  ? "live"
                  : "primary"
              }
              className="text-xs py-1 px-3 font-mono font-bold"
            >
              {scheduleStatus.label}
            </Badge>

            {/* Stage & Broadcast Triggers */}
            <Button
              size="sm"
              variant="amber"
              onClick={() => setDelayModalOpen(true)}
              className="font-bold"
            >
              + Delay / Reflow
            </Button>

            <Button
              size="sm"
              variant="secondary"
              onClick={() => setAnnounceModalOpen(true)}
            >
              <Megaphone className="w-3.5 h-3.5 mr-1" />
              Announce
            </Button>

            <Link href={`/stage/${event.joinCode}`} target="_blank">
              <Button size="sm" variant="ghost" title="Open Stage Display">
                <Tv className="w-4 h-4" />
              </Button>
            </Link>

            <Link href={`/events/${id}/anchor`}>
              <Button size="sm" variant="ghost" title="Open Anchor Mobile View">
                <Smartphone className="w-4 h-4" />
              </Button>
            </Link>
          </div>
        </div>
      </div>

      {/* Main 3-Column Control Room Grid */}
      <main className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-6 flex-1 w-full space-y-6">
        <div className="grid grid-cols-1 lg:grid-cols-12 gap-6 items-stretch">
          {/* Column 1: CURRENT (4 cols) */}
          <div className="lg:col-span-4">
            <CurrentSessionCard
              item={currentItem}
              speakers={speakers}
              timerDisplay={timerDisplay}
              progressPercent={progressPercent}
              eventId={id}
              onOpenDelayModal={() => setDelayModalOpen(true)}
              onOpenAnnounceModal={() => setAnnounceModalOpen(true)}
            />
          </div>

          {/* Column 2: ANCHOR ASSIST (4 cols) */}
          <div className="lg:col-span-4">
            <AnchorAssistPanel
              eventId={id}
              currentItem={currentItem}
              nextItem={nextItem}
              speakers={speakers}
              totalDelayMin={event.liveState.totalDelayMin}
            />
          </div>

          {/* Column 3: UPCOMING AGENDA (4 cols) */}
          <div className="lg:col-span-4">
            <UpcomingAgendaList
              eventId={id}
              nextItem={nextItem}
              upcomingItems={upcomingItems}
              speakers={speakers}
            />
          </div>
        </div>

        {/* Bottom Changes Feed */}
        <ChangesFeed notifications={notifications} />
      </main>

      {/* Modals */}
      <DelayModal
        isOpen={delayModalOpen}
        onClose={() => setDelayModalOpen(false)}
        eventId={id}
        currentItemId={currentItem?.id}
      />

      <AnnounceModal
        isOpen={announceModalOpen}
        onClose={() => setAnnounceModalOpen(false)}
        eventId={id}
      />
    </div>
  );
}
