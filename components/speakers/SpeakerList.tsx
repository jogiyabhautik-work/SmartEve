"use client";

import React, { useState } from "react";
import { Speaker } from "@/types/speaker";
import { Badge } from "@/components/ui/badge";
import { Button } from "@/components/ui/button";
import { User, Plus, CheckCircle, Clock, AlertCircle } from "lucide-react";
import { SpeakerModal } from "./SpeakerModal";

export function SpeakerList({
  speakers,
  eventId,
  onRefresh,
}: {
  speakers: Speaker[];
  eventId: string;
  onRefresh?: () => void;
}) {
  const [modalOpen, setModalOpen] = useState(false);

  return (
    <div className="space-y-4">
      <div className="flex items-center justify-between">
        <div>
          <h3 className="text-lg font-bold text-white">Event Speakers</h3>
          <p className="text-xs text-slate-400">
            Real speakers loaded into AI context for accurate anchor introductions
          </p>
        </div>
        <Button size="sm" variant="primary" onClick={() => setModalOpen(true)}>
          <Plus className="w-4 h-4 mr-1.5" />
          Add Speaker
        </Button>
      </div>

      <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
        {speakers.map((s) => (
          <div
            key={s.id}
            className="p-4 rounded-2xl bg-surface border border-surface-border flex items-start gap-4"
          >
            {s.photoUrl ? (
              <img
                src={s.photoUrl}
                alt={s.name}
                className="w-14 h-14 rounded-2xl object-cover border border-surface-border shrink-0"
              />
            ) : (
              <div className="w-14 h-14 rounded-2xl bg-surface-light border border-surface-border flex items-center justify-center shrink-0">
                <User className="w-6 h-6 text-slate-400" />
              </div>
            )}

            <div className="min-w-0 flex-1">
              <div className="flex items-center justify-between gap-2 mb-1">
                <h4 className="text-sm font-bold text-white truncate">{s.name}</h4>
                <span
                  className={`text-[10px] font-mono px-2 py-0.5 rounded-full border ${
                    s.status === "arrived"
                      ? "bg-emerald-500/15 text-emerald-400 border-emerald-500/30"
                      : s.status === "expected"
                      ? "bg-amber-500/15 text-amber-400 border-amber-500/30"
                      : "bg-rose-500/15 text-rose-400 border-rose-500/30"
                  }`}
                >
                  {s.status}
                </span>
              </div>

              <div className="text-xs text-slate-300 font-medium truncate">
                {s.designation} · <span className="text-slate-400">{s.organization}</span>
              </div>

              {s.topic && (
                <div className="text-xs text-indigo-300 font-medium truncate mt-1">
                  &ldquo;{s.topic}&rdquo;
                </div>
              )}
            </div>
          </div>
        ))}
      </div>

      <SpeakerModal
        isOpen={modalOpen}
        onClose={() => setModalOpen(false)}
        eventId={eventId}
        onAdded={onRefresh}
      />
    </div>
  );
}
