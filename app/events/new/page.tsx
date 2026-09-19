"use client";

import React, { useState } from "react";
import { useRouter } from "next/navigation";
import { Navbar } from "@/components/layout/Navbar";
import { Button } from "@/components/ui/button";
import { notify } from "@/components/ui/toast";

export default function NewEventPage() {
  const router = useRouter();
  const [name, setName] = useState("");
  const [type, setType] = useState("AI Conference");
  const [date, setDate] = useState("2026-09-20");
  const [venue, setVenue] = useState("Main Innovation Hall");
  const [joinCode, setJoinCode] = useState("DEMO26");
  const [tone, setTone] = useState("Visionary & Dynamic");
  const [description, setDescription] = useState("");
  const [loading, setLoading] = useState(false);

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!name || !joinCode) {
      notify({ type: "warning", message: "Please fill in all required fields." });
      return;
    }

    setLoading(true);
    try {
      const res = await fetch("/api/events", {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({
          name,
          type,
          date,
          venue,
          joinCode: joinCode.toUpperCase(),
          tone,
          description,
        }),
      });

      const data = await res.json();
      if (data.success && data.data) {
        notify({ type: "success", message: "Event created successfully!" });
        router.push(`/events/${data.data.id}`);
      } else {
        notify({ type: "error", message: data.error?.message || "Failed to create event" });
      }
    } catch (err) {
      notify({ type: "error", message: "Network error creating event" });
    } finally {
      setLoading(false);
    }
  };

  return (
    <div className="min-h-screen bg-background text-slate-100 flex flex-col">
      <Navbar />

      <main className="max-w-3xl mx-auto px-4 py-10 flex-1 w-full space-y-6">
        <div>
          <h1 className="text-2xl font-bold text-white tracking-tight">Create New Summit</h1>
          <p className="text-xs text-slate-400">
            Set up an event with real-time multi-device sync and smart reflow
          </p>
        </div>

        <form onSubmit={handleSubmit} className="p-6 rounded-2xl bg-surface border border-surface-border space-y-4">
          <div>
            <label className="text-xs font-semibold text-slate-300 block mb-1">Event Name *</label>
            <input
              required
              type="text"
              placeholder="e.g. NextGen AI Summit 2026"
              value={name}
              onChange={(e) => setName(e.target.value)}
              className="w-full bg-background border border-surface-border rounded-xl px-4 py-2 text-sm text-white focus:outline-none focus:ring-2 focus:ring-primary"
            />
          </div>

          <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
            <div>
              <label className="text-xs font-semibold text-slate-300 block mb-1">Event Type</label>
              <input
                type="text"
                value={type}
                onChange={(e) => setType(e.target.value)}
                className="w-full bg-background border border-surface-border rounded-xl px-4 py-2 text-sm text-white focus:outline-none focus:ring-2 focus:ring-primary"
              />
            </div>
            <div>
              <label className="text-xs font-semibold text-slate-300 block mb-1">Date</label>
              <input
                type="date"
                value={date}
                onChange={(e) => setDate(e.target.value)}
                className="w-full bg-background border border-surface-border rounded-xl px-4 py-2 text-sm text-white focus:outline-none focus:ring-2 focus:ring-primary"
              />
            </div>
          </div>

          <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
            <div>
              <label className="text-xs font-semibold text-slate-300 block mb-1">Venue Location</label>
              <input
                type="text"
                value={venue}
                onChange={(e) => setVenue(e.target.value)}
                className="w-full bg-background border border-surface-border rounded-xl px-4 py-2 text-sm text-white focus:outline-none focus:ring-2 focus:ring-primary"
              />
            </div>
            <div>
              <label className="text-xs font-semibold text-slate-300 block mb-1">
                Volunteer Join Code (3-8 uppercase chars) *
              </label>
              <input
                required
                maxLength={8}
                type="text"
                value={joinCode}
                onChange={(e) => setJoinCode(e.target.value.toUpperCase())}
                className="w-full bg-background border border-surface-border rounded-xl px-4 py-2 text-sm font-mono font-bold text-white focus:outline-none focus:ring-2 focus:ring-primary"
              />
            </div>
          </div>

          <div>
            <label className="text-xs font-semibold text-slate-300 block mb-1">Anchor Tone & Persona</label>
            <input
              type="text"
              value={tone}
              onChange={(e) => setTone(e.target.value)}
              className="w-full bg-background border border-surface-border rounded-xl px-4 py-2 text-sm text-white focus:outline-none focus:ring-2 focus:ring-primary"
            />
          </div>

          <div>
            <label className="text-xs font-semibold text-slate-300 block mb-1">Event Summary</label>
            <textarea
              rows={3}
              value={description}
              onChange={(e) => setDescription(e.target.value)}
              className="w-full bg-background border border-surface-border rounded-xl p-3 text-sm text-white focus:outline-none focus:ring-2 focus:ring-primary"
            />
          </div>

          <div className="flex items-center justify-end gap-3 pt-4 border-t border-surface-border">
            <Button type="button" variant="ghost" onClick={() => router.back()}>
              Cancel
            </Button>
            <Button type="submit" variant="primary" isLoading={loading} className="font-bold">
              Save & Setup Flow
            </Button>
          </div>
        </form>
      </main>
    </div>
  );
}
