import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../models/ai_chat_models.dart';

/// "Common Requests" carousel/grid — visible until the conversation starts.
class QuickActionsGrid extends StatelessWidget {
  final void Function(QuickActionItem action) onTap;

  const QuickActionsGrid({super.key, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final actions = QuickActionItem.defaults();
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.bolt_rounded, size: 15, color: AppTheme.warning),
              SizedBox(width: 6),
              Text(
                'COMMON REQUESTS',
                style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold, letterSpacing: 1.2, color: AppTheme.textSecondary),
              ),
            ],
          ),
          const SizedBox(height: 4),
          const Text(
            'Tap to send a pre-filled message',
            style: TextStyle(fontSize: 12, color: AppTheme.textMuted),
          ),
          const SizedBox(height: 10),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              mainAxisSpacing: 8,
              crossAxisSpacing: 8,
              mainAxisExtent: 52,
            ),
            itemCount: actions.length,
            itemBuilder: (_, i) {
              final a = actions[i];
              final isEmergency = a.id == 'emergency';
              return InkWell(
                onTap: () => onTap(a),
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  decoration: BoxDecoration(
                    color: isEmergency ? AppTheme.error.withValues(alpha: 0.08) : AppTheme.surfaceLight,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isEmergency ? AppTheme.error.withValues(alpha: 0.4) : AppTheme.border,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(a.icon, size: 17, color: isEmergency ? AppTheme.error : AppTheme.primaryBlue),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          a.label,
                          style: TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w600,
                            color: isEmergency ? AppTheme.error : AppTheme.textPrimary,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

/// Suggested follow-up chips ("Yes" | "No" | "Tell me more" or custom).
class SuggestedReplies extends StatelessWidget {
  final List<String> replies;
  final void Function(String reply) onTap;

  const SuggestedReplies({super.key, required this.replies, required this.onTap});

  @override
  Widget build(BuildContext context) {
    if (replies.isEmpty) return const SizedBox.shrink();
    return SizedBox(
      height: 40,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: replies.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (_, i) => ActionChip(
          label: Text(replies[i]),
          labelStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppTheme.primaryBlue),
          backgroundColor: Colors.white,
          side: const BorderSide(color: AppTheme.primaryBlue),
          onPressed: () => onTap(replies[i]),
        ),
      ),
    );
  }
}
