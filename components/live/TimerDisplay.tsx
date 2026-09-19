"use client";

import React from "react";
import { Clock, AlertTriangle } from "lucide-react";

export interface TimerDisplayProps {
  formatted: string;
  isOvertime: boolean;
  minutes: number;
  remainingSeconds: number;
  progressPercent: number;
  size?: "default" | "huge" | "compact";
}

export function TimerDisplay({
  formatted,
  isOvertime,
  minutes,
  progressPercent,
  size = "default",
}: TimerDisplayProps) {
  // Color calculation:
  // Overtime -> Red
  // Less than 5 minutes -> Amber
  // Normal -> Emerald Green
  let colorClass = "text-emerald-400";
  let bgGlow = "bg-emerald-500/10 border-emerald-500/30 shadow-emerald-500/10";
  let barColor = "bg-emerald-500";

  if (isOvertime) {
    colorClass = "text-rose-400 animate-pulse";
    bgGlow = "bg-rose-500/15 border-rose-500/40 shadow-rose-500/20";
    barColor = "bg-rose-500";
  } else if (minutes < 5) {
    colorClass = "text-amber-400";
    bgGlow = "bg-amber-500/10 border-amber-500/30 shadow-amber-500/10";
    barColor = "bg-amber-500";
  }

  const fontSizes = {
    compact: "text-3xl font-extrabold tracking-tight",
    default: "text-5xl md:text-6xl font-black tracking-tight",
    huge: "text-7xl md:text-9xl font-black tracking-tight",
  };

  return (
    <div className={`flex flex-col items-center justify-center p-6 rounded-2xl border shadow-2xl transition-all duration-300 ${bgGlow}`}>
      <div className="flex items-center gap-2 mb-2 text-xs uppercase tracking-widest font-mono text-slate-400">
        {isOvertime ? (
          <span className="flex items-center gap-1.5 text-rose-400 font-bold">
            <AlertTriangle className="w-3.5 h-3.5 animate-bounce" />
            SESSION OVERTIME
          </span>
        ) : (
          <span className="flex items-center gap-1.5">
            <Clock className="w-3.5 h-3.5" />
            TIME REMAINING
          </span>
        )}
      </div>

      <div className={`font-mono tabular-nums select-none ${colorClass} ${fontSizes[size]}`}>
        {formatted}
      </div>

      {/* Progress Track */}
      <div className="w-full mt-4 bg-surface-border/70 rounded-full h-2 overflow-hidden">
        <div
          className={`h-full rounded-full transition-all duration-500 ${barColor}`}
          style={{ width: `${Math.min(100, Math.max(0, progressPercent))}%` }}
        />
      </div>
    </div>
  );
}
