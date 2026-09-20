import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../../../models/notification_model.dart';

class NotificationFilterBar extends StatelessWidget {
  final NotificationCategory selected;
  final ValueChanged<NotificationCategory> onSelected;

  const NotificationFilterBar({
    super.key,
    required this.selected,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 38,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        itemCount: NotificationCategory.values.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final cat = NotificationCategory.values[index];
          final isSelected = cat == selected;
          return Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(20),
              onTap: () => onSelected(cat),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: isSelected ? AppTheme.primaryBlue : AppTheme.surfaceLight,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isSelected ? AppTheme.primaryBlue : AppTheme.border,
                    width: isSelected ? 1.5 : 1,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      _iconFor(cat),
                      size: 14,
                      color: isSelected ? Colors.white : AppTheme.textSecondary,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      cat.label,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                        color: isSelected ? Colors.white : AppTheme.textPrimary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  IconData _iconFor(NotificationCategory cat) {
    return switch (cat) {
      NotificationCategory.invitation => Icons.card_membership_rounded,
      NotificationCategory.update => Icons.refresh_rounded,
      NotificationCategory.announcement => Icons.campaign_rounded,
      NotificationCategory.message => Icons.chat_bubble_outline_rounded,
      NotificationCategory.alert => Icons.warning_amber_rounded,
      NotificationCategory.smartEveAi => Icons.auto_awesome_rounded,
      NotificationCategory.all => Icons.inbox_rounded,
    };
  }
}
