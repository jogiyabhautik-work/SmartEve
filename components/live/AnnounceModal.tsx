"use client";

import React, { useState } from "react";
import { Modal } from "@/components/ui/modal";
import { Button } from "@/components/ui/button";
import { broadcastStateChange } from "@/lib/syncClient";
import { notify } from "@/components/ui/toast";
import { Megaphone } from "lucide-react";

export interface AnnounceModalProps {
  isOpen: boolean;
  onClose: () => void;
  eventId: string;
}

export function AnnounceModal({ isOpen, onClose, eventId }: AnnounceModalProps) {
  const [message, setMessage] = useState("");
  const [priority, setPriority] = useState<"normal" | "high" | "urgent">("normal");
  const [loading, setLoading] = useState(false);

  const quickTemplates = [
    "Lunch will be served at Canteen 2 on the ground floor.",
    "Networking tea break is now open in the Main Exhibition Foyer.",
    "Please take your seats, the keynote will begin in 2 minutes.",
    "Lost & Found: A set of car keys was turned in at the registration desk.",
  ];

  const handlePublish = async () => {
    if (!message.trim()) {
      notify({ type: "warning", message: "Please enter an announcement message." });
      return;
    }

    setLoading(true);
    try {
      const res = await fetch(`/api/events/${eventId}/announce`, {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({ message: message.trim(), priority }),
      });

      const data = await res.json();
      if (data.success) {
        broadcastStateChange("announcement_published", { message });
        notify({
          type: "success",
          message: "Announcement broadcasted to Anchor screen and Stage Display!",
        });
        setMessage("");
        onClose();
      } else {
        notify({ type: "error", message: data.error?.message || "Failed to publish announcement" });
      }
    } catch (e) {
      notify({ type: "error", message: "Network error broadcasting announcement" });
    } finally {
      setLoading(false);
    }
  };

  return (
    <Modal isOpen={isOpen} onClose={onClose} title="Broadcast Live Stage Announcement" maxWidth="md">
      <div className="space-y-4">
        {/* Quick presets */}
        <div>
          <label className="text-xs font-semibold text-slate-300 uppercase tracking-wider block mb-2">
            Quick Templates
          </label>
          <div className="space-y-1.5">
            {quickTemplates.map((tmpl, idx) => (
              <button
                key={idx}
                type="button"
                onClick={() => setMessage(tmpl)}
                className="w-full text-left p-2 rounded-lg bg-surface-light hover:bg-surface-border text-xs text-slate-300 transition-colors truncate"
              >
                &ldquo;{tmpl}&rdquo;
              </button>
            ))}
          </div>
        </div>

        {/* Message Input */}
        <div>
          <label className="text-xs font-semibold text-slate-300 uppercase tracking-wider block mb-2">
            Custom Message
          </label>
          <textarea
            rows={3}
            value={message}
            onChange={(e) => setMessage(e.target.value)}
            placeholder="Type live announcement here..."
            className="w-full bg-background border border-surface-border rounded-xl p-3 text-sm text-white focus:outline-none focus:ring-2 focus:ring-primary"
          />
        </div>

        {/* Priority */}
        <div>
          <label className="text-xs font-semibold text-slate-300 uppercase tracking-wider block mb-2">
            Priority
          </label>
          <div className="flex gap-2">
            {(["normal", "high", "urgent"] as const).map((p) => (
              <button
                key={p}
                type="button"
                onClick={() => setPriority(p)}
                className={`flex-1 py-1.5 rounded-lg text-xs font-semibold uppercase tracking-wider border transition-colors ${
                  priority === p
                    ? p === "urgent"
                      ? "bg-rose-500 text-white border-rose-400"
                      : p === "high"
                      ? "bg-amber-500 text-black border-amber-400"
                      : "bg-primary text-white border-primary-light"
                    : "bg-surface-light text-slate-400 border-surface-border hover:bg-surface-border"
                }`}
              >
                {p}
              </button>
            ))}
          </div>
        </div>

        {/* Action buttons */}
        <div className="flex items-center justify-end gap-3 pt-3 border-t border-surface-border">
          <Button variant="ghost" onClick={onClose} disabled={loading}>
            Cancel
          </Button>
          <Button variant="primary" onClick={handlePublish} isLoading={loading} className="font-bold">
            <Megaphone className="w-4 h-4 mr-2" />
            Broadcast Now
          </Button>
        </div>
      </div>
    </Modal>
  );
}
