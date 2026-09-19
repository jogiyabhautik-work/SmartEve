import React from "react";
import { clsx } from "clsx";
import { twMerge } from "tailwind-merge";

export function Skeleton({ className, ...props }: React.HTMLAttributes<HTMLDivElement>) {
  return (
    <div
      className={twMerge(
        clsx("animate-pulse rounded-lg bg-surface-border/50", className)
      )}
      {...props}
    />
  );
}

export function ControlRoomSkeleton() {
  return (
    <div className="grid grid-cols-1 lg:grid-cols-12 gap-6 w-full animate-pulse">
      <div className="lg:col-span-4 space-y-4">
        <Skeleton className="h-72 w-full rounded-2xl" />
        <Skeleton className="h-36 w-full rounded-2xl" />
      </div>
      <div className="lg:col-span-4 space-y-4">
        <Skeleton className="h-96 w-full rounded-2xl" />
      </div>
      <div className="lg:col-span-4 space-y-4">
        <Skeleton className="h-96 w-full rounded-2xl" />
      </div>
    </div>
  );
}
