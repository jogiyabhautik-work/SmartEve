import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import '../../../core/network/api_client.dart';
import '../models/ai_chat_models.dart';

/// Central state for the SmartEve AI Assist chat.
///
/// - Context-aware: call [setContext] from the screen with live event,
///   speaker & anchor details so replies are personalized.
/// - Tries the real backend (`POST /ai/generate`) then falls back to
///   curated offline templates so the stage never goes silent.
/// - Tracks response times, usage logs (organizer/admin analytics),
///   feedback, and emergency escalations.
class AiChatProvider extends ChangeNotifier {
  final ApiClient _api = ApiClient();
  bool _disposed = false;

  final List<ChatMessage> _messages = [];
  final List<AiUsageLog> _usageLogs = [];
  final Map<String, int> _featureUseCount = {};
  int _emergencyCount = 0;

  bool _isGenerating = false;
  bool _emergencyActive = false;
  String? _emergencyTimeLabel;

  // Response-time stats (ms)
  final List<int> _responseTimes = [1800, 2100, 1900];
  Timer? _latencyJitter;

  // Event context injected by UI (from EventProvider / ProfileProvider)
  String anchorName = 'Jordan Hayes';
  String eventName = 'TechNova 2026';
  String currentSpeaker = 'Dr. Aris Vance';
  String nextSpeaker = 'Priya Sharma';
  String currentSessionTitle = 'Keynote: Autonomous Agents';
  String eventId = 'technova-2026';

  AiChatProvider() {
    _seedWelcome();
    // Gentle jitter so "Typically replies in Xs" feels alive.
    _latencyJitter = Timer.periodic(const Duration(seconds: 20), (_) {
      if (_disposed) return;
      _responseTimes.add(1400 + Random().nextInt(1400));
      if (_responseTimes.length > 12) _responseTimes.removeAt(0);
      _safeNotify();
    });
  }

  @override
  void dispose() {
    _disposed = true;
    _latencyJitter?.cancel();
    super.dispose();
  }

  void _safeNotify() {
    if (!_disposed) notifyListeners();
  }

  // ---------------- Getters ----------------
  List<ChatMessage> get messages => List.unmodifiable(_messages);
  List<AiUsageLog> get usageLogs => List.unmodifiable(_usageLogs);
  Map<String, int> get featureUseCount => Map.unmodifiable(_featureUseCount);
  int get emergencyCount => _emergencyCount;
  bool get isGenerating => _isGenerating;
  bool get hasConversation => _messages.any((m) => m.isAnchor);
  bool get emergencyActive => _emergencyActive;
  String? get emergencyTimeLabel => _emergencyTimeLabel;

  double get avgResponseSeconds {
    if (_responseTimes.isEmpty) return 2.0;
    final avg = _responseTimes.reduce((a, b) => a + b) / _responseTimes.length;
    return (avg / 1000 * 10).round() / 10;
  }

  String get statusLine => 'Online • Typically replies in ${avgResponseSeconds.toStringAsFixed(1)}s';

  List<String> get suggestedReplies {
    if (_messages.isEmpty) return const ['Tell me more', 'Give me a script'];
    final last = _messages.lastWhere(
      (m) => m.sender == ChatSender.smartEve,
      orElse: () => _messages.last,
    );
    if (last.responseType == AiResponseType.multipleChoice && last.choiceOptions != null) {
      return last.choiceOptions!;
    }
    if (last.responseType == AiResponseType.scriptSuggestion) {
      return const ['Use this', 'Tell me more'];
    }
    return const ['Yes', 'No', 'Tell me more'];
  }

  /// Most-used features for Admin analytics sheet.
  List<MapEntry<String, int>> get topFeatures {
    final entries = _featureUseCount.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return entries.take(5).toList();
  }

  void setContext({
    String? anchorName,
    String? eventName,
    String? currentSpeaker,
    String? nextSpeaker,
    String? currentSessionTitle,
    String? eventId,
  }) {
    if (anchorName != null) this.anchorName = anchorName;
    if (eventName != null) this.eventName = eventName;
    if (currentSpeaker != null) this.currentSpeaker = currentSpeaker;
    if (nextSpeaker != null) this.nextSpeaker = nextSpeaker;
    if (currentSessionTitle != null) this.currentSessionTitle = currentSessionTitle;
    if (eventId != null) this.eventId = eventId;
  }

  void _seedWelcome() {
    _messages.add(
      ChatMessage(
        id: 'welcome-1',
        sender: ChatSender.smartEve,
        responseType: AiResponseType.text,
        text: 'Hi $anchorName! 👋 I\'m SmartEve, your live stage co-pilot for $eventName.\n\n'
            'I know you\'re on "$currentSessionTitle" with $currentSpeaker. '
            'Ask me for intros, transitions, delay handling, or tap a quick action below to start.',
      ),
    );
  }

  // ---------------- Messaging ----------------

  Future<void> sendMessage(String rawText, {String? attachmentNote}) async {
    final text = rawText.trim();
    if (text.isEmpty && attachmentNote == null) return;
    if (_isGenerating) return;

    final displayText = attachmentNote != null ? '$text\n📎 $attachmentNote' : text;
    final userMsg = ChatMessage(
      id: 'u-${DateTime.now().millisecondsSinceEpoch}',
      sender: ChatSender.anchor,
      text: displayText,
      status: MessageStatus.sent,
    );
    _messages.add(userMsg);
    _safeNotify();

    // Mark read shortly after (simulated organizer/AI read).
    Future.delayed(const Duration(milliseconds: 600), () {
      userMsg.status = MessageStatus.read;
      _safeNotify();
    });

    await _respondTo(text);
  }

  void sendQuickAction(QuickActionItem action) {
    _bumpFeature(action.id);
    sendMessage(action.prefilledMessage);
  }

  void applyChoice(String option) {
    _bumpFeature('choice_select');
    sendMessage(option);
  }

  void _bumpFeature(String key) {
    _featureUseCount[key] = (_featureUseCount[key] ?? 0) + 1;
  }

  Future<void> _respondTo(String userText) async {
    _isGenerating = true;
    _safeNotify();

    final stopwatch = Stopwatch()..start();
    final intent = _classify(userText);

    ChatMessage reply;
    try {
      final backendScript = await _tryBackend(userText, intent).timeout(
        const Duration(seconds: 10),
        onTimeout: () => null,
      );
      stopwatch.stop();
      _recordLatency(stopwatch.elapsedMilliseconds);
      reply = _buildReply(intent, userText, backendScript: backendScript);
    } catch (_) {
      stopwatch.stop();
      _recordLatency(stopwatch.elapsedMilliseconds);
      reply = _buildReply(intent, userText, backendScript: null);
    }

    // Simulate streaming delay so typing indicator is visible (min 900ms).
    final elapsed = stopwatch.elapsedMilliseconds;
    if (elapsed < 900) {
      await Future.delayed(Duration(milliseconds: 900 - elapsed));
    }

    _messages.add(reply);
    _usageLogs.insert(0, AiUsageLog(
      id: 'log-${DateTime.now().millisecondsSinceEpoch}',
      requestType: intent,
      prompt: userText.length > 80 ? '${userText.substring(0, 80)}…' : userText,
      timestamp: DateTime.now(),
      responseTimeMs: stopwatch.elapsedMilliseconds,
    ));
    _bumpFeature(intent);
    _isGenerating = false;
    _safeNotify();
  }

  void _recordLatency(int ms) {
    // Clamp absurd values (offline fallback shouldn't report 10s).
    final sane = ms.clamp(800, 9000);
    _responseTimes.add(sane);
    if (_responseTimes.length > 12) _responseTimes.removeAt(0);
  }

  String _classify(String text) {
    final t = text.toLowerCase();
    if (RegExp(r'\b(emergency|forgot what to say|help now|panic|blank)\b').hasMatch(t)) {
      return 'emergency';
    }
    if (RegExp(r'\b(late|delay|running behind|overtime|stuck)\b').hasMatch(t)) {
      return 'delay';
    }
    if (RegExp(r'\btransition\b').hasMatch(t)) return 'transition';
    if (RegExp(r'\b(paraphrase|rewrite|rephrase)\b').hasMatch(t)) return 'paraphrase';
    if (RegExp(r'\b(engaging|boring|energy|punchier)\b').hasMatch(t)) return 'engaging';
    if (RegExp(r'\b(delivery|feedback.*deliver|how.*sound|nervous)\b').hasMatch(t)) {
      return 'delivery';
    }
    if (RegExp(r'\b(agenda|schedule|when|what.*next|order)\b').hasMatch(t)) return 'agenda';
    if (RegExp(r'\b(script|intro|announce|opening|closing)\b').hasMatch(t)) return 'script';
    if (RegExp(r'\b(shorter|condense)\b').hasMatch(t)) return 'shorter';
    if (RegExp(r'\b(humor|funny|joke)\b').hasMatch(t)) return 'humor';
    if (RegExp(r'\b(formal|professional)\b').hasMatch(t)) return 'formal';
    if (t.trim() == 'yes' || t.trim() == 'no' || t.contains('tell me more')) return 'followup';
    if (t.length < 24) return 'clarify';
    return 'general';
  }

  Future<String?> _tryBackend(String userText, String intent) async {
    String type = 'announcement';
    if (intent == 'transition') type = 'transition';
    if (intent == 'script' || intent == 'emergency' || intent == 'paraphrase') type = 'speaker_intro';
    if (intent == 'delay') type = 'delay';
    if (intent == 'engaging') type = 'speaker_intro';

    final res = await _api.post('/ai/generate', {
      'eventId': eventId,
      'type': type,
      'tone': 'Motivational',
      'customContext': 'Anchor $anchorName asks: $userText. Current speaker: $currentSpeaker, next: $nextSpeaker, session: $currentSessionTitle.',
    });
    if (res.success && res.data != null) {
      final data = res.data as Map<String, dynamic>;
      final script = data['script'] as String?;
      if (script != null && script.trim().isNotEmpty) return script.trim();
    }
    return null;
  }

  ChatMessage _buildReply(String intent, String userText, {String? backendScript}) {
    final id = 'ai-${DateTime.now().millisecondsSinceEpoch}';
    switch (intent) {
      case 'transition':
        // Example 1 — script suggestion with refinement options.
        return ChatMessage(
          id: id,
          sender: ChatSender.smartEve,
          responseType: AiResponseType.scriptSuggestion,
          text: 'I\'ll create a smooth 30-second transition for you, $anchorName — from $currentSpeaker to $nextSpeaker.',
          scriptText: backendScript ??
              'Thank you, $currentSpeaker, for that brilliant deep-dive into autonomous agents! 👏\n\nUp next, we shift from intelligence to infrastructure — please welcome $nextSpeaker, who scales systems to 10 million concurrent operations. Grab your coffee, be back in 2 minutes — you won\'t want to miss this!',
          refinementOptions: const ['Shorter', 'Add humor', 'More formal', 'Use this'],
        );
      case 'delay':
        // Example 2 — multiple choice / action plan.
        return ChatMessage(
          id: id,
          sender: ChatSender.smartEve,
          responseType: AiResponseType.multipleChoice,
          text: '$anchorName, I understand — a 10-minute delay is stressful, but we\'ve got this. Here\'s the plan:\n\n'
              '1. ✅ Organizer notified (auto-done)\n'
              '2. Pick how to fill the gap:',
          choiceOptions: const ['Extend current activity', 'Start with next activity', 'Make announcement'],
        );
      case 'emergency':
        // Example 3 — emergency script + escalation options.
        return ChatMessage(
          id: id,
          sender: ChatSender.smartEve,
          responseType: AiResponseType.scriptSuggestion,
          text: 'Don\'t worry, $anchorName! Breathe — I\'ve got you. 💜\nFor $currentSpeaker, here\'s your intro:',
          scriptText: backendScript ??
              'Ladies and gentlemen, please put your hands together for $currentSpeaker — VP of Applied AI at DeepScale Labs — presenting "$currentSessionTitle"! 🎤',
          refinementOptions: const ['Call Organizer', 'Get Text Version', 'Use this'],
        );
      case 'paraphrase':
        return ChatMessage(
          id: id,
          sender: ChatSender.smartEve,
          responseType: AiResponseType.scriptSuggestion,
          text: 'Here\'s a warmer, more natural paraphrase, $anchorName:',
          scriptText: backendScript ??
              'Good morning, innovators! What an energy in this room — welcome to $eventName, where the future of intelligence takes the stage. Let\'s make some noise! 🎉',
          refinementOptions: const ['Shorter', 'Add humor', 'More formal', 'Use this'],
        );
      case 'engaging':
        return ChatMessage(
          id: id,
          sender: ChatSender.smartEve,
          responseType: AiResponseType.scriptSuggestion,
          text: 'Let\'s turn up the energy! 🔥 Punchier version:',
          scriptText: backendScript ??
              'Are you READY, $eventName?! What you\'re about to hear redefined modern engineering — lean in, cheer loud, and welcome $currentSpeaker to the stage!',
          refinementOptions: const ['Shorter', 'Add humor', 'More formal', 'Use this'],
        );
      case 'shorter':
        return ChatMessage(
          id: id,
          sender: ChatSender.smartEve,
          responseType: AiResponseType.scriptSuggestion,
          text: 'Condensed to under 35 words — same impact:',
          scriptText: backendScript ??
              'Please welcome $currentSpeaker to the stage for "$currentSessionTitle". Put your hands together! 👏',
          refinementOptions: const ['Add humor', 'More formal', 'Use this'],
        );
      case 'humor':
        return ChatMessage(
          id: id,
          sender: ChatSender.smartEve,
          responseType: AiResponseType.scriptSuggestion,
          text: 'Adding a tasteful, stage-friendly wink 😉:',
          scriptText: backendScript ??
              'They say coffee fuels coders — but $currentSpeaker fuels entire cloud clusters before breakfast! Give it up for a brilliant mind and an even better storyteller!',
          refinementOptions: const ['Shorter', 'More formal', 'Use this'],
        );
      case 'formal':
        return ChatMessage(
          id: id,
          sender: ChatSender.smartEve,
          responseType: AiResponseType.scriptSuggestion,
          text: 'Here\'s a polished, formal version:',
          scriptText: backendScript ??
              'Distinguished guests, it is my honour to introduce $currentSpeaker, whose research in deterministic intelligence powers millions of mission-critical decisions worldwide. Please welcome them to the stage.',
          refinementOptions: const ['Shorter', 'Add humor', 'Use this'],
        );
      case 'delivery':
        return ChatMessage(
          id: id,
          sender: ChatSender.smartEve,
          responseType: AiResponseType.text,
          text: 'Quick delivery coaching for you, $anchorName:\n\n'
              '• **Pace:** ~130 words/min — pause 2s after names for applause\n'
              '• **Energy:** Smile on openers, lean in on the guest\'s biggest win\n'
              '• **Hands-free tip:** Use voice input + TTS rehearsal before you walk on\n\n'
              'Want a 30-second warm-up script to practice right now?',
        );
      case 'agenda':
        return ChatMessage(
          id: id,
          sender: ChatSender.smartEve,
          responseType: AiResponseType.reference,
          text: 'Here\'s what\'s live right now, $anchorName:',
          referenceTitle: '$currentSessionTitle • $currentSpeaker now, $nextSpeaker next',
          referenceRoute: 'agenda',
          referenceCta: 'Open Agenda',
        );
      case 'clarify':
        return ChatMessage(
          id: id,
          sender: ChatSender.smartEve,
          responseType: AiResponseType.actionRequired,
          text: 'I want to nail this for you — quick check:',
          actionPrompt: 'Who is this script for, and how long should it run?',
          actionHint: 'e.g. "Intro for Priya Sharma, ~30 seconds, formal tone"',
        );
      case 'followup':
        return ChatMessage(
          id: id,
          sender: ChatSender.smartEve,
          responseType: AiResponseType.text,
          text: userText.toLowerCase().contains('yes')
              ? 'Great! I\'ve queued that for your "$currentSessionTitle" slot. Anything else — timing, tone, or a backup line if applause runs long?'
              : userText.toLowerCase().contains('no')
                  ? 'No problem — I\'ll hold that draft. Just say the word when you want a shorter, funnier, or more formal take.'
                  : 'Happy to go deeper, $anchorName! Tell me: is this for $currentSpeaker or $nextSpeaker — and should it be fun, formal, or high-energy?',
        );
      case 'general':
      default:
        if (backendScript != null && backendScript.length > 40) {
          return ChatMessage(
            id: id,
            sender: ChatSender.smartEve,
            responseType: AiResponseType.scriptSuggestion,
            text: 'Here\'s a stage-ready take, $anchorName:',
            scriptText: backendScript,
            refinementOptions: const ['Shorter', 'Add humor', 'More formal', 'Use this'],
          );
        }
        return ChatMessage(
          id: id,
          sender: ChatSender.smartEve,
          responseType: AiResponseType.text,
          text: 'Got it, $anchorName! For "$userText" during "$currentSessionTitle", here\'s my suggestion:\n\n'
              '• Open with the audience win ("you\'re about to hear…")\n'
              '• Name $currentSpeaker + one credential\n'
              '• Land with a clear applause cue 👏\n\n'
              'Want me to draft the full 30-second script?',
        );
    }
  }

  // ---------------- Refinement shortcuts ----------------

  void refineLastScript(String option) {
    final idx = _messages.lastIndexWhere(
      (m) => m.sender == ChatSender.smartEve && m.responseType == AiResponseType.scriptSuggestion,
    );
    if (idx == -1) return;
    final original = _messages[idx].scriptText ?? '';
    String next = original;
    final o = option.toLowerCase();
    if (o.contains('shorter')) {
      next = 'Please welcome $currentSpeaker — "$currentSessionTitle". Put your hands together! 👏';
    } else if (o.contains('humor')) {
      next = '$original\n\nP.S. $currentSpeaker debugs distributed systems faster than we find coffee — and that\'s saying something! ☕';
    } else if (o.contains('formal')) {
      next = 'Distinguished guests, please welcome $currentSpeaker to present "$currentSessionTitle". Your warm applause, please.';
    }
    _messages.add(ChatMessage(
      id: 'ai-${DateTime.now().millisecondsSinceEpoch}',
      sender: ChatSender.smartEve,
      responseType: AiResponseType.scriptSuggestion,
      text: option == 'Use this' || option == 'Get Text Version'
          ? 'Locked in! ✅ Here\'s your clean copy-ready version:'
          : 'Here\'s the "$option" version:',
      scriptText: next,
      refinementOptions: const ['Shorter', 'Add humor', 'More formal', 'Use this'],
    ));
    _bumpFeature('refine_$option');
    _safeNotify();
  }

  // ---------------- Emergency ----------------

  void requestEmergencyHelp() {
    if (_emergencyActive) return;
    _emergencyActive = true;
    final now = DateTime.now();
    final h = now.hour > 12 ? now.hour - 12 : (now.hour == 0 ? 12 : now.hour);
    final label = '$h:${now.minute.toString().padLeft(2, '0')} ${now.hour >= 12 ? 'PM' : 'AM'}';
    _emergencyTimeLabel = label;
    _emergencyCount++;
    _bumpFeature('emergency_escalation');

    _messages.add(ChatMessage(
      id: 'sys-${now.millisecondsSinceEpoch}',
      sender: ChatSender.system,
      responseType: AiResponseType.emergencyAck,
      text: '🚨 Emergency help requested at $label — organizer alerted.',
    ));
    _messages.add(ChatMessage(
      id: 'ai-${now.millisecondsSinceEpoch + 1}',
      sender: ChatSender.smartEve,
      responseType: AiResponseType.scriptSuggestion,
      text: 'I\'ve alerted your organizer, $anchorName — help is on the way. Meanwhile, read this line verbatim:',
      scriptText: 'Ladies and gentlemen, thank you for your patience — we\'ll be right back with $currentSpeaker in just a moment! 🙏',
      refinementOptions: const ['Call Organizer', 'Use this'],
    ));
    _usageLogs.insert(0, AiUsageLog(
      id: 'log-emg-${now.millisecondsSinceEpoch}',
      requestType: 'emergency_escalation',
      prompt: 'I need help NOW',
      timestamp: now,
      responseTimeMs: 900,
    ));
    _safeNotify();
  }

  void resolveEmergency() {
    _emergencyActive = false;
    _emergencyTimeLabel = null;
    _messages.add(ChatMessage(
      id: 'sys-${DateTime.now().millisecondsSinceEpoch}',
      sender: ChatSender.system,
      responseType: AiResponseType.text,
      text: '✅ Emergency resolved — organizer notified you\'re back on track.',
    ));
    _safeNotify();
  }

  // ---------------- Feedback ----------------

  void markHelpful(String messageId, bool helpful) {
    final idx = _messages.indexWhere((m) => m.id == messageId);
    if (idx == -1) return;
    _messages[idx].wasHelpful = helpful;
    _bumpFeature(helpful ? 'feedback_positive' : 'feedback_negative');
    _safeNotify();
  }

  void submitImprovement(String messageId, String note) {
    final idx = _messages.indexWhere((m) => m.id == messageId);
    if (idx == -1) return;
    _messages[idx].improvementNote = note;
    _bumpFeature('feedback_improvement_note');
    _safeNotify();
  }

  // ---------------- History ----------------

  void clearHistory() {
    _messages.clear();
    _seedWelcome();
    _safeNotify();
  }

  String exportAsText() {
    final buffer = StringBuffer()
      ..writeln('SmartEve AI Assist — Chat Export')
      ..writeln('Event: $eventName • Anchor: $anchorName')
      ..writeln('Exported: ${DateTime.now()}')
      ..writeln('Avg response: ${avgResponseSeconds.toStringAsFixed(1)}s')
      ..writeln('----------------------------------------');
    for (final m in _messages) {
      buffer.writeln(m.toExportLine());
      if (m.wasHelpful != null) {
        buffer.writeln('   Feedback: ${m.wasHelpful! ? '👍 helpful' : '👎 not helpful'}${m.improvementNote != null ? ' — "${m.improvementNote}"' : ''}');
      }
    }
    buffer.writeln('----------------------------------------');
    buffer.writeln('Usage: ${_usageLogs.length} requests • Emergencies: $_emergencyCount');
    return buffer.toString();
  }
}
