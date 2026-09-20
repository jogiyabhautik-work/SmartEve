import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../models/ai_chat_models.dart';
import 'ai_chat_header.dart';

/// SCRIPT SUGGESTION card: 16px+ readable script + Copy / Modify / Use in Event + thumbs.
class ScriptSuggestionCard extends StatelessWidget {
  final ChatMessage message;
  final void Function(String option) onRefine;

  const ScriptSuggestionCard({super.key, required this.message, required this.onRefine});

  @override
  Widget build(BuildContext context) {
    final script = message.scriptText ?? '';
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFEFF4FF),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.primaryBlue.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Row(
            children: [
              Icon(Icons.description_rounded, size: 15, color: AppTheme.primaryBlue),
              SizedBox(width: 6),
              Text('SCRIPT SUGGESTION', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1.1, color: AppTheme.primaryBlue)),
            ],
          ),
          const SizedBox(height: 8),
          SelectableText(
            script,
            style: const TextStyle(fontSize: 16.5, height: 1.55, color: AppTheme.textPrimary, fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _action(context, Icons.copy_rounded, 'Copy Script', AppTheme.surface, AppTheme.textPrimary, () => copyScript(context, script)),
              _action(context, Icons.edit_rounded, 'Modify', AppTheme.surface, AppTheme.textPrimary, () => _modifySheet(context)),
              _action(context, Icons.play_arrow_rounded, 'Use in Event', AppTheme.primaryBlue, Colors.white, () {
                onRefine('Use this');
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Script queued for live event ✓ Organizer notified.'), backgroundColor: AppTheme.success, behavior: SnackBarBehavior.floating),
                );
              }),
            ],
          ),
          if (message.refinementOptions != null && message.refinementOptions!.isNotEmpty) ...[
            const SizedBox(height: 10),
            const Text('Refine:', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppTheme.textSecondary)),
            const SizedBox(height: 6),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: message.refinementOptions!.map((opt) {
                final isPrimary = opt == 'Use this' || opt == 'Call Organizer' || opt == 'Get Text Version';
                final isDanger = opt == 'Call Organizer';
                return ActionChip(
                  label: Text(opt),
                  labelStyle: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: isPrimary ? Colors.white : AppTheme.primaryBlue,
                  ),
                  backgroundColor: isDanger
                      ? AppTheme.error
                      : isPrimary
                          ? AppTheme.primaryBlue
                          : Colors.white,
                  side: BorderSide(color: isPrimary ? Colors.transparent : AppTheme.primaryBlue.withValues(alpha: 0.4)),
                  onPressed: () {
                    if (opt == 'Call Organizer') {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('📞 Calling organizer… (demo) — emergency line prioritized.'), backgroundColor: AppTheme.error, behavior: SnackBarBehavior.floating),
                      );
                    }
                    onRefine(opt);
                  },
                );
              }).toList(),
            ),
          ],
        ],
      ),
    );
  }

  Widget _action(BuildContext context, IconData icon, String label, Color bg, Color fg, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: bg == AppTheme.surface ? AppTheme.border : Colors.transparent),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 15, color: fg),
            const SizedBox(width: 6),
            Text(label, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: fg)),
          ],
        ),
      ),
    );
  }

  void _modifySheet(BuildContext context) {
    final controller = TextEditingController();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppTheme.surface,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(left: 20, right: 20, top: 20, bottom: MediaQuery.of(ctx).viewInsets.bottom + 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Modify script', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.textPrimary)),
            const SizedBox(height: 6),
            const Text('Describe the refinement — e.g. "shorter, more formal, add applause cue".', style: TextStyle(fontSize: 13, color: AppTheme.textSecondary)),
            const SizedBox(height: 12),
            TextField(
              controller: controller,
              maxLines: 3,
              autofocus: true,
              decoration: InputDecoration(
                hintText: 'Make it shorter and more formal…',
                filled: true,
                fillColor: AppTheme.surfaceLight,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppTheme.border)),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  final v = controller.text.trim();
                  Navigator.pop(ctx);
                  onRefine(v.isEmpty ? 'Shorter' : v);
                },
                child: const Text('REFINE WITH SMARTEVE'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// MULTIPLE CHOICE card: 2-3 tappable options.
class ChoiceOptionsCard extends StatelessWidget {
  final List<String> options;
  final void Function(String option) onSelect;

  const ChoiceOptionsCard({super.key, required this.options, required this.onSelect});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: options.map((opt) {
        return Container(
          margin: const EdgeInsets.only(bottom: 8),
          child: OutlinedButton.icon(
            onPressed: () => onSelect(opt),
            icon: const Icon(Icons.arrow_forward_rounded, size: 16),
            label: Align(alignment: Alignment.centerLeft, child: Text(opt)),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppTheme.primaryBlue,
              backgroundColor: Colors.white,
              alignment: Alignment.centerLeft,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
            ),
          ),
        );
      }).toList(),
    );
  }
}

/// ACTION REQUIRED card: clarification input + Continue.
class ActionRequiredCard extends StatefulWidget {
  final ChatMessage message;
  final void Function(String answer) onContinue;

  const ActionRequiredCard({super.key, required this.message, required this.onContinue});

  @override
  State<ActionRequiredCard> createState() => _ActionRequiredCardState();
}

class _ActionRequiredCardState extends State<ActionRequiredCard> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFBEB),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.warning.withValues(alpha: 0.45)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const Icon(Icons.help_outline_rounded, size: 16, color: AppTheme.warning),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  widget.message.actionPrompt ?? 'I need a bit more detail:',
                  style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600, color: AppTheme.textPrimary),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _controller,
            minLines: 1,
            maxLines: 3,
            style: const TextStyle(fontSize: 14),
            decoration: InputDecoration(
              hintText: widget.message.actionHint ?? 'Type details here…',
              hintStyle: const TextStyle(fontSize: 13, color: AppTheme.textMuted),
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppTheme.border)),
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            ),
          ),
          const SizedBox(height: 10),
          ElevatedButton(
            onPressed: () {
              final v = _controller.text.trim();
              if (v.isEmpty) return;
              widget.onContinue(v);
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.warning, foregroundColor: Colors.white),
            child: const Text('CONTINUE'),
          ),
        ],
      ),
    );
  }
}

/// REFERENCE card: deep-link to Agenda / Scripts screens.
class ReferenceCard extends StatelessWidget {
  final ChatMessage message;
  final VoidCallback onOpen;

  const ReferenceCard({super.key, required this.message, required this.onOpen});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onOpen,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppTheme.secondaryPurple.withValues(alpha: 0.4)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppTheme.secondaryPurple.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                (message.referenceRoute ?? 'agenda') == 'agenda' ? Icons.calendar_month_rounded : Icons.description_rounded,
                color: AppTheme.secondaryPurple,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    message.referenceTitle ?? 'View in app',
                    style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600, color: AppTheme.textPrimary),
                  ),
                  const SizedBox(height: 2),
                  const Text('Tap to open linked screen', style: TextStyle(fontSize: 12, color: AppTheme.textMuted)),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(color: AppTheme.secondaryPurple, borderRadius: BorderRadius.circular(9)),
              child: Text(
                message.referenceCta ?? 'Open',
                style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold, color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
