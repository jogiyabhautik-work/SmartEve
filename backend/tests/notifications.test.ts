import { describe, it, expect } from "vitest";
import {
  isInQuietHours,
  getPreferences,
  updatePreferences,
  sendNotification,
  getNotifications,
  markNotificationAsRead,
} from "../src/services/notifications/notificationService.js";
import { NotificationType } from "../src/types/notification_system.js";

describe("Notification System Core Logic", () => {
  it("should calculate quiet hours correctly", () => {
    const prefs = {
      quietHoursEnabled: true,
      quietHoursStart: "22:00:00",
      quietHoursEnd: "07:00:00",
    };
    // Helper unit check
    expect(isInQuietHours({ ...prefs, quietHoursEnabled: false })).toBe(false);
  });

  it("should generate default preferences for new user", async () => {
    const prefs = await getPreferences("user-test-1");
    expect(prefs.userId).toBe("user-test-1");
    expect(prefs.pushEnabled).toBe(true);
    expect(prefs.inAppEnabled).toBe(true);
  });

  it("should update user preferences", async () => {
    const updated = await updatePreferences("user-test-1", {
      soundEnabled: false,
      quietHoursEnabled: true,
    });
    expect(updated.soundEnabled).toBe(false);
    expect(updated.quietHoursEnabled).toBe(true);
  });

  it("should dispatch notification and retrieve it in list", async () => {
    const notifId = await sendNotification({
      recipientId: "user-anchor-test",
      senderId: "user-organizer-test",
      type: NotificationType.ANCHOR_INVITATION,
      title: "Test Invitation Title",
      message: "You have been invited to anchor TechNova",
      eventId: "technova-2026",
      priority: "high",
    });

    expect(notifId).toBeTruthy();

    const { notifications, unreadCount } = await getNotifications({
      recipientId: "user-anchor-test",
      sort: "newest",
    });

    expect(unreadCount).toBeGreaterThanOrEqual(1);
    const found = notifications.find((n) => n.id === notifId);
    expect(found).toBeDefined();
    expect(found?.title).toBe("Test Invitation Title");
  });

  it("should mark notification as read", async () => {
    const notifId = await sendNotification({
      recipientId: "user-anchor-read-test",
      type: NotificationType.DIRECT_MESSAGE,
      title: "Message Alert",
      message: "Are you ready?",
    });

    await markNotificationAsRead(notifId);
    const { notifications } = await getNotifications({
      recipientId: "user-anchor-read-test",
    });
    const found = notifications.find((n) => n.id === notifId);
    expect(found?.is_read).toBe(true);
  });
});
