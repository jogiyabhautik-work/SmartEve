"use client";

import React, { useState } from "react";
import { Modal } from "@/components/ui/modal";
import { Button } from "@/components/ui/button";
import { broadcastStateChange } from "@/lib/syncClient";
import { notify } from "@/components/ui/toast";
import { Plus, Minus, Clock, ShieldCheck } from "lucide-react";

export interface DelayModalProps {
  isOpen: boolean;
  onClose: () => void;
  eventId: string;
  currentItemId?: string | null;
}

export function DelayModal({ isOpen, onClose, eventId, currentItemId }: DelayModalProps) {
  const [minutes, setMinutes] = useState<number>(15);
  const [reason, setReason] = useState("");
  const [loading, setLoading] = useState(false);

  const presets = [5, 10, 15, 20, 30, -10];

  const handleApply = async () => {
    if (minutes === 0) {
      notify({ type: "warning", message: "Please specify non-zero delay minutes." });
      return;
    }

    setLoading(true);
    try {
      const res = await fetch(`/api/events/${eventId}/delay`, {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({
          delayMinutes: minutes,
          targetItemId: currentItemId || undefined,
          reason: reason.trim() || undefined,
        }),
      });

      const data = await res.json();
      if (data.success) {
        broadcastStateChange("delay_applied", { minutes });
        notify({
          type: "success",
          message: `Reflow applied (${minutes > 0 ? `+${minutes}` : minutes} min). Schedule synchronized across all devices!`,
        });
        onClose();
      } else {
        notify({ type: "error", message: data.error?.message || "Failed to apply delay" });
      }
    } catch (e) {
      notify({ type: "error", message: "Network error applying delay" });
    } finally {
      setLoading(false);
    }
  };

  return (
    <Modal isOpen={isOpen} onClose={onClose} title="Smart Schedule Delay & Reflow" maxWidth="md">
      <div className="space-y-5">
        {/* Explanation */}
        <div className="p-3 rounded-xl bg-primary/10 border border-primary/20 text-xs text-indigo-300 leading-relaxed">
          The deterministic reflow engine automatically recalculates upcoming timings and compresses absorbable break buffers before shifting major sessions.
        </div>

        {/* Quick Presets */}
        <div>
          <label className="text-xs font-semibold text-slate-300 uppercase tracking-wider block mb-2">
            Quick Presets
          </label>
          <div className="grid grid-cols-3 gap-2">
            {presets.map((p) => (
              <button
                key={p}
                type="button"
                onClick={() => setMinutes(p)}
                className={`py-2 px-3 rounded-xl text-xs font-mono font-bold transition-all border ${
                  minutes === p
                    ? "bg-amber-500 text-black border-amber-400 shadow-md shadow-amber-500/20"
                    : "bg-surface-light text-slate-300 border-surface-border hover:bg-surface-border"
                }`}
              >
                {p > 0 ? `+${p} min` : `${p} min`}
              </button>
            ))}
          </div>
        </div>

        {/* Custom Input */}
        <div>
          <label className="text-xs font-semibold text-slate-300 uppercase tracking-wider block mb-2">
            Custom Minutes
          </label>
          <div className="flex items-center gap-3">
            <button
              type="button"
              onClick={() => setMinutes((prev) => prev - 5)}
              className="p-2.5 rounded-xl bg-surface-light border border-surface-border text-slate-300 hover:text-white"
            >
              <Minus className="w-4 h-4" />
            </button>

            <input
              type="number"
              value={minutes}
              onChange={(e) => setMinutes(parseInt(e.target.value) || 0)}
              className="w-full bg-background border border-surface-border rounded-xl px-4 py-2 text-center text-xl font-mono font-bold text-white focus:outline-none focus:ring-2 focus:ring-primary"
            />

            <button
              type="button"
              onClick={() => setMinutes((prev) => prev + 5)}
              className="p-2.5 rounded-xl bg-surface-light border border-surface-border text-slate-300 hover:text-white"
            >
              <Plus className="w-4 h-4" />
            </button>
          </div>
        </div>

        {/* Reason / Context */}
        <div>
          <label className="text-xs font-semibold text-slate-300 uppercase tracking-wider block mb-2">
            Reason (Optional)
          </label>
          <input
            type="text"
            placeholder="e.g. Extended audience Q&A, Speaker flight delay"
            value={reason}
            onChange={(e) => setReason(e.target.value)}
            className="w-full bg-background border border-surface-border rounded-xl px-4 py-2.5 text-sm text-white focus:outline-none focus:ring-2 focus:ring-primary placeholder:text-slate-500"
          />
        </div>

        {/* Actions */}
        <div className="flex items-center justify-end gap-3 pt-3 border-t border-surface-border">
          <Button variant="ghost" onClick={onClose} disabled={loading}>
            Cancel
          </Button>
          <Button variant="amber" onClick={handleApply} isLoading={loading} className="font-bold">
            Apply Schedule Reflow
          </Button>
        </div>
      </div>
    </Modal>
  );
}
