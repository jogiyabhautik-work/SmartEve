export enum NotificationType {
  ANCHOR_INVITATION = 'anchor_invitation',
  INVITATION_ACCEPTED = 'invitation_accepted',
  INVITATION_DECLINED = 'invitation_declined',
  SCRIPTS_GENERATED = 'scripts_generated',
  SCRIPTS_UPDATED = 'scripts_updated',
  SCRIPT_APPROVAL_REQUIRED = 'script_approval_required',
  SCRIPT_MODIFICATION_REQUEST = 'script_modification_request',
  AGENDA_UPDATED = 'agenda_updated',
  SPEAKER_ADDED = 'speaker_added',
  EVENT_DELAY = 'event_delay',
  DELAY_APPROVED = 'delay_approved',
  DIRECT_MESSAGE = 'direct_message',
  EVENT_REMINDER = 'event_reminder',
  EVENT_LIVE = 'event_live',
  ANCHOR_READY = 'anchor_ready',
  ANNOUNCEMENT = 'announcement',
  EMERGENCY_SOS = 'emergency_sos',
  NEXT_ACTIVITY = 'next_activity',
  SCRIPT_READY = 'script_ready',
  EVENT_COMPLETED = 'event_completed',
  ORGANIZER_FEEDBACK = 'organizer_feedback',
  ANCHOR_NOT_RESPONDING = 'anchor_not_responding',
  ENGAGEMENT_ALERT = 'engagement_alert',
}

export type PriorityLevel = 'low' | 'medium' | 'high' | 'urgent';

export interface NotificationPayload {
  recipientId: string;
  senderId?: string;
  type: NotificationType | string;
  title: string;
  message: string;
  data?: Record<string, any>;
  priority?: PriorityLevel;
  recipientRole?: 'organizer' | 'anchor' | 'admin';
  actionUrl?: string;
  actionType?: string;
  eventId?: string;
  anchorId?: string;
  organizerId?: string;
  speakerId?: string;
  scheduledFor?: Date;
}

export interface NotificationPreferences {
  userId: string;
  pushEnabled: boolean;
  inAppEnabled: boolean;
  emailEnabled: boolean;
  invitationsEnabled: boolean;
  messagesEnabled: boolean;
  updatesEnabled: boolean;
  announcementsEnabled: boolean;
  alertsEnabled: boolean;
  remindersEnabled: boolean;
  soundEnabled: boolean;
  vibrationEnabled: boolean;
  quietHoursEnabled: boolean;
  quietHoursStart: string;
  quietHoursEnd: string;
  quietHoursTimezone: string;
  dailyDigestEnabled: boolean;
  digestTime: string;
}

export interface PushTokenRecord {
  id?: string;
  userId: string;
  deviceId: string;
  deviceType: 'ios' | 'android' | 'web';
  fcmToken: string;
  isActive: boolean;
  createdAt?: Date;
  lastUsedAt?: Date;
}
