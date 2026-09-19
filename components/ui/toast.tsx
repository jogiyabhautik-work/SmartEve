"use client";

import React, { useState, useEffect } from "react";
import { CheckCircle2, AlertTriangle, Info, X } from "lucide-react";

export interface ToastItem {
  id: string;
  type: "success" | "warning" | "error" | "info";
  message: string;
}

let toastDispatch: ((toast: Omit<ToastItem, "id">) => void) | null = null;

export function notify(toast: Omit<ToastItem, "id">) {
  if (toastDispatch) {
    toastDispatch(toast);
  }
}

export function ToastContainer() {
  const [toasts, setToasts] = useState<ToastItem[]>([]);

  useEffect(() => {
    toastDispatch = (t) => {
      const id = String(Date.now() + Math.random());
      setToasts((prev) => [...prev, { ...t, id }]);
      setTimeout(() => {
        setToasts((prev) => prev.filter((item) => item.id !== id));
      }, 4000);
    };

    return () => {
      toastDispatch = null;
    };
  }, []);

  if (toasts.length === 0) return null;

  return (
    <div className="fixed bottom-5 right-5 z-50 flex flex-col gap-2.5 max-w-sm w-full pointer-events-none">
      {toasts.map((t) => (
        <div
          key={t.id}
          className="pointer-events-auto flex items-start gap-3 p-4 rounded-xl border shadow-xl bg-surface border-surface-border text-white text-sm animate-in slide-in-from-bottom-5 fade-in duration-200"
        >
          {t.type === "success" && <CheckCircle2 className="w-5 h-5 text-emerald-400 shrink-0 mt-0.5" />}
          {t.type === "warning" && <AlertTriangle className="w-5 h-5 text-amber-400 shrink-0 mt-0.5" />}
          {t.type === "error" && <AlertTriangle className="w-5 h-5 text-rose-400 shrink-0 mt-0.5" />}
          {t.type === "info" && <Info className="w-5 h-5 text-indigo-400 shrink-0 mt-0.5" />}
          <div className="flex-1 font-medium text-slate-100">{t.message}</div>
          <button
            onClick={() => setToasts((prev) => prev.filter((item) => item.id !== t.id))}
            className="text-slate-400 hover:text-white shrink-0 p-0.5"
          >
            <X className="w-4 h-4" />
          </button>
        </div>
      ))}
    </div>
  );
}
