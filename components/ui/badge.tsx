import React from "react";
import { clsx } from "clsx";
import { twMerge } from "tailwind-merge";

export interface BadgeProps extends React.HTMLAttributes<HTMLSpanElement> {
  variant?: "live" | "warning" | "danger" | "primary" | "neutral" | "ai" | "template" | "manual";
  pulse?: boolean;
}

export function Badge({ className, variant = "neutral", pulse = false, children, ...props }: BadgeProps) {
  const base = "inline-flex items-center font-medium rounded-full px-2.5 py-0.5 text-xs select-none gap-1.5";

  const variants = {
    live: "bg-emerald-500/15 text-emerald-400 border border-emerald-500/30",
    warning: "bg-amber-500/15 text-amber-400 border border-amber-500/30",
    danger: "bg-rose-500/15 text-rose-400 border border-rose-500/30",
    primary: "bg-indigo-500/15 text-indigo-400 border border-indigo-500/30",
    neutral: "bg-slate-800 text-slate-300 border border-slate-700",
    ai: "bg-gradient-to-r from-indigo-500/20 to-purple-500/20 text-indigo-300 border border-indigo-500/40 font-semibold",
    template: "bg-cyan-500/15 text-cyan-300 border border-cyan-500/30",
    manual: "bg-zinc-700/50 text-zinc-300 border border-zinc-600",
  };

  return (
    <span className={twMerge(clsx(base, variants[variant], className))} {...props}>
      {pulse && (
        <span className="relative flex h-2 w-2">
          <span className="animate-ping absolute inline-flex h-full w-full rounded-full bg-current opacity-75"></span>
          <span className="relative inline-flex rounded-full h-2 w-2 bg-current"></span>
        </span>
      )}
      {children}
    </span>
  );
}
