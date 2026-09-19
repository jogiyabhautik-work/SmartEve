"use client";

import React, { useEffect, useState, useMemo } from "react";
import { EventData } from "@/types/event";
import { AgendaItem } from "@/types/agenda";
import { Speaker } from "@/types/speaker";
import { EventNotification } from "@/types/notification";
import { formatTimeDisplay, formatCountdown, getRemainingSeconds } from "@/lib/time";
import { Radio, AlertTriangle, ArrowRight, Clock, Tv } from "lucide-react";
import { Badge } from "@/components/ui/badge";

export interface ProjectorDisplayProps {
  event: EventData;
  agenda: AgendaItem[];
  speakers: Speaker[];
  notifications: EventNotification[];
}

export function ProjectorDisplay({
  event,
  agenda,
  speakers,
  notifications,
}: ProjectorDisplayProps) {
  const [nowMs, setNowMs] = useState(Date.now());

  useEffect(() => {
    const timer = setInterval(() => setNowMs(Date.now()), 1000);
    return () => clearInterval(timer);
  }, []);

  // Derive current, next, and upcoming
  const currentItem = useMemo(() => {
    if (event.liveState.currentItemId) {
      const found = agenda.find((it) => it.id === event.liveState.currentItemId);
      if (found) return found;
    }
    return agenda.find((it) => it.status === "live") || agenda[0] || null;
  }, [event, agenda]);

  const currentIndex = currentItem ? agenda.findIndex((it) => it.id === currentItem.id) : -1;

  const nextItem = useMemo(() => {
    if (currentIndex === -1) return null;
    return agenda.slice(currentIndex + 1).find((it) => it.status !== "cancelled") || null;
  }, [agenda, currentIndex]);

  const upcomingSessions = useMemo(() => {
    if (currentIndex === -1) return [];
    return agenda
      .slice(currentIndex + 1)
      .filter((it) => it.status !== "cancelled")
      .slice(0, 4);
  }, [agenda, currentIndex]);

  const currentSpeaker = currentItem
    ? speakers.find((s) => currentItem.speakerIds.includes(s.id))
    : null;

  // Countdown calculation
  const remainingSec = currentItem ? getRemainingSeconds(currentItem.endTime, nowMs) : 0;
  const countdown = formatCountdown(remainingSec);

  // Active delay or announcement banner
  const activeAlert = notifications.find(
    (n) => (n.type === "delay" || n.type === "announcement") && Date.now() - n.createdAt < 10 * 60 * 1000
  );

  return (
    <div className="min-h-screen bg-[#070B18] text-white p-6 md:p-12 flex flex-col justify-between select-none">
      {/* Top Banner: Event Name & Live Pulse */}
      <header className="flex items-center justify-between border-b border-slate-800 pb-6">
        <div className="flex items-center gap-4">
          <div className="w-12 h-12 rounded-2xl bg-primary/20 border border-primary/40 flex items-center justify-center">
            <Tv className="w-6 h-6 text-primary-light" />
          </div>
          <div>
            <h1 className="text-3xl md:text-4xl font-black tracking-tight text-white uppercase">
              {event.name}
            </h1>
            <div className="text-sm font-mono text-slate-400 mt-0.5">
              {event.venue} · CODE: <span className="font-bold text-primary-light">{event.joinCode}</span>
            </div>
          </div>
        </div>

        <div className="flex items-center gap-4">
          {event.liveState.totalDelayMin !== 0 && (
            <div className="px-4 py-2 rounded-xl bg-amber-500/20 border border-amber-500/40 text-amber-300 font-mono text-base font-bold">
              {event.liveState.totalDelayMin > 0 ? `+${event.liveState.totalDelayMin} MIN DELAY` : `${event.liveState.totalDelayMin} MIN`}
            </div>
          )}

          <div className="flex items-center gap-2.5 px-4 py-2 rounded-xl bg-emerald-500/15 border border-emerald-500/30 text-emerald-400 font-mono font-bold text-sm tracking-wider">
            <span className="w-2.5 h-2.5 rounded-full bg-emerald-400 animate-ping" />
            STAGE ON AIR
          </div>
        </div>
      </header>

      {/* Broadcast Alert Ticker if active */}
      {activeAlert && (
        <div className="my-6 p-4 rounded-2xl bg-amber-500/15 border-2 border-amber-500 text-amber-100 flex items-center gap-4 animate-pulse">
          <AlertTriangle className="w-8 h-8 text-amber-400 shrink-0" />
          <div className="text-xl md:text-2xl font-bold tracking-wide">
            {activeAlert.message}
          </div>
        </div>
      )}

      {/* Main Grid: NOW ON STAGE vs TIMER */}
      <main className="grid grid-cols-1 lg:grid-cols-12 gap-8 my-auto py-8">
        {/* NOW ON STAGE (Left 7 Cols) */}
        <div className="lg:col-span-7 flex flex-col justify-center space-y-6">
          <div className="inline-flex items-center gap-2 px-3.5 py-1.5 rounded-lg bg-emerald-500/20 text-emerald-300 font-mono text-sm font-bold tracking-widest uppercase border border-emerald-500/30 w-fit">
            <span className="w-2 h-2 rounded-full bg-emerald-400" />
            NOW ON STAGE
          </div>

          <h2 className="text-4xl md:text-6xl font-black text-white leading-tight tracking-tight">
            {currentItem ? currentItem.title : "Summit Transition"}
          </h2>

          {currentSpeaker ? (
            <div className="flex items-center gap-5 p-6 rounded-3xl bg-surface/90 border border-surface-border">
              {currentSpeaker.photoUrl && (
                <img
                  src={currentSpeaker.photoUrl}
                  alt={currentSpeaker.name}
                  className="w-20 h-20 rounded-2xl object-cover border-2 border-primary/40 shadow-xl"
                />
              )}
              <div>
                <div className="text-2xl md:text-3xl font-extrabold text-white">
                  {currentSpeaker.name}
                </div>
                <div className="text-lg text-slate-300 font-medium">
                  {currentSpeaker.designation} · <span className="text-primary-light">{currentSpeaker.organization}</span>
                </div>
              </div>
            </div>
          ) : (
            <div className="text-xl text-slate-400 font-mono">
              Session Window: {currentItem ? `${formatTimeDisplay(currentItem.startTime)} – ${formatTimeDisplay(currentItem.endTime)}` : "--"}
            </div>
          )}
        </div>

        {/* PROMINENT LIVE COUNTDOWN TIMER (Right 5 Cols) */}
        <div className="lg:col-span-5 flex flex-col items-center justify-center p-8 rounded-3xl bg-surface/90 border-2 border-surface-border shadow-2xl">
          <div className="text-base font-mono uppercase tracking-widest text-slate-400 mb-3 flex items-center gap-2">
            <Clock className="w-5 h-5" />
            {countdown.isOvertime ? (
              <span className="text-rose-400 font-bold">SESSION OVERTIME</span>
            ) : (
              "TIME REMAINING"
            )}
          </div>

          <div
            className={`font-mono tabular-nums text-7xl md:text-9xl font-black tracking-tight ${
              countdown.isOvertime
                ? "text-rose-400 animate-pulse"
                : countdown.minutes < 5
                ? "text-amber-400"
                : "text-emerald-400"
            }`}
          >
            {countdown.formatted}
          </div>

          <div className="text-sm font-mono text-slate-400 mt-4">
            Ends at {currentItem ? formatTimeDisplay(currentItem.endTime) : "--:--"}
          </div>
        </div>
      </main>

      {/* Bottom Row: NEXT & UPCOMING SCHEDULE */}
      <footer className="border-t border-slate-800 pt-6">
        <div className="grid grid-cols-1 md:grid-cols-4 gap-4">
          {upcomingSessions.map((session, idx) => {
            const isNext = idx === 0;
            const spk = speakers.find((s) => session.speakerIds.includes(s.id));

            return (
              <div
                key={session.id}
                className={`p-4 rounded-2xl border transition-all ${
                  isNext
                    ? "bg-primary/15 border-primary/40 shadow-lg shadow-primary/10"
                    : "bg-surface/40 border-surface-border"
                }`}
              >
                <div className="flex items-center justify-between text-xs font-mono mb-1.5">
                  <span
                    className={`font-bold uppercase tracking-wider ${
                      isNext ? "text-primary-light" : "text-slate-400"
                    }`}
                  >
                    {isNext ? "NEXT UP" : `SESSION +${idx + 1}`}
                  </span>
                  <span className="text-slate-300 font-semibold">
                    {formatTimeDisplay(session.startTime)}
                  </span>
                </div>

                <div className="text-base font-bold text-white truncate mb-1">
                  {session.title}
                </div>

                {spk && (
                  <div className="text-xs text-slate-400 truncate">
                    {spk.name} ({spk.organization})
                  </div>
                )}
              </div>
            );
          })}
        </div>
      </footer>
    </div>
  );
}
