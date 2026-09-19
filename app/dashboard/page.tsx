"use client";

import React, { useEffect, useState } from "react";
import Link from "next/link";
import { Navbar } from "@/components/layout/Navbar";
import { EventCard } from "@/components/dashboard/EventCard";
import { Button } from "@/components/ui/button";
import { EventData } from "@/types/event";
import { INITIAL_DEMO_EVENT } from "@/lib/store";
import { Plus, Radio, Clock, ShieldCheck, Sparkles } from "lucide-react";
import { notify } from "@/components/ui/toast";
import { broadcastStateChange } from "@/lib/syncClient";
import { useRouter } from "next/navigation";

export default function DashboardPage() {
  const router = useRouter();
  const [events, setEvents] = useState<EventData[]>([INITIAL_DEMO_EVENT]);
  const [loading, setLoading] = useState(true);

  const fetchEvents = async () => {
    try {
      const res = await fetch("/api/events");
      const data = await res.json();
      if (data.success && data.data) {
        setEvents(data.data);
      }
    } catch (e) {
      // Use demo event fallback
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    fetchEvents();
  }, []);

  const handleStartEvent = async (id: string) => {
    try {
      const res = await fetch(`/api/events/${id}/start`, { method: "POST" });
      const data = await res.json();
      if (data.success) {
        broadcastStateChange("event_started");
        notify({ type: "success", message: "Summit started! Launching Live Control Room." });
        router.push(`/events/${id}/live`);
      } else {
        notify({ type: "error", message: data.error?.message || "Failed to start event" });
      }
    } catch (e) {
      notify({ type: "error", message: "Network error starting event" });
    }
  };

  return (
    <div className="min-h-screen bg-background text-slate-100 flex flex-col">
      <Navbar />

      <main className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-8 flex-1 w-full space-y-8">
        {/* Header & New Event Action */}
        <div className="flex flex-col sm:flex-row sm:items-center sm:justify-between gap-4">
          <div>
            <h1 className="text-3xl font-extrabold text-white tracking-tight">Organizer Dashboard</h1>
            <p className="text-xs text-slate-400 mt-1">
              Manage your summits, stage displays, anchors, and live agenda flows
            </p>
          </div>

          <Link href="/events/new">
            <Button variant="primary" size="md" className="font-bold">
              <Plus className="w-4 h-4 mr-1.5" />
              Create New Event
            </Button>
          </Link>
        </div>

        {/* Stats Row */}
        <div className="grid grid-cols-2 md:grid-cols-4 gap-4">
          <div className="p-4 rounded-2xl bg-surface border border-surface-border">
            <div className="flex items-center gap-2 text-xs font-semibold text-slate-400 mb-1">
              <Radio className="w-3.5 h-3.5 text-emerald-400" />
              Live Status
            </div>
            <div className="text-xl font-bold text-white">
              {events.some((e) => e.liveState.status === "live") ? "1 Active Live" : "Ready to Launch"}
            </div>
          </div>

          <div className="p-4 rounded-2xl bg-surface border border-surface-border">
            <div className="flex items-center gap-2 text-xs font-semibold text-slate-400 mb-1">
              <Clock className="w-3.5 h-3.5 text-primary-light" />
              Sync Engine
            </div>
            <div className="text-xl font-bold text-white">Deterministic</div>
          </div>

          <div className="p-4 rounded-2xl bg-surface border border-surface-border">
            <div className="flex items-center gap-2 text-xs font-semibold text-slate-400 mb-1">
              <ShieldCheck className="w-3.5 h-3.5 text-amber-400" />
              Buffer Protection
            </div>
            <div className="text-xl font-bold text-white">Break Absorption</div>
          </div>

          <div className="p-4 rounded-2xl bg-surface border border-surface-border">
            <div className="flex items-center gap-2 text-xs font-semibold text-slate-400 mb-1">
              <Sparkles className="w-3.5 h-3.5 text-purple-400" />
              AI Assistant
            </div>
            <div className="text-xl font-bold text-white">Triple Fallback</div>
          </div>
        </div>

        {/* Event Cards */}
        <div className="space-y-4">
          <h2 className="text-lg font-bold text-white">Your Scheduled Summits</h2>

          <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6">
            {events.map((evt) => (
              <EventCard key={evt.id} event={evt} onStart={handleStartEvent} />
            ))}
          </div>
        </div>
      </main>
    </div>
  );
}
