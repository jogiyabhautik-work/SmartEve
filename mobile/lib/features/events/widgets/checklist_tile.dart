import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../../../models/checklist_item_model.dart';

/// A single interactive checklist row: tappable, animated check circle,
/// green when completed / gray outline when pending.
class ChecklistTile extends StatelessWidget {
  final ChecklistItemModel item;
  final ValueChanged<bool> onChanged;

  const ChecklistTile({
    super.key,
    required this.item,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final done = item.isCompleted;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => onChanged(!done),
        borderRadius: BorderRadius.circular(AppTheme.radiusCard),
        child: Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: done
                ? AppTheme.success.withValues(alpha: 0.06)
                : AppTheme.surface,
            borderRadius: BorderRadius.circular(AppTheme.radiusCard),
            border: Border.all(
              color: done
                  ? AppTheme.success.withValues(alpha: 0.35)
                  : AppTheme.border,
            ),
          ),
          child: Row(
            children: [
              // Animated check circle
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: 26,
                height: 26,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: done ? AppTheme.success : Colors.transparent,
                  border: Border.all(
                    color: done ? AppTheme.success : AppTheme.textMuted,
                    width: 2,
                  ),
                ),
                child: done
                    ? const Icon(Icons.check_rounded,
                        size: 16, color: Colors.white)
                    : null,
              ),
              const SizedBox(width: 12),
              // Item icon
              Container(
                padding: const EdgeInsets.all(7),
                decoration: BoxDecoration(
                  color: done
                      ? AppTheme.success.withValues(alpha: 0.12)
                      : AppTheme.primaryBlue.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  item.icon,
                  size: 17,
                  color: done ? AppTheme.success : AppTheme.primaryBlue,
                ),
              ),
              const SizedBox(width: 12),
              // Label
              Expanded(
                child: Text(
                  item.label,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: done ? AppTheme.textSecondary : AppTheme.textPrimary,
                    decoration: done ? TextDecoration.lineThrough : null,
                    decorationColor: AppTheme.textMuted,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
