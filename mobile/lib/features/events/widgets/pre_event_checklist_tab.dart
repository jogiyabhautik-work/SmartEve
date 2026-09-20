import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../../providers/checklist_provider.dart';
import 'checklist_tile.dart';

/// Tab 4: Pre-Event Checklist — interactive checkbox list with progress
/// header and a "Mark All Complete" CTA.
class PreEventChecklistTab extends StatelessWidget {
  const PreEventChecklistTab({super.key});

  @override
  Widget build(BuildContext context) {
    final checklist = context.watch<ChecklistProvider>();
    final items = checklist.items;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Progress header
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppTheme.surface,
            borderRadius: BorderRadius.circular(AppTheme.radiusCard),
            border: Border.all(
              color: checklist.isAllComplete
                  ? AppTheme.success.withValues(alpha: 0.5)
                  : AppTheme.border,
            ),
          ),
          child: Row(
            children: [
              SizedBox(
                width: 52,
                height: 52,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    CircularProgressIndicator(
                      value: checklist.completionFraction,
                      strokeWidth: 5,
                      backgroundColor: AppTheme.border,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        checklist.isAllComplete
                            ? AppTheme.success
                            : AppTheme.primaryBlue,
                      ),
                    ),
                    Text(
                      '${checklist.completionPercent}%',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Pre-Event Checklist',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      '${checklist.completedCount} of ${checklist.totalCount} complete',
                      style: const TextStyle(
                          fontSize: 12, color: AppTheme.textSecondary),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Checklist items
        ...items.map(
          (item) => ChecklistTile(
            item: item,
            onChanged: (val) => checklist.toggleItem(item.id, val),
          ),
        ),

        const SizedBox(height: 10),

        // Mark All Complete CTA or all-done banner
        if (checklist.isAllComplete)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppTheme.success.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(AppTheme.radiusCard),
              border:
                  Border.all(color: AppTheme.success.withValues(alpha: 0.4)),
            ),
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.celebration_outlined,
                    size: 18, color: AppTheme.success),
                SizedBox(width: 8),
                Flexible(
                  child: Text(
                    "All set! You're ready to go live.",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.success,
                    ),
                  ),
                ),
              ],
            ),
          )
        else
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () => checklist.markAllComplete(),
              icon: const Icon(Icons.done_all_rounded, size: 18),
              label: const Text('Mark All Complete'),
            ),
          ),
      ],
    );
  }
}
