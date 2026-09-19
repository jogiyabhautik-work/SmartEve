"use client";

import React, { useState } from "react";
import { AgendaItem } from "@/types/agenda";
import { Speaker } from "@/types/speaker";
import { TimerDisplay } from "./TimerDisplay";
import { Button } from "@/components/ui/button";
import { Badge } from "@/components/ui/badge";
import { formatTimeDisplay } from "@/lib/time";
import { CheckCircle2, Clock, PlusCircle, User, Sparkles, AlertCircle } from "lucide-react";
import { broadcastStateChange } from "@/lib/syncClient";
import { notify } from "@/components/ui/toast";

export interface CurrentSessionCardProps {
  item: AgendaItem | null;
  speakers: Speaker[];
  timerDisplay: {
    formatted: string;
    isOvertime: boolean;
    minutes: number;
    remainingSeconds: number;
  };
  progressPercent: number;
  eventId: string;
  onOpenDelayModal: () => void;
  onOpenAnnounceModal: () => void;
}

export function CurrentSessionCard({
  item,
  speakers,
  timerDisplay,
  progressPercent,
  eventId,
  onOpenDelayModal,
  onOpenAnnounceModal,
}: CurrentSessionCardProps) {
  const [completing, setCompleting] = useState(false);
  const [quickDelaying, setQuickDelaying] = useState(false);

  if (!item) {
    return (
      <div className="bg-surface border border-surface-border rounded-2xl p-8 text-center flex flex-col items-center justify-center min-h-[400px]">
        <Clock className="w-12 h-12 text-slate-500 mb-3" />
        <h3 className="text-xl font-bold text-white mb-2">No Active Session</h3>
        <p className="text-slate-400 text-sm max-w-md mb-6">
          The event is not currently live, or all scheduled sessions have concluded.
        </p>
      </div>
    );
  }

  // Find associated speaker
  const currentSpeaker = speakers.find((s) => item.speakerIds.includes(s.id));

  const handleComplete = async () => {
    setCompleting(true);
    try {
      const res = await fetch(`/api/events/${eventId}/complete-current`, {
        method: "POST",
      });
      const data = await res.json();
      if (data.success) {
        broadcastStateChange("complete_current", { itemId: item.id });
        notify({
          type: "success",
          message: `Completed "${item.title}"! Schedule progressed.`,
        });
      } else {
        notify({
          type: "error",
          message: data.error?.message || "Failed to mark session complete",
        });
      }
    } catch (e) {
      notify({ type: "error", message: "Network error completing session" });
    } finally {
      setCompleting(false);
    }
  };

  const handleQuickDelay = async (minutes: number) => {
    setQuickDelaying(true);
    try {
      const res = await fetch(`/api/events/${eventId}/delay`, {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({ delayMinutes: minutes, targetItemId: item.id }),
      });
      const data = await res.json();
      if (data.success) {
        broadcastStateChange("delay_added", { minutes });
        notify({
          type: "warning",
          message: `Added +${minutes} min delay! Reflow engine adjusted schedule.`,
        });
      } else {
        notify({
          type: "error",
          message: data.error?.message || "Failed to apply delay",
        });
      }
    } catch (e) {
      notify({ type: "error", message: "Network error applying delay" });
    } finally {
      setQuickDelaying(false);
    }
  };

  return (
    <div className="bg-surface border border-surface-border rounded-2xl p-6 shadow-xl flex flex-col justify-between relative overflow-hidden">
      {/* Glow highlight */}
      <div className="absolute -top-24 -left-24 w-48 h-48 bg-emerald-500/10 rounded-full blur-3xl pointer-events-none" />

      {/* Header */}
      <div>
        <div className="flex items-center justify-between gap-3 mb-4">
          <Badge variant="live" pulse={true}>
            NOW ON STAGE
          </Badge>
          <div className="text-xs font-mono text-slate-400">
            {formatTimeDisplay(item.startTime)} – {formatTimeDisplay(item.endTime)}
          </div>
        </div>

        <h2 className="text-2xl font-bold text-white tracking-tight leading-snug mb-3">
          {item.title}
        </h2>

        {/* Speaker Card if assigned */}
        {currentSpeaker ? (
          <div className="flex items-center gap-3.5 p-3 rounded-xl bg-surface-light/70 border border-surface-border mb-6">
            {currentSpeaker.photoUrl ? (
              <img
                src={currentSpeaker.photoUrl}
                alt={currentSpeaker.name}
                className="w-12 h-12 rounded-xl object-cover border border-surface-border shrink-0"
              />
            ) : (
              <div className="w-12 h-12 rounded-xl bg-surface-border flex items-center justify-center shrink-0">
                <User className="w-6 h-6 text-slate-400" />
              </div>
            )}
            <div className="min-w-0">
              <div className="text-sm font-semibold text-white truncate">{currentSpeaker.name}</div>
              <div className="text-xs text-slate-400 truncate">
                {currentSpeaker.designation} · {currentSpeaker.organization}
              </div>
              {currentSpeaker.topic && (
                <div className="text-[11px] text-indigo-400 font-medium truncate mt-0.5">
                  &ldquo;{currentSpeaker.topic}&rdquo;
                </div>
              )}
            </div>
          </div>
        ) : (
          <div className="p-3 rounded-xl bg-surface-light/40 border border-surface-border mb-6 text-xs text-slate-400">
            Category: <span className="font-semibold text-slate-300 capitalize">{item.type}</span> · Planned Duration: {item.duration}m
          </div>
        )}

        {/* Prominent Timer */}
        <div className="mb-6">
          <TimerDisplay
            formatted={timerDisplay.formatted}
            isOvertime={timerDisplay.isOvertime}
            minutes={timerDisplay.minutes}
            remainingSeconds={timerDisplay.remainingSeconds}
            progressPercent={progressPercent}
            size="default"
          />
        </div>
      </div>

      {/* Control Actions */}
      <div className="space-y-3 pt-2 border-t border-surface-border">
        {/* Complete Session Button */}
        <Button
          variant="live"
          size="touch"
          className="w-full text-base font-bold shadow-emerald-500/20"
          onClick={handleComplete}
          isLoading={completing}
        >
          <CheckCircle2 className="w-5 h-5 mr-2" />
          MARK SESSION COMPLETE
        </Button>

        {/* Delay and Announce Quick Actions */}
        <div className="grid grid-cols-2 gap-2.5">
          <Button
            variant="amber"
            size="md"
            className="w-full text-xs"
            onClick={() => handleQuickDelay(15)}
            isLoading={quickDelaying}
          >
            <PlusCircle className="w-4 h-4 mr-1.5" />
            +15 MIN DELAY
          </Button>

          <Button
            variant="secondary"
            size="md"
            className="w-full text-xs"
            onClick={onOpenDelayModal}
          >
            Custom Delay / Shift...
          </Button>
        </div>
      </div>
    </div>
  );
}
