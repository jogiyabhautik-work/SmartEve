"use client";

import React, { useState } from "react";
import { Modal } from "@/components/ui/modal";
import { Button } from "@/components/ui/button";
import { Speaker, SpeakerArrivalStatus } from "@/types/speaker";
import { notify } from "@/components/ui/toast";
import { broadcastStateChange } from "@/lib/syncClient";

export interface SpeakerModalProps {
  isOpen: boolean;
  onClose: () => void;
  eventId: string;
  onAdded?: (spk: Speaker) => void;
}

export function SpeakerModal({ isOpen, onClose, eventId, onAdded }: SpeakerModalProps) {
  const [name, setName] = useState("");
  const [designation, setDesignation] = useState("");
  const [organization, setOrganization] = useState("");
  const [topic, setTopic] = useState("");
  const [bio, setBio] = useState("");
  const [status, setStatus] = useState<SpeakerArrivalStatus>("arrived");
  const [loading, setLoading] = useState(false);

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!name || !designation || !organization) {
      notify({ type: "warning", message: "Please fill in all required speaker fields." });
      return;
    }

    setLoading(true);
    try {
      const res = await fetch(`/api/events/${eventId}/speakers`, {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({
          name,
          designation,
          organization,
          topic,
          bio,
          highlights: [topic],
          status,
        }),
      });
      const data = await res.json();
      if (data.success && data.data) {
        broadcastStateChange("speaker_added");
        notify({ type: "success", message: `Added speaker ${name}!` });
        onAdded?.(data.data);
        onClose();
      }
    } catch (e) {
      notify({ type: "error", message: "Failed to create speaker" });
    } finally {
      setLoading(false);
    }
  };

  return (
    <Modal isOpen={isOpen} onClose={onClose} title="Add Keynote / Session Speaker" maxWidth="md">
      <form onSubmit={handleSubmit} className="space-y-4">
        <div>
          <label className="text-xs font-semibold text-slate-300 block mb-1">Speaker Full Name *</label>
          <input
            required
            type="text"
            placeholder="e.g. Dr. Jane Cooper"
            value={name}
            onChange={(e) => setName(e.target.value)}
            className="w-full bg-background border border-surface-border rounded-xl px-3.5 py-2 text-sm text-white focus:outline-none focus:ring-2 focus:ring-primary"
          />
        </div>

        <div className="grid grid-cols-2 gap-3">
          <div>
            <label className="text-xs font-semibold text-slate-300 block mb-1">Designation *</label>
            <input
              required
              type="text"
              placeholder="e.g. VP of Applied AI"
              value={designation}
              onChange={(e) => setDesignation(e.target.value)}
              className="w-full bg-background border border-surface-border rounded-xl px-3.5 py-2 text-sm text-white focus:outline-none focus:ring-2 focus:ring-primary"
            />
          </div>
          <div>
            <label className="text-xs font-semibold text-slate-300 block mb-1">Organization *</label>
            <input
              required
              type="text"
              placeholder="e.g. DeepMind"
              value={organization}
              onChange={(e) => setOrganization(e.target.value)}
              className="w-full bg-background border border-surface-border rounded-xl px-3.5 py-2 text-sm text-white focus:outline-none focus:ring-2 focus:ring-primary"
            />
          </div>
        </div>

        <div>
          <label className="text-xs font-semibold text-slate-300 block mb-1">Presentation Topic</label>
          <input
            type="text"
            placeholder="e.g. Frontier Reasoning Models in 2026"
            value={topic}
            onChange={(e) => setTopic(e.target.value)}
            className="w-full bg-background border border-surface-border rounded-xl px-3.5 py-2 text-sm text-white focus:outline-none focus:ring-2 focus:ring-primary"
          />
        </div>

        <div>
          <label className="text-xs font-semibold text-slate-300 block mb-1">Arrival Status</label>
          <select
            value={status}
            onChange={(e) => setStatus(e.target.value as any)}
            className="w-full bg-background border border-surface-border rounded-xl px-3 py-2 text-sm text-white focus:outline-none focus:ring-2 focus:ring-primary"
          >
            <option value="arrived">Arrived On-Site</option>
            <option value="expected">Expected / In Transit</option>
            <option value="absent">Absent / Delayed</option>
          </select>
        </div>

        <div className="flex items-center justify-end gap-3 pt-3 border-t border-surface-border">
          <Button type="button" variant="ghost" onClick={onClose} disabled={loading}>
            Cancel
          </Button>
          <Button type="submit" variant="primary" isLoading={loading}>
            Save Speaker
          </Button>
        </div>
      </form>
    </Modal>
  );
}
