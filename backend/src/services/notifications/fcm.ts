import { adminMessaging } from "../../config/firebaseAdmin.js";
import { EventNotification } from "../../types/notification.js";

/**
 * Dispatches real-time push notifications to mobile devices via Firebase Cloud Messaging (FCM)
 */
export async function sendFcmNotification(
  eventId: string,
  notification: EventNotification
): Promise<boolean> {
  if (!adminMessaging) {
    console.log(`ℹ️ [FCM MOCK] Push notification to event topic "event-${eventId}": ${notification.message}`);
    return false;
  }

  try {
    const topic = `event-${eventId}`;

    await adminMessaging.send({
      topic,
      notification: {
        title: notification.type === "delay" ? "⚠️ Schedule Delay Alert" : "📢 Stage Notice",
        body: notification.message,
      },
      data: {
        eventId,
        notificationId: notification.id,
        type: notification.type,
        priority: notification.priority,
        createdAt: String(notification.createdAt),
      },
      android: {
        priority: notification.priority === "urgent" ? "high" : "normal",
        notification: {
          channelId: "smarteve_stage_alerts",
          sound: "default",
        },
      },
      apns: {
        payload: {
          aps: {
            sound: "default",
            badge: 1,
          },
        },
      },
    });

    console.log(`📡 [FCM] Broadcasted message to topic "${topic}"`);
    return true;
  } catch (err) {
    console.warn("FCM dispatch failed:", (err as Error).message);
    return false;
  }
}
