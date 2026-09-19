"use client";

import { useEffect, useState } from "react";
import { EventNotification } from "@/types/notification";
import { subscribeToNotifications } from "@/lib/syncClient";

export function useNotifications(eventId: string) {
  const [notifications, setNotifications] = useState<EventNotification[]>([]);
  const [unreadCount, setUnreadCount] = useState(0);

  useEffect(() => {
    if (!eventId) return;

    const unsubscribe = subscribeToNotifications(eventId, (notifs) => {
      setNotifications(notifs);
      setUnreadCount(notifs.filter((n) => !n.read).length);
    });

    return () => unsubscribe();
  }, [eventId]);

  const markAllAsRead = () => {
    setNotifications((prev) => prev.map((n) => ({ ...n, read: true })));
    setUnreadCount(0);
  };

  return { notifications, unreadCount, markAllAsRead };
}
