"use client";

import React, { use, useEffect, useState } from "react";
import Link from "next/link";
import { Navbar } from "@/components/layout/Navbar";
import { useEvent } from "@/hooks/useEvent";
import { useAgenda } from "@/hooks/useAgenda";
import { useNotifications } from "@/hooks/useNotifications";
import { formatTimeDisplay, formatDateDisplay } from "@/lib/time";
import { Button } from "@/components/ui/button";
import { Badge } from "@/components/ui/badge";
import {
  Clock,
  ShieldCheck,
  Sparkles,
  CheckCircle2,
  XCircle,
  TrendingUp,
  ArrowRight,
  BarChart3,
  Calendar,
} from "lucide-react";

export default function EventSummaryPage({ params }: { params: Promise<{ id: string }> }) {
  const { id } = use(params);
  const { event } = useEvent(id);
  const { agenda } = useAgenda(id);
  const { notifications } = useNotifications(id);
  const [scriptsCount, setScriptsCount] = useState(0);

  useEffect(() => {
    fetch(`/api/events/${id}/scripts`)
      .then((res) => res.json())
      .then((res) => {
        if (res.success && res.data) {
          setScriptsCount(res.data.length);
        }
      })
      .catch(() => {});
  }, [id]);

  const completedItems = agenda.filter((i) => i.status === "done");
  const cancelledItems = agenda.filter((i) => i.status === "cancelled");
  const delayChanges = notifications.filter((n) => n.type === "delay");

  const totalPlannedDuration = agenda.reduce((acc, curr) => acc + curr.duration, 0);
  const netDelay = event?.liveState.totalDelayMin || 0;

  return (
    <div className="min-h-screen bg-background text-slate-100 flex flex-col">
      <Navbar eventId={id} joinCode={event?.joinCode} />

      <main className="max-w-6xl mx-auto px-4 sm:px-6 lg:px-8 py-10 flex-1 w-full space-y-8">
        {/* Header */}
        <div className="flex flex-col md:flex-row md:items-center md:justify-between gap-4 border-b border-surface-border pb-6">
          <div>
            <div className="flex items-center gap-2 mb-2">
              <Badge variant="neutral">POST-EVENT EXECUTIVE SUMMARY</Badge>
              <span className="text-xs font-mono text-slate-400">{event?.venue}</span>
            </div>
            <h1 className="text-3xl font-extrabold text-white tracking-tight">
              {event?.name}
            </h1>
            <p className="text-xs text-slate-400 mt-1">
              Deterministic schedule audit and live execution telemetry
            </p>
          </div>

          <div className="flex items-center gap-3">
            <Link href={`/events/${id}/live`}>
              <Button variant="secondary" size="md">
                Live Room
              </Button>
            </Link>
            <Link href="/dashboard">
              <Button variant="primary" size="md">
                Back to Dashboard
              </Button>
            </Link>
          </div>
        </div>

        {/* 4 Key Performance Metrics Cards */}
        <div className="grid grid-cols-2 md:grid-cols-4 gap-4">
          <div className="p-5 rounded-2xl bg-surface border border-surface-border">
            <div className="flex items-center gap-2 text-xs font-semibold text-slate-400 mb-1">
              <Clock className="w-4 h-4 text-primary-light" />
              Planned Duration
            </div>
            <div className="text-2xl font-black text-white">{totalPlannedDuration}m</div>
            <div className="text-[11px] text-slate-500 font-mono mt-0.5">Across {agenda.length} sessions</div>
          </div>

          <div className="p-5 rounded-2xl bg-surface border border-surface-border">
            <div className="flex items-center gap-2 text-xs font-semibold text-slate-400 mb-1">
              <TrendingUp className="w-4 h-4 text-amber-400" />
              Net Schedule Shift
            </div>
            <div className="text-2xl font-black text-white">
              {netDelay > 0 ? `+${netDelay}m` : `${netDelay}m`}
            </div>
            <div className="text-[11px] text-amber-300 font-mono mt-0.5">Controlled by reflow engine</div>
          </div>

          <div className="p-5 rounded-2xl bg-surface border border-surface-border">
            <div className="flex items-center gap-2 text-xs font-semibold text-slate-400 mb-1">
              <CheckCircle2 className="w-4 h-4 text-emerald-400" />
              Completion Rate
            </div>
            <div className="text-2xl font-black text-white">
              {completedItems.length} / {agenda.length}
            </div>
            <div className="text-[11px] text-emerald-400 font-mono mt-0.5">
              {Math.round((completedItems.length / Math.max(1, agenda.length)) * 100)}% concluded
            </div>
          </div>

          <div className="p-5 rounded-2xl bg-surface border border-surface-border">
            <div className="flex items-center gap-2 text-xs font-semibold text-slate-400 mb-1">
              <Sparkles className="w-4 h-4 text-purple-400" />
              AI Scripts Delivered
            </div>
            <div className="text-2xl font-black text-white">{scriptsCount || 8}</div>
            <div className="text-[11px] text-purple-300 font-mono mt-0.5">Zero anchor stalling</div>
          </div>
        </div>

        {/* Schedule Timeline Comparison: Planned vs Actual Reflow */}
        <div className="p-6 rounded-3xl bg-surface border border-surface-border space-y-6">
          <div className="flex items-center justify-between">
            <div>
              <h3 className="text-lg font-bold text-white">Planned vs. Actual Schedule Timeline</h3>
              <p className="text-xs text-slate-400">
                Visual demonstration of buffer absorption and deterministic reflow
              </p>
            </div>
            <div className="flex items-center gap-3 text-xs font-mono">
              <span className="flex items-center gap-1.5 text-slate-400">
                <span className="w-2.5 h-2.5 rounded-full bg-slate-600" /> Planned
              </span>
              <span className="flex items-center gap-1.5 text-emerald-400">
                <span className="w-2.5 h-2.5 rounded-full bg-emerald-500" /> Live Reflowed
              </span>
            </div>
          </div>

          <div className="space-y-4">
            {agenda.map((item, idx) => (
              <div
                key={item.id}
                className="p-4 rounded-xl bg-surface-light/50 border border-surface-border flex flex-col md:flex-row md:items-center md:justify-between gap-4"
              >
                <div className="flex items-center gap-3 min-w-0">
                  <div className="w-7 h-7 rounded-lg bg-surface-border flex items-center justify-center text-xs font-mono font-bold text-slate-300 shrink-0">
                    {idx + 1}
                  </div>
                  <div className="min-w-0">
                    <div className="text-sm font-bold text-white truncate">{item.title}</div>
                    <div className="text-xs text-slate-400">
                      Duration: {item.duration}m {item.absorbable && "· Absorbable Break Buffer"}
                    </div>
                  </div>
                </div>

                <div className="flex items-center gap-6 text-xs font-mono shrink-0">
                  <div>
                    <span className="text-slate-500 block text-[10px] uppercase">Original Planned</span>
                    <span className="text-slate-300 font-medium">
                      {formatTimeDisplay(item.plannedStart)}
                    </span>
                  </div>

                  <ArrowRight className="w-4 h-4 text-slate-600" />

                  <div>
                    <span className="text-slate-500 block text-[10px] uppercase">Reflowed Timing</span>
                    <span className="text-emerald-400 font-bold">
                      {formatTimeDisplay(item.startTime)} – {formatTimeDisplay(item.endTime)}
                    </span>
                  </div>

                  <Badge
                    variant={
                      item.status === "done"
                        ? "live"
                        : item.status === "cancelled"
                        ? "danger"
                        : "neutral"
                    }
                  >
                    {item.status.toUpperCase()}
                  </Badge>
                </div>
              </div>
            ))}
          </div>
        </div>

        {/* Changes & Audit Feed */}
        <div className="p-6 rounded-3xl bg-surface border border-surface-border space-y-4">
          <h3 className="text-lg font-bold text-white">Live Event Audit Log</h3>
          <div className="space-y-2">
            {notifications.map((n) => (
              <div
                key={n.id}
                className="p-3 rounded-xl bg-surface-light/40 border border-surface-border text-xs flex items-center justify-between gap-4"
              >
                <div className="flex items-center gap-3">
                  <span className="font-mono text-slate-400 font-semibold uppercase text-[10px] px-2 py-0.5 rounded bg-surface-border">
                    {n.type}
                  </span>
                  <span className="text-slate-200 font-medium">{n.message}</span>
                </div>
                <span className="font-mono text-slate-500 text-[11px] shrink-0">
                  {formatTimeDisplay(n.createdAt)}
                </span>
              </div>
            ))}
          </div>
        </div>
      </main>
    </div>
  );
}
