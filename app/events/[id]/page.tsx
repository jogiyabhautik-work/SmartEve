"use client";

import React, { use, useState, useEffect } from "react";
import Link from "next/link";
import { useRouter } from "next/navigation";
import { Navbar } from "@/components/layout/Navbar";
import { AgendaEditor } from "@/components/agenda/AgendaEditor";
import { SpeakerList } from "@/components/speakers/SpeakerList";
import { useEvent } from "@/hooks/useEvent";
import { useAgenda } from "@/hooks/useAgenda";
import { Speaker } from "@/types/speaker";
import { subscribeToSpeakers, broadcastStateChange } from "@/lib/syncClient";
import { Button } from "@/components/ui/button";
import { Badge } from "@/components/ui/badge";
import { formatDateDisplay } from "@/lib/time";
import { Radio, Calendar, MapPin, Play, Tv, Smartphone, FileText } from "lucide-react";
import { notify } from "@/components/ui/toast";

export default function EventDetailPage({ params }: { params: Promise<{ id: string }> }) {
  const { id } = use(params);
  const router = useRouter();
  const { event, loading: eventLoading } = useEvent(id);
  const { agenda, loading: agendaLoading } = useAgenda(id);
  const [speakers, setSpeakers] = useState<Speaker[]>([]);
  const [activeTab, setActiveTab] = useState<"agenda" | "speakers">("agenda");
  const [starting, setStarting] = useState(false);

  useEffect(() => {
    const unsubscribe = subscribeToSpeakers(id, (spks) => setSpeakers(spks));
    return () => unsubscribe();
  }, [id]);

  const handleStartLive = async () => {
    setStarting(true);
    try {
      const res = await fetch(`/api/events/${id}/start`, { method: "POST" });
      const data = await res.json();
      if (data.success) {
        broadcastStateChange("event_started");
        notify({ type: "success", message: "Summit is now LIVE!" });
        router.push(`/events/${id}/live`);
      } else {
        notify({ type: "error", message: data.error?.message || "Failed to start event" });
      }
    } catch (e) {
      notify({ type: "error", message: "Network error starting summit" });
    } finally {
      setStarting(false);
    }
  };

  if (eventLoading || !event) {
    return (
      <div className="min-h-screen bg-background text-slate-100 flex flex-col">
        <Navbar eventId={id} />
        <div className="flex-1 flex items-center justify-center">
          <div className="w-8 h-8 border-2 border-primary border-t-transparent rounded-full animate-spin" />
        </div>
      </div>
    );
  }

  const isLive = event.liveState.status === "live";

  return (
    <div className="min-h-screen bg-background text-slate-100 flex flex-col">
      <Navbar eventId={id} joinCode={event.joinCode} />

      <main className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-8 flex-1 w-full space-y-6">
        {/* Summit Header */}
        <div className="p-6 rounded-3xl bg-surface border border-surface-border shadow-xl flex flex-col md:flex-row md:items-center md:justify-between gap-6">
          <div>
            <div className="flex items-center gap-3 mb-2">
              <Badge variant={isLive ? "live" : "primary"} pulse={isLive}>
                {isLive ? "SUMMIT LIVE" : "READY FOR STAGE"}
              </Badge>
              <span className="text-xs font-mono text-slate-400">
                JOIN CODE: <span className="text-white font-bold">{event.joinCode}</span>
              </span>
            </div>

            <h1 className="text-2xl md:text-3xl font-black text-white tracking-tight">
              {event.name}
            </h1>

            <div className="flex flex-wrap items-center gap-4 mt-2 text-xs text-slate-300">
              <span className="flex items-center gap-1.5">
                <Calendar className="w-3.5 h-3.5 text-slate-400" />
                {formatDateDisplay(event.date)}
              </span>
              <span className="flex items-center gap-1.5">
                <MapPin className="w-3.5 h-3.5 text-slate-400" />
                {event.venue}
              </span>
              <span>Tone: {event.tone}</span>
            </div>
          </div>

          {/* Action CTAs */}
          <div className="flex flex-wrap items-center gap-3">
            {isLive ? (
              <Link href={`/events/${id}/live`}>
                <Button variant="live" size="md" className="font-bold">
                  <Radio className="w-4 h-4 mr-2 animate-pulse" />
                  Enter Live Control Room
                </Button>
              </Link>
            ) : (
              <Button
                variant="primary"
                size="md"
                className="font-bold"
                onClick={handleStartLive}
                isLoading={starting}
              >
                <Play className="w-4 h-4 mr-2" />
                Start Live Event
              </Button>
            )}

            <Link href={`/events/${id}/anchor`}>
              <Button variant="secondary" size="md">
                <Smartphone className="w-4 h-4 mr-2" />
                Anchor View
              </Button>
            </Link>

            <Link href={`/stage/${event.joinCode}`} target="_blank">
              <Button variant="secondary" size="md">
                <Tv className="w-4 h-4 mr-2" />
                Stage Display
              </Button>
            </Link>

            <Link href={`/events/${id}/summary`}>
              <Button variant="ghost" size="md">
                <FileText className="w-4 h-4 mr-1.5" />
                Summary
              </Button>
            </Link>
          </div>
        </div>

        {/* Tab Toggle: Agenda vs Speakers */}
        <div className="flex items-center gap-2 border-b border-surface-border pb-1">
          <button
            onClick={() => setActiveTab("agenda")}
            className={`px-4 py-2 text-sm font-bold border-b-2 transition-all ${
              activeTab === "agenda"
                ? "text-primary-light border-primary"
                : "text-slate-400 border-transparent hover:text-white"
            }`}
          >
            Agenda Flow ({agenda.length} sessions)
          </button>
          <button
            onClick={() => setActiveTab("speakers")}
            className={`px-4 py-2 text-sm font-bold border-b-2 transition-all ${
              activeTab === "speakers"
                ? "text-primary-light border-primary"
                : "text-slate-400 border-transparent hover:text-white"
            }`}
          >
            Speakers & VIPs ({speakers.length})
          </button>
        </div>

        {/* Tab Content */}
        {activeTab === "agenda" ? (
          <AgendaEditor agenda={agenda} speakers={speakers} eventId={id} />
        ) : (
          <SpeakerList speakers={speakers} eventId={id} />
        )}
      </main>
    </div>
  );
}
