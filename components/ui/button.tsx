"use client";

import React from "react";
import { clsx } from "clsx";
import { twMerge } from "tailwind-merge";
import { Loader2 } from "lucide-react";

export interface ButtonProps extends React.ButtonHTMLAttributes<HTMLButtonElement> {
  variant?: "primary" | "secondary" | "danger" | "ghost" | "outline" | "live" | "amber";
  size?: "sm" | "md" | "lg" | "touch";
  isLoading?: boolean;
}

export const Button = React.forwardRef<HTMLButtonElement, ButtonProps>(
  ({ className, variant = "primary", size = "md", isLoading, children, disabled, ...props }, ref) => {
    const baseStyles =
      "inline-flex items-center justify-center font-medium rounded-xl transition-all duration-150 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-offset-background disabled:opacity-50 disabled:cursor-not-allowed select-none active:scale-[0.98]";

    const variants = {
      primary: "bg-primary hover:bg-primary-hover text-white shadow-lg shadow-primary/20 focus:ring-primary",
      secondary: "bg-surface-light hover:bg-surface-border text-slate-200 border border-surface-border focus:ring-slate-500",
      danger: "bg-danger hover:bg-red-600 text-white shadow-lg shadow-danger/20 focus:ring-danger",
      live: "bg-live hover:bg-emerald-600 text-black font-semibold shadow-lg shadow-live/25 focus:ring-live",
      amber: "bg-amber-500 hover:bg-amber-600 text-black font-semibold shadow-lg shadow-amber-500/20 focus:ring-amber-500",
      outline: "border border-surface-border hover:bg-surface-light text-slate-300 focus:ring-primary",
      ghost: "hover:bg-surface-light text-slate-300 focus:ring-slate-400",
    };

    const sizes = {
      sm: "text-xs px-3 py-1.5 h-8 gap-1.5",
      md: "text-sm px-4 py-2 h-10 gap-2",
      lg: "text-base px-6 py-2.5 h-12 gap-2.5",
      touch: "text-base px-6 py-3.5 h-14 min-h-[52px] font-semibold gap-3", // Touch target >= 52px for Anchor mobile view
    };

    return (
      <button
        ref={ref}
        disabled={disabled || isLoading}
        className={twMerge(clsx(baseStyles, variants[variant], sizes[size], className))}
        {...props}
      >
        {isLoading && <Loader2 className="w-4 h-4 animate-spin text-current" />}
        {children}
      </button>
    );
  }
);

Button.displayName = "Button";
