import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/theme/app_theme.dart';
import '../models/ai_chat_models.dart';

/// Right-aligned anchor bubble (blue) with timestamp + read checkmarks.
class AnchorBubble extends StatelessWidget {
  final ChatMessage message;
  const AnchorBubble({super.key, required this.message});

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerRight,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.78),
        child: Container(
          margin: const EdgeInsets.only(left: 48, top: 4, bottom: 4),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [AppTheme.primaryBlue, Color(0xFF3B5BDB)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(16),
              topRight: Radius.circular(4),
              bottomLeft: Radius.circular(16),
              bottomRight: Radius.circular(16),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              SelectableText(
                message.text,
                style: const TextStyle(fontSize: 15, height: 1.4, color: Colors.white),
              ),
              const SizedBox(height: 4),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    message.formattedTime,
                    style: TextStyle(fontSize: 11, color: Colors.white.withValues(alpha: 0.75)),
                  ),
                  const SizedBox(width: 4),
                  Icon(
                    message.status == MessageStatus.read ? Icons.done_all_rounded : Icons.done_rounded,
                    size: 14,
                    color: message.status == MessageStatus.read
                        ? const Color(0xFF7DD3FC)
                        : Colors.white.withValues(alpha: 0.7),
                    semanticLabel: message.status == MessageStatus.read ? 'Read' : 'Sent',
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Left-aligned SmartEve bubble shell; rich payload cards render below text.
class SmartEveBubble extends StatelessWidget {
  final ChatMessage message;
  final Widget? richChild;
  final Widget? feedbackChild;

  const SmartEveBubble({super.key, required this.message, this.richChild, this.feedbackChild});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 32,
          height: 32,
          margin: const EdgeInsets.only(top: 2),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [AppTheme.primaryBlue, AppTheme.secondaryPurple],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(10),
          ),
          child: const Icon(Icons.auto_awesome_rounded, color: Colors.white, size: 16),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
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
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SelectableText(
                      message.text,
                      style: const TextStyle(fontSize: 15, height: 1.45, color: AppTheme.textPrimary),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      message.formattedTime,
                      style: const TextStyle(fontSize: 11, color: AppTheme.textMuted),
                    ),
                  ],
                ),
              ),
              if (richChild != null) ...[const SizedBox(height: 8), richChild!],
              if (feedbackChild != null) ...[const SizedBox(height: 4), feedbackChild!],
            ],
          ),
        ),
        const SizedBox(width: 32),
      ],
    );
  }
}

/// Centered system notice (e.g. emergency escalation).
class SystemNotice extends StatelessWidget {
  final ChatMessage message;
  const SystemNotice({super.key, required this.message});

  @override
  Widget build(BuildContext context) {
    final isEmergency = message.responseType == AiResponseType.emergencyAck;
    return Center(
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 8),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
        decoration: BoxDecoration(
          color: isEmergency ? AppTheme.error.withValues(alpha: 0.1) : AppTheme.surfaceLight,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: isEmergency ? AppTheme.error.withValues(alpha: 0.4) : AppTheme.border),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isEmergency ? Icons.emergency_rounded : Icons.info_outline_rounded,
              size: 16,
              color: isEmergency ? AppTheme.error : AppTheme.textSecondary,
            ),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                message.text,
                style: TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w600,
                  color: isEmergency ? AppTheme.error : AppTheme.textSecondary,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// "Was this helpful?" thumbs row + optional improvement input.
class FeedbackRow extends StatefulWidget {
  final ChatMessage message;
  final void Function(bool helpful) onFeedback;
  final void Function(String note) onImprovement;

  const FeedbackRow({super.key, required this.message, required this.onFeedback, required this.onImprovement});

  @override
  State<FeedbackRow> createState() => _FeedbackRowState();
}

class _FeedbackRowState extends State<FeedbackRow> {
  bool _showInput = false;
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final m = widget.message;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Text('Was this helpful?', style: TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
            const SizedBox(width: 8),
            _thumb(m.wasHelpful == true, Icons.thumb_up_alt_rounded, 'Helpful', true),
            const SizedBox(width: 6),
            _thumb(m.wasHelpful == false, Icons.thumb_down_alt_rounded, 'Not helpful', false),
          ],
        ),
        if (m.wasHelpful == false && !_showInput && m.improvementNote == null)
          TextButton(
            onPressed: () => setState(() => _showInput = true),
            child: const Text('How can we improve?', style: TextStyle(fontSize: 12)),
          ),
        if (_showInput && m.improvementNote == null)
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _controller,
                  minLines: 1,
                  maxLines: 3,
                  style: const TextStyle(fontSize: 13),
                  decoration: InputDecoration(
                    hintText: 'Tell us how to improve…',
                    hintStyle: const TextStyle(fontSize: 12, color: AppTheme.textMuted),
                    isDense: true,
                    filled: true,
                    fillColor: AppTheme.surface,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppTheme.border)),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  ),
                ),
              ),
              const SizedBox(width: 6),
              IconButton.filled(
                onPressed: () {
                  if (_controller.text.trim().isNotEmpty) {
                    widget.onImprovement(_controller.text.trim());
                    setState(() => _showInput = false);
                  }
                },
                icon: const Icon(Icons.send_rounded, size: 16),
                style: IconButton.styleFrom(backgroundColor: AppTheme.primaryBlue, foregroundColor: Colors.white),
                tooltip: 'Send feedback',
              ),
            ],
          ),
        if (m.improvementNote != null)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(
              'Thanks for the feedback! "${m.improvementNote}" — we\'ll use it to improve SmartEve. 💜',
              style: const TextStyle(fontSize: 11.5, color: AppTheme.success, fontStyle: FontStyle.italic),
            ),
          ),
      ],
    );
  }

  Widget _thumb(bool selected, IconData icon, String label, bool value) {
    return InkWell(
      onTap: () {
        widget.onFeedback(value);
        if (!value) setState(() => _showInput = true);
        HapticFeedback.lightImpact();
      },
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: selected
              ? (value ? AppTheme.success.withValues(alpha: 0.12) : AppTheme.error.withValues(alpha: 0.1))
              : AppTheme.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: selected ? (value ? AppTheme.success : AppTheme.error) : AppTheme.border,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: selected ? (value ? AppTheme.success : AppTheme.error) : AppTheme.textMuted),
            const SizedBox(width: 4),
            Text(label, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: selected ? AppTheme.textPrimary : AppTheme.textMuted)),
          ],
        ),
      ),
    );
  }
}
