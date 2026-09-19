"use client";

import React, { useState } from "react";
import { AgendaItem, AgendaItemType } from "@/types/agenda";
import { Speaker } from "@/types/speaker";
import { formatTimeDisplay } from "@/lib/time";
import { Button } from "@/components/ui/button";
import { Badge } from "@/components/ui/badge";
import { Modal } from "@/components/ui/modal";
import { Plus, Clock, ShieldCheck, AlertCircle, Trash2 } from "lucide-react";
import { notify } from "@/components/ui/toast";
import { broadcastStateChange } from "@/lib/syncClient";

export interface AgendaEditorProps {
  agenda: AgendaItem[];
  speakers: Speaker[];
  eventId: string;
  onRefresh?: () => void;
}

export function AgendaEditor({ agenda, speakers, eventId, onRefresh }: AgendaEditorProps) {
  const [modalOpen, setModalOpen] = useState(false);
  const [title, setTitle] = useState("");
  const [type, setType] = useState<AgendaItemType>("talk");
  const [duration, setDuration] = useState(30);
  const [absorbable, setAbsorbable] = useState(false);
  const [minDuration, setMinDuration] = useState(15);
  const [hardStart, setHardStart] = useState(false);
  const [selectedSpeakerId, setSelectedSpeakerId] = useState("");
  const [loading, setLoading] = useState(false);

  const handleAddItem = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!title) {
      notify({ type: "warning", message: "Please provide a session title." });
      return;
    }

    setLoading(true);
    try {
      const now = new Date();
      const startTime = now.toISOString();
      const endTime = new Date(now.getTime() + duration * 60 * 1000).toISOString();

      const res = await fetch(`/api/events/${eventId}/agenda`, {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({
          title,
          type,
          duration,
          plannedStart: startTime,
          startTime,
          endTime,
          speakerIds: selectedSpeakerId ? [selectedSpeakerId] : [],
          absorbable,
          minDuration: absorbable ? minDuration : undefined,
          hardStart,
        }),
      });

      const data = await res.json();
      if (data.success) {
        broadcastStateChange("agenda_updated");
        notify({ type: "success", message: `Added session "${title}"!` });
        setTitle("");
        setModalOpen(false);
        onRefresh?.();
      }
    } catch (e) {
      notify({ type: "error", message: "Failed to add agenda item" });
    } finally {
      setLoading(false);
    }
  };

  return (
    <div className="space-y-4">
      <div className="flex items-center justify-between">
        <div>
          <h3 className="text-lg font-bold text-white">Event Agenda Schedule</h3>
          <p className="text-xs text-slate-400">
            Configure session order, absorbable buffers, and speaker assignments
          </p>
        </div>
        <Button size="sm" variant="primary" onClick={() => setModalOpen(true)}>
          <Plus className="w-4 h-4 mr-1.5" />
          Add Session
        </Button>
      </div>

      <div className="space-y-3">
        {agenda.map((item, idx) => {
          const spk = speakers.find((s) => item.speakerIds.includes(s.id));

          return (
            <div
              key={item.id}
              className="p-4 rounded-2xl bg-surface border border-surface-border flex items-center justify-between gap-4"
            >
              <div className="flex items-center gap-4 min-w-0">
                <div className="w-8 h-8 rounded-xl bg-surface-light border border-surface-border flex items-center justify-center text-xs font-mono font-bold text-slate-300 shrink-0">
                  {idx + 1}
                </div>

                <div className="min-w-0">
                  <div className="flex items-center gap-2 mb-1">
                    <span className="text-xs font-mono text-slate-400">
                      {formatTimeDisplay(item.startTime)} – {formatTimeDisplay(item.endTime)}
                    </span>

                    <span className="text-[10px] uppercase font-mono px-2 py-0.5 rounded bg-surface-light text-slate-300">
                      {item.type}
                    </span>

                    {item.absorbable && (
                      <span className="inline-flex items-center gap-1 text-[10px] font-mono px-2 py-0.5 rounded bg-amber-500/15 text-amber-300 border border-amber-500/30">
                        <ShieldCheck className="w-3 h-3" />
                        Absorbable Buffer (Min {item.minDuration || 15}m)
                      </span>
                    )}

                    {item.hardStart && (
                      <span className="inline-flex items-center gap-1 text-[10px] font-mono px-2 py-0.5 rounded bg-rose-500/15 text-rose-300 border border-rose-500/30">
                        <AlertCircle className="w-3 h-3" />
                        Fixed Hard Start
                      </span>
                    )}
                  </div>

                  <h4 className="text-sm font-bold text-white truncate">{item.title}</h4>

                  {spk && (
                    <div className="text-xs text-indigo-300 font-medium truncate mt-0.5">
                      Speaker: {spk.name} ({spk.organization})
                    </div>
                  )}
                </div>
              </div>

              <div className="flex items-center gap-3 shrink-0">
                <span className="text-xs font-mono text-slate-300 px-2.5 py-1 rounded-lg bg-surface-light border border-surface-border">
                  {item.duration}m
                </span>

                <span
                  className={`text-[11px] font-mono font-bold px-2 py-0.5 rounded-full ${
                    item.status === "live"
                      ? "bg-emerald-500/20 text-emerald-400 border border-emerald-500/40"
                      : item.status === "done"
                      ? "bg-slate-800 text-slate-400"
                      : item.status === "cancelled"
                      ? "bg-rose-500/20 text-rose-400"
                      : "bg-indigo-500/10 text-indigo-300"
                  }`}
                >
                  {item.status.toUpperCase()}
                </span>
              </div>
            </div>
          );
        })}
      </div>

      {/* Add Session Modal */}
      <Modal isOpen={modalOpen} onClose={() => setModalOpen(false)} title="Add Agenda Session" maxWidth="md">
        <form onSubmit={handleAddItem} className="space-y-4">
          <div>
            <label className="text-xs font-semibold text-slate-300 block mb-1">Session Title *</label>
            <input
              required
              type="text"
              placeholder="e.g. Distributed Inference at Scale"
              value={title}
              onChange={(e) => setTitle(e.target.value)}
              className="w-full bg-background border border-surface-border rounded-xl px-3.5 py-2 text-sm text-white focus:outline-none focus:ring-2 focus:ring-primary"
            />
          </div>

          <div className="grid grid-cols-2 gap-3">
            <div>
              <label className="text-xs font-semibold text-slate-300 block mb-1">Session Type</label>
              <select
                value={type}
                onChange={(e) => setType(e.target.value as any)}
                className="w-full bg-background border border-surface-border rounded-xl px-3 py-2 text-sm text-white focus:outline-none focus:ring-2 focus:ring-primary"
              >
                <option value="talk">Technical Talk</option>
                <option value="keynote">Keynote</option>
                <option value="panel">Panel Discussion</option>
                <option value="break">Break / Lunch</option>
                <option value="workshop">Workshop</option>
                <option value="opening">Opening</option>
                <option value="closing">Closing</option>
              </select>
            </div>

            <div>
              <label className="text-xs font-semibold text-slate-300 block mb-1">Duration (minutes)</label>
              <input
                type="number"
                min={1}
                value={duration}
                onChange={(e) => setDuration(parseInt(e.target.value) || 15)}
                className="w-full bg-background border border-surface-border rounded-xl px-3.5 py-2 text-sm text-white focus:outline-none focus:ring-2 focus:ring-primary"
              />
            </div>
          </div>

          <div>
            <label className="text-xs font-semibold text-slate-300 block mb-1">Assign Speaker (Optional)</label>
            <select
              value={selectedSpeakerId}
              onChange={(e) => setSelectedSpeakerId(e.target.value)}
              className="w-full bg-background border border-surface-border rounded-xl px-3 py-2 text-sm text-white focus:outline-none focus:ring-2 focus:ring-primary"
            >
              <option value="">-- No Speaker Assigned --</option>
              {speakers.map((s) => (
                <option key={s.id} value={s.id}>
                  {s.name} ({s.organization})
                </option>
              ))}
            </select>
          </div>

          {/* Buffer & Constraints */}
          <div className="p-3 rounded-xl bg-surface-light/50 border border-surface-border space-y-3">
            <div className="flex items-center justify-between">
              <div>
                <div className="text-xs font-bold text-white">Absorbable Break Buffer</div>
                <div className="text-[11px] text-slate-400">
                  Allow reflow engine to compress this break to absorb upstream delays
                </div>
              </div>
              <input
                type="checkbox"
                checked={absorbable}
                onChange={(e) => setAbsorbable(e.target.checked)}
                className="w-4 h-4 rounded text-primary focus:ring-primary bg-background border-surface-border"
              />
            </div>

            {absorbable && (
              <div>
                <label className="text-xs text-slate-300 block mb-1">
                  Minimum Protected Duration (minutes)
                </label>
                <input
                  type="number"
                  min={5}
                  max={duration}
                  value={minDuration}
                  onChange={(e) => setMinDuration(parseInt(e.target.value) || 10)}
                  className="w-full bg-background border border-surface-border rounded-xl px-3 py-1.5 text-xs text-white"
                />
              </div>
            )}

            <div className="flex items-center justify-between pt-2 border-t border-surface-border/50">
              <div>
                <div className="text-xs font-bold text-white">Hard Start Constraint</div>
                <div className="text-[11px] text-slate-400">
                  Fixed start time (e.g. live broadcast stream)
                </div>
              </div>
              <input
                type="checkbox"
                checked={hardStart}
                onChange={(e) => setHardStart(e.target.checked)}
                className="w-4 h-4 rounded text-primary focus:ring-primary bg-background border-surface-border"
              />
            </div>
          </div>

          <div className="flex items-center justify-end gap-3 pt-3 border-t border-surface-border">
            <Button type="button" variant="ghost" onClick={() => setModalOpen(false)} disabled={loading}>
              Cancel
            </Button>
            <Button type="submit" variant="primary" isLoading={loading}>
              Save Session
            </Button>
          </div>
        </form>
      </Modal>
    </div>
  );
}
