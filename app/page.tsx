"use client";

import React from "react";
import Link from "next/link";
import { Radio, Tv, Smartphone, Cpu, ShieldCheck, Zap, ArrowRight, Play, Sparkles } from "lucide-react";
import { Button } from "@/components/ui/button";
import { Badge } from "@/components/ui/badge";

export default function HomePage() {
  return (
    <div className="min-h-screen bg-background text-slate-100 flex flex-col justify-between">
      {/* Navbar Minimal */}
      <header className="border-b border-surface-border bg-background/80 backdrop-blur-md sticky top-0 z-50">
        <div className="max-w-7xl mx-auto px-4 sm:px-6 h-16 flex items-center justify-between">
          <div className="flex items-center gap-3">
            <div className="w-9 h-9 rounded-xl bg-gradient-to-tr from-primary to-indigo-400 flex items-center justify-center text-white shadow-md shadow-primary/25">
              <Radio className="w-5 h-5 text-white animate-pulse" />
            </div>
            <div className="flex items-center gap-2">
              <span className="font-bold tracking-tight text-white text-base">SMART ANCHOR</span>
              <span className="text-[10px] uppercase font-mono px-1.5 py-0.5 rounded bg-primary/20 text-indigo-300 border border-primary/30">
                Co-Pilot
              </span>
            </div>
          </div>

          <div className="flex items-center gap-3">
            <Link href="/(auth)/login">
              <Button variant="ghost" size="sm">
                Log In
              </Button>
            </Link>
            <Link href="/dashboard">
              <Button variant="primary" size="sm">
                Dashboard
              </Button>
            </Link>
          </div>
        </div>
      </header>

      {/* Hero Section */}
      <main className="max-w-7xl mx-auto px-4 sm:px-6 py-16 md:py-24 my-auto">
        <div className="text-center max-w-3xl mx-auto mb-14">
          <Badge variant="live" pulse={true} className="mb-4 text-xs py-1 px-3">
            HACKATHON FLAGSHIP MVP
          </Badge>

          <h1 className="text-4xl md:text-6xl font-black text-white tracking-tight leading-tight mb-6">
            Your Live Event&apos;s <br />
            <span className="text-transparent bg-clip-text bg-gradient-to-r from-primary-light via-indigo-300 to-emerald-400">
              Deterministic Co-Pilot
            </span>
          </h1>

          <p className="text-base md:text-xl text-slate-300 leading-relaxed mb-8">
            One live source of truth. When an organizer adds a +15 min delay, the Anchor teleprompter, Stage projector display, countdown timers, and notifications adjust synchronously in real-time.
          </p>

          {/* Quick Launch Buttons for Hackathon Judges */}
          <div className="flex flex-wrap items-center justify-center gap-4">
            <Link href="/events/technova-2026/live">
              <Button variant="live" size="lg" className="font-bold shadow-xl shadow-emerald-500/20">
                <Play className="w-5 h-5 mr-2" />
                Launch Live Control Room
              </Button>
            </Link>

            <Link href="/events/technova-2026/anchor">
              <Button variant="primary" size="lg" className="font-bold">
                <Smartphone className="w-5 h-5 mr-2" />
                Anchor Mobile View
              </Button>
            </Link>

            <Link href="/stage/TN26" target="_blank">
              <Button variant="secondary" size="lg">
                <Tv className="w-5 h-5 mr-2" />
                Stage Display (/stage/TN26)
              </Button>
            </Link>
          </div>
        </div>

        {/* Feature Grid Highlighting Differentiators */}
        <div className="grid grid-cols-1 md:grid-cols-3 gap-6 max-w-5xl mx-auto">
          {/* Card 1 */}
          <div className="p-6 rounded-2xl bg-surface border border-surface-border shadow-xl space-y-3">
            <div className="w-10 h-10 rounded-xl bg-emerald-500/15 border border-emerald-500/30 flex items-center justify-center text-emerald-400">
              <Cpu className="w-5 h-5" />
            </div>
            <h3 className="text-lg font-bold text-white">Deterministic Reflow</h3>
            <p className="text-xs text-slate-400 leading-relaxed">
              Mathematical schedule recalculation. Absorbable breaks cushion delays without moving major keynotes unnecessarily. Zero schedule drift.
            </p>
          </div>

          {/* Card 2 */}
          <div className="p-6 rounded-2xl bg-surface border border-surface-border shadow-xl space-y-3">
            <div className="w-10 h-10 rounded-xl bg-primary/15 border border-primary/30 flex items-center justify-center text-primary-light">
              <Zap className="w-5 h-5" />
            </div>
            <h3 className="text-lg font-bold text-white">One Live Source of Truth</h3>
            <p className="text-xs text-slate-400 leading-relaxed">
              Real-time multi-device sync via Firestore onSnapshot. Derived timers survive tab closes, phone reloads, and network hiccups.
            </p>
          </div>

          {/* Card 3 */}
          <div className="p-6 rounded-2xl bg-surface border border-surface-border shadow-xl space-y-3">
            <div className="w-10 h-10 rounded-xl bg-purple-500/15 border border-purple-500/30 flex items-center justify-center text-purple-300">
              <Sparkles className="w-5 h-5" />
            </div>
            <h3 className="text-lg font-bold text-white">Fail-Safe AI Assistant</h3>
            <p className="text-xs text-slate-400 leading-relaxed">
              Triple fallback cascade: Gemini &rarr; Groq &rarr; Contextual Templates &rarr; Manual. Never strands the anchor even during API outages.
            </p>
          </div>
        </div>
      </main>

      {/* Footer */}
      <footer className="border-t border-surface-border py-6 text-center text-xs text-slate-500">
        Smart Anchor & Stage Flow · 48-Hour Hackathon Flagship Project · Built for Real-time Stage Management
      </footer>
    </div>
  );
}
