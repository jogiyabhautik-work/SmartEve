"use client";

import React, { use, useState, useEffect } from "react";
import { ProjectorDisplay } from "@/components/stage/ProjectorDisplay";
import { EventData } from "@/types/event";
import { AgendaItem } from "@/types/agenda";
import { Speaker } from "@/types/speaker";
import { EventNotification } from "@/types/notification";
import { INITIAL_DEMO_EVENT, INITIAL_DEMO_AGENDA, INITIAL_DEMO_SPEAKERS } from "@/lib/store";
import { Tv, AlertTriangle } from "lucide-react";

export default function PublicStagePage({
  params,
}: {
  params: Promise<{ joinCode: string }>;
}) {
  const { joinCode } = use(params);
  const [event, setEvent] = useState<EventData | null>(null);
  const [agenda, setAgenda] = useState<AgendaItem[]>([]);
  const [speakers, setSpeakers] = useState<Speaker[]>([]);
  const [notifications, setNotifications] = useState<EventNotification[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);

  const fetchStageData = async () => {
    try {
      const res = await fetch(`/api/public/${joinCode}`);
      const data = await res.json();
      if (data.success && data.data) {
        setEvent(data.data.event);
        setAgenda(data.data.agenda || []);
        setSpeakers(data.data.speakers || []);
        setNotifications(data.data.notifications || []);
      } else {
        // If demo join code TN26, load initial demo state
        if (joinCode.toUpperCase() === "TN26") {
          setEvent(INITIAL_DEMO_EVENT);
          setAgenda(Object.values(INITIAL_DEMO_AGENDA));
          setSpeakers(Object.values(INITIAL_DEMO_SPEAKERS));
        } else {
          setError(data.error?.message || "Invalid join code");
        }
      }
    } catch (e) {
      if (joinCode.toUpperCase() === "TN26") {
        setEvent(INITIAL_DEMO_EVENT);
        setAgenda(Object.values(INITIAL_DEMO_AGENDA));
        setSpeakers(Object.values(INITIAL_DEMO_SPEAKERS));
      } else {
        setError("Network error loading stage display");
      }
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    fetchStageData();

    // Listen to real-time bus
    let channel: BroadcastChannel | null = null;
    if (typeof window !== "undefined" && "BroadcastChannel" in window) {
      channel = new BroadcastChannel("smart_anchor_realtime_bus");
      channel.addEventListener("message", () => fetchStageData());
    }

    // Polling fallback every 4 seconds for remote stage projectors
    const interval = setInterval(() => fetchStageData(), 4000);

    return () => {
      if (channel) channel.close();
      clearInterval(interval);
    };
  }, [joinCode]);

  if (loading) {
    return (
      <div className="min-h-screen bg-[#070B18] text-white flex items-center justify-center p-8">
        <div className="text-center space-y-4">
          <div className="w-12 h-12 border-4 border-primary border-t-transparent rounded-full animate-spin mx-auto" />
          <div className="text-lg font-mono text-slate-400">
            CONNECTING TO LIVE STAGE DISPLAY [{joinCode.toUpperCase()}]...
          </div>
        </div>
      </div>
    );
  }

  if (error || !event) {
    return (
      <div className="min-h-screen bg-[#070B18] text-white flex items-center justify-center p-8">
        <div className="text-center p-8 rounded-3xl bg-surface border border-surface-border max-w-md space-y-4">
          <AlertTriangle className="w-12 h-12 text-amber-400 mx-auto" />
          <h2 className="text-xl font-bold text-white">Stage Display Not Found</h2>
          <p className="text-sm text-slate-400">
            {error || `No active event found with join code "${joinCode}". Please verify the code with your organizer.`}
          </p>
        </div>
      </div>
    );
  }

  return (
    <ProjectorDisplay
      event={event}
      agenda={agenda}
      speakers={speakers}
      notifications={notifications}
    />
  );
}
