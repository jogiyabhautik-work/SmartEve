"use client";

import React from "react";
import Link from "next/link";
import { usePathname } from "next/navigation";
import { useAuth } from "@/hooks/useAuth";
import { Badge } from "@/components/ui/badge";
import { Radio, Tv, Smartphone, LayoutDashboard, UserCheck, Sparkles } from "lucide-react";

export function Navbar({ eventId, joinCode = "TN26" }: { eventId?: string; joinCode?: string }) {
  const pathname = usePathname();
  const { user, switchRole } = useAuth();

  const currentEventId = eventId || "technova-2026";

  const isLiveActive = pathname.includes("/live");
  const isAnchorActive = pathname.includes("/anchor");
  const isStageActive = pathname.includes("/stage");

  return (
    <header className="sticky top-0 z-40 w-full border-b border-surface-border bg-background/80 backdrop-blur-md">
      <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 h-16 flex items-center justify-between">
        {/* Brand */}
        <div className="flex items-center gap-4">
          <Link href="/dashboard" className="flex items-center gap-2.5 group">
            <div className="w-9 h-9 rounded-xl bg-gradient-to-tr from-primary to-indigo-400 flex items-center justify-center text-white shadow-md shadow-primary/25">
              <Radio className="w-5 h-5 text-white animate-pulse" />
            </div>
            <div>
              <div className="flex items-center gap-2">
                <span className="font-bold tracking-tight text-white group-hover:text-primary-light transition-colors text-base">
                  SMART ANCHOR
                </span>
                <span className="text-[10px] uppercase font-mono px-1.5 py-0.5 rounded bg-primary/20 text-indigo-300 border border-primary/30">
                  Co-Pilot
                </span>
              </div>
            </div>
          </Link>
        </div>

        {/* Navigation items */}
        <nav className="hidden md:flex items-center gap-1.5">
          <Link
            href="/dashboard"
            className={`px-3 py-1.5 rounded-lg text-xs font-medium transition-colors flex items-center gap-1.5 ${
              pathname === "/dashboard"
                ? "bg-surface-light text-white border border-surface-border"
                : "text-slate-400 hover:text-white hover:bg-surface-light/50"
            }`}
          >
            <LayoutDashboard className="w-3.5 h-3.5" />
            Dashboard
          </Link>

          <Link
            href={`/events/${currentEventId}/live`}
            className={`px-3 py-1.5 rounded-lg text-xs font-medium transition-colors flex items-center gap-1.5 ${
              isLiveActive
                ? "bg-emerald-500/20 text-emerald-300 border border-emerald-500/30"
                : "text-slate-400 hover:text-white hover:bg-surface-light/50"
            }`}
          >
            <span className="w-2 h-2 rounded-full bg-emerald-400 animate-ping" />
            Live Control Room
          </Link>

          <Link
            href={`/events/${currentEventId}/anchor`}
            className={`px-3 py-1.5 rounded-lg text-xs font-medium transition-colors flex items-center gap-1.5 ${
              isAnchorActive
                ? "bg-primary/20 text-indigo-300 border border-primary/30"
                : "text-slate-400 hover:text-white hover:bg-surface-light/50"
            }`}
          >
            <Smartphone className="w-3.5 h-3.5" />
            Anchor Mobile View
          </Link>

          <Link
            href={`/stage/${joinCode}`}
            target="_blank"
            className={`px-3 py-1.5 rounded-lg text-xs font-medium transition-colors flex items-center gap-1.5 ${
              isStageActive
                ? "bg-amber-500/20 text-amber-300 border border-amber-500/30"
                : "text-slate-400 hover:text-white hover:bg-surface-light/50"
            }`}
          >
            <Tv className="w-3.5 h-3.5" />
            Stage Display
          </Link>
        </nav>

        {/* User & Role Switcher */}
        <div className="flex items-center gap-3">
          <div className="flex items-center gap-2 bg-surface px-3 py-1.5 rounded-xl border border-surface-border">
            <UserCheck className="w-4 h-4 text-slate-400" />
            <span className="text-xs text-slate-300 font-medium hidden sm:inline">
              {user?.name || "Alex Rivera"}
            </span>
            <select
              value={user?.role || "organizer"}
              onChange={(e) => switchRole(e.target.value as any)}
              className="bg-surface-light text-slate-200 text-xs font-semibold rounded-lg px-2 py-1 border border-surface-border focus:outline-none focus:ring-1 focus:ring-primary cursor-pointer"
            >
              <option value="organizer">Organizer</option>
              <option value="anchor">Anchor</option>
            </select>
          </div>
        </div>
      </div>
    </header>
  );
}
