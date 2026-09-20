import 'package:flutter/material.dart';

/// Who sent the message.
enum ChatSender { anchor, smartEve, system }

/// AI response rendering types from spec.
enum AiResponseType {
  text,
  scriptSuggestion,
  multipleChoice,
  actionRequired,
  reference,
  emergencyAck,
}

enum MessageStatus { sending, sent, read }

class QuickActionItem {
  final String id;
  final String label;
  final String prefilledMessage;
  final IconData icon;

  const QuickActionItem({
    required this.id,
    required this.label,
    required this.prefilledMessage,
    required this.icon,
  });

  static List<QuickActionItem> defaults() => const [
        QuickActionItem(
          id: 'paraphrase',
          label: 'Help me paraphrase my script',
          prefilledMessage: 'Help me paraphrase my current script to sound more natural',
          icon: Icons.edit_note_rounded,
        ),
        QuickActionItem(
          id: 'transition',
          label: 'Generate a transition',
          prefilledMessage: 'I need a transition between Speaker 1 and Speaker 2',
          icon: Icons.swap_horiz_rounded,
        ),
        QuickActionItem(
          id: 'engaging',
          label: 'Make this more engaging',
          prefilledMessage: 'Make my current script more engaging for the audience',
          icon: Icons.bolt_rounded,
        ),
        QuickActionItem(
          id: 'emergency',
          label: 'I need an emergency script',
          prefilledMessage: 'I completely forgot what to say! I need help NOW',
          icon: Icons.emergency_rounded,
        ),
        QuickActionItem(
          id: 'delay',
          label: 'How do I handle a delay?',
          prefilledMessage: 'Speaker is running 10 minutes late, what should I do?',
          icon: Icons.timer_outlined,
        ),
        QuickActionItem(
          id: 'delivery',
          label: 'Feedback on my delivery',
          prefilledMessage: 'Can you give me feedback on my delivery style?',
          icon: Icons.record_voice_over_rounded,
        ),
      ];
}

class ChatMessage {
  final String id;
  final ChatSender sender;
  final String text;
  final DateTime timestamp;
  final AiResponseType responseType;

  // Script suggestion payload
  final String? scriptText;
  final List<String>? refinementOptions;
  final List<String>? choiceOptions;
  final String? referenceTitle;
  final String? referenceRoute;
  final String? referenceCta;

  // Action-required payload
  final String? actionPrompt;
  final String? actionHint;

  // Feedback
  bool? wasHelpful;
  String? improvementNote;

  // User message status
  MessageStatus status;

  ChatMessage({
    required this.id,
    required this.sender,
    required this.text,
    DateTime? timestamp,
    this.responseType = AiResponseType.text,
    this.scriptText,
    this.refinementOptions,
    this.choiceOptions,
    this.referenceTitle,
    this.referenceRoute,
    this.referenceCta,
    this.actionPrompt,
    this.actionHint,
    this.wasHelpful,
    this.improvementNote,
    this.status = MessageStatus.sent,
  }) : timestamp = timestamp ?? DateTime.now();

  bool get isAnchor => sender == ChatSender.anchor;
  bool get isSystem => sender == ChatSender.system;

  String get formattedTime {
    final h = timestamp.hour > 12
        ? timestamp.hour - 12
        : (timestamp.hour == 0 ? 12 : timestamp.hour);
    final m = timestamp.minute.toString().padLeft(2, '0');
    final period = timestamp.hour >= 12 ? 'PM' : 'AM';
    return '$h:$m $period';
  }

  String toExportLine() {
    final who = sender == ChatSender.anchor
        ? 'Anchor'
        : sender == ChatSender.smartEve
            ? 'SmartEve AI'
            : 'System';
    final body = scriptText != null ? '$text\n--- Script ---\n$scriptText' : text;
    return '[$formattedTime] $who: $body';
  }
}

/// Lightweight analytics entry — surfaced to Organizer / Admin dashboards.
class AiUsageLog {
  final String id;
  final String requestType;
  final String prompt;
  final DateTime timestamp;
  final int responseTimeMs;
  final bool? wasHelpful;

  AiUsageLog({
    required this.id,
    required this.requestType,
    required this.prompt,
    required this.timestamp,
    required this.responseTimeMs,
    this.wasHelpful,
  });
}
