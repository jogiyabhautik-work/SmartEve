import { ScheduleChange } from "./agenda.js";

export type NotificationType =
  | "delay"
  | "change"
  | "cancel"
  | "announcement"
  | "starting"
  | "done";

export type NotificationPriority = "normal" | "high" | "urgent";

export interface EventNotification {
  id: string;
  type: NotificationType;
  message: string;
  changes?: ScheduleChange[];
  createdBy: string;
  createdAt: number;
  priority: NotificationPriority;
  read?: boolean;
}
