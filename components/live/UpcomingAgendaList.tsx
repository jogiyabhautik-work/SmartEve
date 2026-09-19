"use client";

import React, { useState } from "react";
import { AgendaItem } from "@/types/agenda";
import { Speaker } from "@/types/speaker";
import { Badge } from "@/components/ui/badge";
import { formatTimeDisplay } from "@/lib/time";
import { Clock, ShieldCheck, ArrowRight, XCircle, AlertCircle } from "lucide-react";
import { broadcastStateChange } from "@/lib/syncClient";
import { notify } from "@/components/ui/toast";

export interface UpcomingAgendaListProps {
  eventId: string;
  nextItem: AgendaItem | null;
  upcomingItems: AgendaItem[];
  speakers: Speaker[];
}

export function UpcomingAgendaList({
  eventId,
  nextItem,
  upcomingItems,
  speakers,
}: UpcomingAgendaListProps) {
  const [cancellingId, setCancellingId] = useState<string | null>(null);

  const handleCancelItem = async (itemId: string, title: string) => {
    if (!confirm(`Cancel "${title}"? Subsequent sessions will automatically pull forward.`)) {
      return;
    }

    setCancellingId(itemId);
    try {
      const res = await fetch(`/api/events/${eventId}/cancel-item`, {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({ itemId }),
      });
      const data = await res.json();
      if (data.success) {
        broadcastStateChange("item_cancelled", { itemId });
        notify({
          type: "warning",
          message: `Cancelled "${title}". Schedule pulled forward!`,
        });
      } else {
        notify({ type: "error", message: data.error?.message || "Failed to cancel session" });
      }
    } catch (e) {
      notify({ type: "error", message: "Network error cancelling session" });
    } finally {
      setCancellingId(null);
    }
  };

  return (
    <div className="bg-surface border border-surface-border rounded-2xl p-6 shadow-xl flex flex-col h-full">
      {/* Header */}
      <div className="flex items-center justify-between mb-4">
        <div>
          <h3 className="text-base font-bold text-white leading-none">Upcoming Flow</h3>
          <span className="text-xs text-slate-400">Deterministic Live Reflow</span>
        </div>
        <span className="text-xs font-mono text-slate-400">
          {upcomingItems.length} remaining
        </span>
      </div>

      {/* Next Up Spotlight Card */}
      {nextItem && (
        <div className="p-4 rounded-xl bg-gradient-to-r from-primary/20 via-surface-light to-surface-light border border-primary/30 mb-4 shadow-md">
          <div className="flex items-center justify-between mb-1.5">
            <span className="text-[11px] font-mono uppercase font-bold text-primary-light flex items-center gap-1.5">
              <ArrowRight className="w-3.5 h-3.5" />
              NEXT UP
            </span>
            <span className="text-xs font-mono text-white font-semibold">
              {formatTimeDisplay(nextItem.startTime)}
            </span>
          </div>

          <div className="text-sm font-bold text-white truncate mb-1">{nextItem.title}</div>

          {/* Associated speaker */}
          {(() => {
            const spk = speakers.find((s) => nextItem.speakerIds.includes(s.id));
            if (!spk) return null;
            return (
              <div className="text-xs text-slate-300 truncate">
                {spk.name} · <span className="text-slate-400">{spk.organization}</span>
              </div>
            );
          })()}

          <div className="flex items-center gap-2 mt-2 pt-2 border-t border-surface-border/50 text-[11px] text-slate-400 font-mono">
            <span>Duration: {nextItem.duration}m</span>
            <span>·</span>
            <span className="capitalize">{nextItem.type}</span>
          </div>
        </div>
      )}

      {/* Scrollable list of remaining sessions */}
      <div className="flex-1 overflow-y-auto space-y-2.5 pr-1 max-h-[360px]">
        {upcomingItems.length === 0 ? (
          <div className="text-center py-8 text-xs text-slate-500">No further sessions scheduled</div>
        ) : (
          upcomingItems.map((item, idx) => {
            const isNext = nextItem?.id === item.id;
            if (isNext) return null; // Already rendered in spotlight

            const spk = speakers.find((s) => item.speakerIds.includes(s.id));

            return (
              <div
                key={item.id}
                className="p-3 rounded-xl bg-surface-light/50 border border-surface-border hover:border-slate-600 transition-colors group relative"
              >
                <div className="flex items-start justify-between gap-2">
                  <div className="min-w-0 flex-1">
                    <div className="flex items-center gap-2 mb-1">
                      <span className="text-[11px] font-mono text-slate-400">
                        {formatTimeDisplay(item.startTime)}
                      </span>

                      {/* Absorbable break tag */}
                      {item.absorbable && (
                        <span className="inline-flex items-center gap-1 text-[10px] font-mono font-medium px-1.5 py-0.2 rounded bg-amber-500/15 text-amber-300 border border-amber-500/30">
                          <ShieldCheck className="w-3 h-3" />
                          Absorbing Buffer (min {item.minDuration || 15}m)
                        </span>
                      )}

                      {/* Hard Start tag */}
                      {item.hardStart && (
                        <span className="inline-flex items-center gap-1 text-[10px] font-mono font-medium px-1.5 py-0.2 rounded bg-rose-500/15 text-rose-300 border border-rose-500/30">
                          <AlertCircle className="w-3 h-3" />
                          Fixed Hard Start
                        </span>
                      )}
                    </div>

                    <div className="text-xs font-semibold text-slate-200 truncate group-hover:text-white">
                      {item.title}
                    </div>

                    {spk && (
                      <div className="text-[11px] text-slate-400 truncate">
                        {spk.name} ({spk.organization})
                      </div>
                    )}
                  </div>

                  {/* Duration pill & cancel trigger */}
                  <div className="flex items-center gap-1.5 shrink-0">
                    <span className="text-[11px] font-mono text-slate-400 px-1.5 py-0.5 rounded bg-surface-border">
                      {item.duration}m
                    </span>

                    <button
                      onClick={() => handleCancelItem(item.id, item.title)}
                      disabled={cancellingId === item.id}
                      className="opacity-0 group-hover:opacity-100 text-slate-500 hover:text-rose-400 p-1 rounded transition-opacity"
                      title="Cancel session"
                    >
                      <XCircle className="w-4 h-4" />
                    </button>
                  </div>
                </div>
              </div>
            );
          })
        )}
      </div>
    </div>
  );
}
