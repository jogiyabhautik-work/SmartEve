import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';

/// Sticky bottom input: attach 📎, voice 🎤, text field, send ➤.
/// Large 48px+ touch targets, high-contrast, screen-reader friendly.
class ChatInputBar extends StatefulWidget {
  final void Function(String text) onSend;
  final VoidCallback onVoice;
  final void Function(String attachmentNote) onAttach;
  final bool isGenerating;

  const ChatInputBar({
    super.key,
    required this.onSend,
    required this.onVoice,
    required this.onAttach,
    this.isGenerating = false,
  });

  @override
  State<ChatInputBar> createState() => _ChatInputBarState();
}

class _ChatInputBarState extends State<ChatInputBar> {
  final _controller = TextEditingController();
  static const int _maxChars = 500;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() {
    final text = _controller.text.trim();
    if (text.isEmpty || widget.isGenerating) return;
    widget.onSend(text);
    _controller.clear();
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final canSend = _controller.text.trim().isNotEmpty && !widget.isGenerating;
    return Container(
      padding: EdgeInsets.only(
        left: 12,
        right: 12,
        top: 8,
        bottom: MediaQuery.of(context).viewInsets.bottom + 10,
      ),
      decoration: const BoxDecoration(
        color: AppTheme.surface,
        border: Border(top: BorderSide(color: AppTheme.border)),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                // Attach
                IconButton(
                  tooltip: 'Attach image or document',
                  onPressed: () => _attachSheet(context),
                  icon: const Icon(Icons.attach_file_rounded, color: AppTheme.textSecondary),
                  style: IconButton.styleFrom(minimumSize: const Size(48, 48)),
                ),
                // Text field
                Expanded(
                  child: TextField(
                    controller: _controller,
                    minLines: 1,
                    maxLines: 4,
                    maxLength: _maxChars,
                    textInputAction: TextInputAction.send,
                    onChanged: (_) => setState(() {}),
                    onSubmitted: (_) => _submit(),
                    style: const TextStyle(fontSize: 15, color: AppTheme.textPrimary),
                    decoration: InputDecoration(
                      hintText: 'Ask SmartEve AI… e.g. "transition for Priya"',
                      hintStyle: const TextStyle(fontSize: 13.5, color: AppTheme.textMuted),
                      filled: true,
                      fillColor: AppTheme.surfaceLight,
                      counterText: '',
                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: AppTheme.border)),
                      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: AppTheme.border)),
                      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: AppTheme.primaryBlue, width: 1.5)),
                    ),
                  ),
                ),
                // Voice (hands-free during live event)
                IconButton(
                  tooltip: 'Voice input (hands-free)',
                  onPressed: widget.onVoice,
                  icon: const Icon(Icons.mic_rounded, color: AppTheme.secondaryPurple),
                  style: IconButton.styleFrom(
                    minimumSize: const Size(48, 48),
                    backgroundColor: AppTheme.secondaryPurple.withValues(alpha: 0.1),
                  ),
                ),
                const SizedBox(width: 4),
                // Send
                IconButton.filled(
                  tooltip: 'Send message',
                  onPressed: canSend ? _submit : null,
                  icon: widget.isGenerating
                      ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : const Icon(Icons.send_rounded, size: 19),
                  style: IconButton.styleFrom(
                    backgroundColor: canSend ? AppTheme.primaryBlue : AppTheme.border,
                    foregroundColor: Colors.white,
                    minimumSize: const Size(48, 48),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                ),
              ],
            ),
            // Subtle character count
            if (_controller.text.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(right: 60, top: 2),
                child: Text(
                  '${_controller.text.length}/$_maxChars',
                  style: const TextStyle(fontSize: 10.5, color: AppTheme.textMuted),
                ),
              ),
          ],
        ),
      ),
    );
  }

  void _attachSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.surface,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Attach to message', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              const Text('Images & docs are shared with SmartEve as context.', style: TextStyle(fontSize: 12.5, color: AppTheme.textSecondary)),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () {
                        Navigator.pop(ctx);
                        widget.onAttach('script-draft.png (image attached)');
                      },
                      icon: const Icon(Icons.image_rounded),
                      label: const Text('Photo'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () {
                        Navigator.pop(ctx);
                        widget.onAttach('rundown.pdf (document attached)');
                      },
                      icon: const Icon(Icons.description_rounded),
                      label: const Text('Document'),
                    ),
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
