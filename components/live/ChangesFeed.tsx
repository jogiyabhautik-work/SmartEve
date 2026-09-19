"use client";

import React from "react";
import { EventNotification } from "@/types/notification";
import { Badge } from "@/components/ui/badge";
import { formatTimeDisplay } from "@/lib/time";
import { History, Bell, AlertTriangle, CheckCircle, Megaphone, ArrowUpRight } from "lucide-react";

export interface ChangesFeedProps {
  notifications: EventNotification[];
}

export function ChangesFeed({ notifications }: ChangesFeedProps) {
  if (!notifications || notifications.length === 0) {
    return (
      <div className="bg-surface border border-surface-border rounded-2xl p-4 flex items-center justify-between text-xs text-slate-400">
        <div className="flex items-center gap-2">
          <History className="w-4 h-4 text-slate-500" />
          <span className="font-semibold text-slate-300">Live Schedule Audit Trail:</span>
          <span>No schedule changes yet. All sessions tracking on-time.</span>
        </div>
        <Badge variant="live">SYNCED</Badge>
      </div>
    );
  }

  return (
    <div className="bg-surface border border-surface-border rounded-2xl p-4 shadow-xl">
      <div className="flex items-center justify-between mb-3 border-b border-surface-border pb-2.5">
        <div className="flex items-center gap-2">
          <History className="w-4 h-4 text-primary" />
          <h4 className="text-xs font-bold uppercase tracking-wider text-slate-300">
            Live Changes & Reflow Audit Trail
          </h4>
        </div>
        <div className="flex items-center gap-2">
          <span className="text-[11px] font-mono text-slate-400">
            {notifications.length} updates logged
          </span>
          <Badge variant="neutral">REAL-TIME</Badge>
        </div>
      </div>

      <div className="flex gap-3 overflow-x-auto pb-1 scrollbar-thin">
        {notifications.slice(0, 8).map((notif) => {
          let icon = <Bell className="w-3.5 h-3.5 text-primary" />;
          let badgeVariant: "warning" | "live" | "danger" | "primary" | "neutral" = "neutral";

          if (notif.type === "delay") {
            icon = <AlertTriangle className="w-3.5 h-3.5 text-amber-400" />;
            badgeVariant = "warning";
          } else if (notif.type === "starting" || notif.type === "done") {
            icon = <CheckCircle className="w-3.5 h-3.5 text-emerald-400" />;
            badgeVariant = "live";
          } else if (notif.type === "announcement") {
            icon = <Megaphone className="w-3.5 h-3.5 text-indigo-400" />;
            badgeVariant = "primary";
          } else if (notif.type === "cancel") {
            icon = <AlertTriangle className="w-3.5 h-3.5 text-rose-400" />;
            badgeVariant = "danger";
          }

          return (
            <div
              key={notif.id}
              className="flex-shrink-0 w-80 p-3 rounded-xl bg-surface-light/60 border border-surface-border flex flex-col justify-between"
            >
              <div className="flex items-center justify-between gap-2 mb-1.5">
                <div className="flex items-center gap-1.5">
                  {icon}
                  <span className="text-[11px] font-bold uppercase text-slate-200">
                    {notif.type}
                  </span>
                </div>
                <span className="text-[10px] font-mono text-slate-400">
                  {formatTimeDisplay(notif.createdAt)}
                </span>
              </div>

              <div className="text-xs text-slate-300 font-medium line-clamp-2 mb-2">
                {notif.message}
              </div>

              {/* Specific shift count */}
              {notif.changes && notif.changes.length > 0 && (
                <div className="text-[10px] text-slate-400 font-mono pt-1 border-t border-surface-border/40 flex items-center justify-between">
                  <span>{notif.changes.length} sessions shifted</span>
                  <span className="text-indigo-400 flex items-center">
                    Reflowed <ArrowUpRight className="w-3 h-3" />
                  </span>
                </div>
              )}
            </div>
          );
        })}
      </div>
    </div>
  );
}
