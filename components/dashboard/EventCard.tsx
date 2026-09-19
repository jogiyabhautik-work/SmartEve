"use client";

import React from "react";
import Link from "next/link";
import { EventData } from "@/types/event";
import { Badge } from "@/components/ui/badge";
import { Button } from "@/components/ui/button";
import { formatDateDisplay } from "@/lib/time";
import { Calendar, MapPin, Radio, Tv, Smartphone, ArrowRight, Play } from "lucide-react";

export function EventCard({
  event,
  onStart,
}: {
  event: EventData;
  onStart?: (id: string) => void;
}) {
  const isLive = event.liveState.status === "live";
  const isDraft = event.liveState.status === "draft";
  const isCompleted = event.liveState.status === "completed";

  return (
    <div className="bg-surface border border-surface-border hover:border-slate-600 rounded-2xl p-6 shadow-xl transition-all duration-200 flex flex-col justify-between group">
      <div>
        {/* Status Header */}
        <div className="flex items-center justify-between gap-3 mb-4">
          <div className="flex items-center gap-2">
            {isLive ? (
              <Badge variant="live" pulse={true}>
                LIVE NOW
              </Badge>
            ) : isCompleted ? (
              <Badge variant="neutral">COMPLETED</Badge>
            ) : (
              <Badge variant="primary">DRAFT / READY</Badge>
            )}

            {event.liveState.totalDelayMin !== 0 && (
              <Badge variant={event.liveState.totalDelayMin > 0 ? "warning" : "primary"}>
                {event.liveState.totalDelayMin > 0 ? `+${event.liveState.totalDelayMin}m Behind` : `${event.liveState.totalDelayMin}m Ahead`}
              </Badge>
            )}
          </div>

          <span className="text-xs font-mono text-slate-400 font-medium">
            CODE: <span className="text-white font-bold">{event.joinCode}</span>
          </span>
        </div>

        {/* Title & Type */}
        <h3 className="text-xl font-bold text-white tracking-tight group-hover:text-primary-light transition-colors mb-1.5">
          {event.name}
        </h3>
        <p className="text-xs text-slate-400 mb-4 line-clamp-2">{event.description || event.type}</p>

        {/* Date & Venue Metadata */}
        <div className="space-y-1.5 mb-6 text-xs text-slate-300">
          <div className="flex items-center gap-2">
            <Calendar className="w-3.5 h-3.5 text-slate-400 shrink-0" />
            <span>{formatDateDisplay(event.date)}</span>
          </div>
          <div className="flex items-center gap-2">
            <MapPin className="w-3.5 h-3.5 text-slate-400 shrink-0" />
            <span className="truncate">{event.venue}</span>
          </div>
        </div>
      </div>

      {/* Action Footer */}
      <div className="pt-4 border-t border-surface-border space-y-2.5">
        <div className="grid grid-cols-2 gap-2">
          {isLive ? (
            <Link href={`/events/${event.id}/live`} className="w-full">
              <Button variant="live" size="sm" className="w-full font-bold">
                <Radio className="w-3.5 h-3.5 mr-1.5 animate-pulse" />
                Live Room
              </Button>
            </Link>
          ) : (
            <Button
              variant="primary"
              size="sm"
              className="w-full font-bold"
              onClick={() => onStart?.(event.id)}
            >
              <Play className="w-3.5 h-3.5 mr-1.5" />
              Start Live
            </Button>
          )}

          <Link href={`/events/${event.id}`} className="w-full">
            <Button variant="secondary" size="sm" className="w-full">
              Manage / Setup
            </Button>
          </Link>
        </div>

        {/* Quick Links to Anchor and Stage */}
        <div className="flex items-center justify-between pt-2 text-[11px] text-slate-400 border-t border-surface-border/50">
          <Link
            href={`/events/${event.id}/anchor`}
            className="hover:text-indigo-300 flex items-center gap-1 transition-colors"
          >
            <Smartphone className="w-3 h-3" /> Anchor Screen
          </Link>
          <Link
            href={`/stage/${event.joinCode}`}
            target="_blank"
            className="hover:text-amber-300 flex items-center gap-1 transition-colors"
          >
            <Tv className="w-3 h-3" /> Stage Display
          </Link>
        </div>
      </div>
    </div>
  );
}
