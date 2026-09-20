import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../../providers/event_provider.dart';
import '../../agenda/agenda_screen.dart';
import '../../scripts/scripts_library_screen.dart';
import '../models/ai_chat_models.dart';
import '../providers/ai_chat_provider.dart';
import '../widgets/ai_chat_header.dart';
import '../widgets/chat_bubbles.dart';
import '../widgets/chat_input_bar.dart';
import '../widgets/quick_actions_grid.dart';
import '../widgets/response_cards.dart';

/// Full SmartEve AI Assist chat interface.
///
/// Responsive:
/// - Mobile (<600px): full-screen.
/// - Tablet/Desktop (>=600px): centered 560px panel with card chrome.
///
/// Covers spec: branded header + Online/response-time, quick actions,
/// all 5 AI response types, feedback, export/clear, emergency mode,
/// voice/attach input, suggested replies, context personalization.
class AiAssistantScreen extends StatefulWidget {
  const AiAssistantScreen({super.key});

  /// Opens as a 98%-height bottom sheet on phones, dialog panel on wide screens.
  static Future<void> show(BuildContext context) {
    final isWide = MediaQuery.of(context).size.width >= 700;
    if (isWide) {
      return showDialog(
        context: context,
        builder: (_) => Dialog(
          insetPadding: const EdgeInsets.all(24),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          child: SizedBox(
            width: 560,
            height: MediaQuery.of(context).size.height * 0.88,
            child: const ClipRRect(
              borderRadius: BorderRadius.all(Radius.circular(20)),
              child: AiAssistantScreen(),
            ),
          ),
        ),
      );
    }
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        height: MediaQuery.of(context).size.height * 0.98,
        decoration: const BoxDecoration(
          color: AppTheme.background,
          borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
        ),
        child: const ClipRRect(
          borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
          child: AiAssistantScreen(),
        ),
      ),
    );
  }

  @override
  State<AiAssistantScreen> createState() => _AiAssistantScreenState();
}

class _AiAssistantScreenState extends State<AiAssistantScreen> {
  final ScrollController _scroll = ScrollController();
  bool _contextBound = false;

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  void _bindContext(AiChatProvider chat) {
    if (_contextBound) return;
    _contextBound = true;
    try {
      final event = context.read<EventProvider>();
      WidgetsBinding.instance.addPostFrameCallback((_) {
        chat.setContext(
          eventName: event.event?.name ?? 'TechNova 2026',
          currentSpeaker: event.currentSpeaker?.name ?? 'Dr. Aris Vance',
          currentSessionTitle: event.currentSession?.title ?? 'Keynote: Autonomous Agents',
          eventId: event.event?.id ?? 'technova-2026',
        );
      });
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AiChatProvider>(
      builder: (context, chat, _) {
        _bindContext(chat);
        // Auto-scroll on new messages / typing state.
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (_scroll.hasClients) {
            _scroll.animateTo(
              _scroll.position.maxScrollExtent,
              duration: const Duration(milliseconds: 250),
              curve: Curves.easeOut,
            );
          }
        });

        return LayoutBuilder(
          builder: (context, constraints) {
            final isWide = constraints.maxWidth >= 600;
            final body = Column(
              children: [
                AiChatHeader(
                  statusLine: chat.statusLine,
                  emergencyActive: chat.emergencyActive,
                  onClose: () => Navigator.of(context).maybePop(),
                  onExport: () => _export(context, chat),
                  onClear: () => _confirmClear(context, chat),
                  onEmergency: () => _confirmEmergency(context, chat),
                ),
                if (chat.emergencyActive && chat.emergencyTimeLabel != null)
                  EmergencyBanner(
                    timeLabel: chat.emergencyTimeLabel!,
                    onResolve: chat.resolveEmergency,
                  ),
                Expanded(
                  child: Container(
                    color: AppTheme.background,
                    child: ListView(
                      controller: _scroll,
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                      children: [
                        // Context chip: what SmartEve remembers.
                        _contextChip(chat),
                        const SizedBox(height: 8),
                        // Quick actions until conversation starts.
                        if (!chat.hasConversation) ...[
                          QuickActionsGrid(onTap: (a) => chat.sendQuickAction(a)),
                          const SizedBox(height: 8),
                        ],
                        // History.
                        ...chat.messages.map((m) => Padding(
                              padding: const EdgeInsets.only(bottom: 10),
                              child: _messageWidget(context, chat, m),
                            )),
                        if (chat.isGenerating) ...[
                          const Padding(
                            padding: EdgeInsets.only(bottom: 10),
                            child: TypingIndicator(),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
                // Suggested replies above input.
                if (chat.hasConversation)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: SuggestedReplies(
                      replies: chat.suggestedReplies,
                      onTap: (r) => chat.sendMessage(r),
                    ),
                  ),
                ChatInputBar(
                  isGenerating: chat.isGenerating,
                  onSend: chat.sendMessage,
                  onAttach: (note) => chat.sendMessage('Please review my attachment', attachmentNote: note),
                  onVoice: () => _voiceDemo(context, chat),
                ),
              ],
            );

            if (!isWide) return Scaffold(body: SafeArea(child: body));

            // Tablet/desktop: floating 560px panel look.
            return Scaffold(
              backgroundColor: const Color(0xFFE8EDF7),
              body: Center(
                child: Container(
                  width: 560,
                  height: double.infinity,
                  margin: const EdgeInsets.symmetric(vertical: 12),
                  decoration: BoxDecoration(
                    color: AppTheme.background,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: AppTheme.border),
                    boxShadow: [
                      BoxShadow(color: Colors.black.withValues(alpha: 0.12), blurRadius: 30, offset: const Offset(0, 12)),
                    ],
                  ),
                  child: ClipRRect(borderRadius: BorderRadius.circular(20), child: body),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _contextChip(AiChatProvider chat) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.border),
      ),
      child: Row(
        children: [
          const Icon(Icons.event_rounded, size: 15, color: AppTheme.primaryBlue),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              '${chat.eventName} • ${chat.currentSpeaker} live • Anchor: ${chat.anchorName}',
              style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary, fontWeight: FontWeight.w500),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _messageWidget(BuildContext context, AiChatProvider chat, ChatMessage m) {
    if (m.isSystem) return SystemNotice(message: m);
    if (m.isAnchor) {
      return Semantics(label: 'Your message at ${m.formattedTime}', child: AnchorBubble(message: m));
    }
    // SmartEve message + rich payload + feedback.
    Widget? rich;
    switch (m.responseType) {
      case AiResponseType.scriptSuggestion:
        rich = ScriptSuggestionCard(message: m, onRefine: chat.refineLastScript);
        break;
      case AiResponseType.multipleChoice:
        rich = ChoiceOptionsCard(
          options: m.choiceOptions ?? const [],
          onSelect: chat.applyChoice,
        );
        break;
      case AiResponseType.actionRequired:
        rich = ActionRequiredCard(message: m, onContinue: chat.sendMessage);
        break;
      case AiResponseType.reference:
        rich = ReferenceCard(
          message: m,
          onOpen: () => _openReference(context, m),
        );
        break;
      case AiResponseType.text:
      case AiResponseType.emergencyAck:
        rich = null;
        break;
    }
    return Semantics(
      label: 'SmartEve AI message at ${m.formattedTime}',
      child: SmartEveBubble(
        message: m,
        richChild: rich,
        feedbackChild: FeedbackRow(
          message: m,
          onFeedback: (helpful) => chat.markHelpful(m.id, helpful),
          onImprovement: (note) => chat.submitImprovement(m.id, note),
        ),
      ),
    );
  }

  void _openReference(BuildContext context, ChatMessage m) {
    final route = m.referenceRoute ?? 'agenda';
    if (route == 'scripts') {
      Navigator.of(context).push(MaterialPageRoute(builder: (_) => const ScriptsLibraryScreen()));
    } else {
      Navigator.of(context).push(MaterialPageRoute(builder: (_) => const AgendaScreen()));
    }
  }

  void _export(BuildContext context, AiChatProvider chat) {
    final text = chat.exportAsText();
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Chat exported (${chat.messages.length} messages) — copied to clipboard ✓'),
        backgroundColor: AppTheme.success,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _confirmClear(BuildContext context, AiChatProvider chat) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Clear chat history?'),
        content: const Text('This removes all messages in this session. Usage analytics are kept for the organizer.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          FilledButton(
            onPressed: () {
              Navigator.pop(ctx);
              chat.clearHistory();
            },
            style: FilledButton.styleFrom(backgroundColor: AppTheme.error),
            child: const Text('Clear'),
          ),
        ],
      ),
    );
  }

  void _confirmEmergency(BuildContext context, AiChatProvider chat) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        icon: const Icon(Icons.emergency_rounded, color: AppTheme.error, size: 32),
        title: const Text('Request emergency help?'),
        content: const Text('This alerts your organizer immediately and pins a rescue script on screen. Use it when you blank on stage.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          FilledButton(
            onPressed: () {
              Navigator.pop(ctx);
              chat.requestEmergencyHelp();
              HapticFeedback.heavyImpact();
            },
            style: FilledButton.styleFrom(backgroundColor: AppTheme.error),
            child: const Text('I NEED HELP NOW'),
          ),
        ],
      ),
    );
  }

  /// Hands-free voice demo: no extra dependency — simulates STT with a
  /// choice sheet so anchors can keep hands on the clicker on stage.
  void _voiceDemo(BuildContext context, AiChatProvider chat) {
    const samples = [
      'I need a transition between Speaker 1 and Speaker 2',
      'Speaker is running 10 minutes late',
      'I completely forgot what to say!',
      'Make this more engaging',
    ];
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.surface,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(color: AppTheme.error.withValues(alpha: 0.1), shape: BoxShape.circle),
                child: const Icon(Icons.mic_rounded, color: AppTheme.error, size: 28),
              ),
              const SizedBox(height: 10),
              const Text('Listening… (hands-free mode)', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              const Text('Pick what you said — live STT plugs in here.', style: TextStyle(fontSize: 12.5, color: AppTheme.textSecondary)),
              const SizedBox(height: 12),
              ...samples.map((s) => ListTile(
                    leading: const Icon(Icons.graphic_eq_rounded, color: AppTheme.primaryBlue),
                    title: Text(s, style: const TextStyle(fontSize: 13.5)),
                    onTap: () {
                      Navigator.pop(ctx);
                      chat.sendMessage(s);
                    },
                  )),
            ],
          ),
        ),
      ),
    );
  }
}
