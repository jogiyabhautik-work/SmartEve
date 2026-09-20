import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/theme/app_theme.dart';

/// Branded header: logo, "SmartEve AI Assist", Online + response time, menu, close.
class AiChatHeader extends StatelessWidget {
  final String statusLine;
  final VoidCallback onClose;
  final VoidCallback onExport;
  final VoidCallback onClear;
  final VoidCallback onEmergency;
  final bool emergencyActive;

  const AiChatHeader({
    super.key,
    required this.statusLine,
    required this.onClose,
    required this.onExport,
    required this.onClear,
    required this.onEmergency,
    this.emergencyActive = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 8, 12),
      decoration: const BoxDecoration(
        color: AppTheme.surface,
        border: Border(bottom: BorderSide(color: AppTheme.border)),
      ),
      child: Row(
        children: [
          // Branded logo
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [AppTheme.primaryBlue, AppTheme.secondaryPurple],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(Icons.auto_awesome_rounded, color: Colors.white, size: 24),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'SmartEve AI Assist',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(color: AppTheme.success, shape: BoxShape.circle),
                    ),
                    const SizedBox(width: 6),
                    Flexible(
                      child: Text(
                        statusLine,
                        style: const TextStyle(fontSize: 12, color: AppTheme.success, fontWeight: FontWeight.w600),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          // Emergency NOW button (red, top right per spec)
          Tooltip(
            message: 'Escalate to organizer immediately',
            child: TextButton.icon(
              onPressed: emergencyActive ? null : onEmergency,
              icon: const Icon(Icons.emergency_rounded, size: 16),
              label: const Text('NOW'),
              style: TextButton.styleFrom(
                foregroundColor: Colors.white,
                backgroundColor: emergencyActive ? AppTheme.textMuted : AppTheme.error,
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                minimumSize: const Size(48, 40),
                tapTargetSize: MaterialTapTargetSize.padded,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
              ),
            ),
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert_rounded, color: AppTheme.textPrimary),
            tooltip: 'Chat options',
            color: AppTheme.surface,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: const BorderSide(color: AppTheme.border),
            ),
            onSelected: (v) {
              if (v == 'export') onExport();
              if (v == 'clear') onClear();
            },
            itemBuilder: (_) => const [
              PopupMenuItem(
                value: 'export',
                child: Row(children: [
                  Icon(Icons.download_rounded, size: 18, color: AppTheme.primaryBlue),
                  SizedBox(width: 10),
                  Text('Export Chat (text)', style: TextStyle(fontSize: 13)),
                ]),
              ),
              PopupMenuItem(
                value: 'clear',
                child: Row(children: [
                  Icon(Icons.delete_outline_rounded, size: 18, color: AppTheme.error),
                  SizedBox(width: 10),
                  Text('Clear Chat History', style: TextStyle(fontSize: 13, color: AppTheme.error)),
                ]),
              ),
            ],
          ),
          IconButton(
            tooltip: 'Close',
            onPressed: onClose,
            icon: const Icon(Icons.close_rounded, color: AppTheme.textPrimary),
          ),
        ],
      ),
    );
  }
}

/// Thin red banner shown while an emergency escalation is active.
class EmergencyBanner extends StatelessWidget {
  final String timeLabel;
  final VoidCallback onResolve;

  const EmergencyBanner({super.key, required this.timeLabel, required this.onResolve});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      color: AppTheme.error,
      child: Row(
        children: [
          const Icon(Icons.warning_rounded, color: Colors.white, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Emergency help requested at $timeLabel — organizer alerted',
              style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600),
            ),
          ),
          TextButton(
            onPressed: onResolve,
            style: TextButton.styleFrom(
              foregroundColor: AppTheme.error,
              backgroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text('Resolve', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}

/// Animated three-dot typing indicator with SmartEve avatar.
class TypingIndicator extends StatefulWidget {
  const TypingIndicator({super.key});

  @override
  State<TypingIndicator> createState() => _TypingIndicatorState();
}

class _TypingIndicatorState extends State<TypingIndicator> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 900))..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            gradient: const LinearGradient(colors: [AppTheme.primaryBlue, AppTheme.secondaryPurple]),
            borderRadius: BorderRadius.circular(10),
          ),
          child: const Icon(Icons.auto_awesome_rounded, color: Colors.white, size: 16),
        ),
        const SizedBox(width: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: AppTheme.surface,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(4),
              topRight: Radius.circular(16),
              bottomLeft: Radius.circular(16),
              bottomRight: Radius.circular(16),
            ),
            border: Border.all(color: AppTheme.border),
          ),
          child: AnimatedBuilder(
            animation: _controller,
            builder: (_, __) => Row(
              mainAxisSize: MainAxisSize.min,
              children: List.generate(3, (i) {
                final phase = (_controller.value * 3 - i).clamp(0.0, 1.0);
                final scale = 0.5 + (phase < 0.5 ? phase * 2 : (1 - phase) * 2) * 0.5;
                return Container(
                  margin: EdgeInsets.only(left: i == 0 ? 0 : 5),
                  width: 8 * scale + 4,
                  height: 8 * scale + 4,
                  decoration: BoxDecoration(
                    color: AppTheme.primaryBlue.withValues(alpha: 0.35 + 0.65 * scale),
                    shape: BoxShape.circle,
                  ),
                );
              }),
            ),
          ),
        ),
        const SizedBox(width: 8),
        const Text('SmartEve is writing…', style: TextStyle(fontSize: 11, color: AppTheme.textMuted, fontStyle: FontStyle.italic)),
      ],
    );
  }
}

/// Copies [text] and shows a confirmation snackbar.
Future<void> copyScript(BuildContext context, String text) async {
  await Clipboard.setData(ClipboardData(text: text));
  if (context.mounted) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Script copied to clipboard ✓'),
        backgroundColor: AppTheme.success,
        behavior: SnackBarBehavior.floating,
        duration: Duration(seconds: 2),
      ),
    );
  }
}
