import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class SmartEveNavItem {
  final IconData icon;
  final String label;

  const SmartEveNavItem({
    required this.icon,
    required this.label,
  });
}

class SmartEveBottomNav extends StatelessWidget {
  final int selectedIndex;
  final ValueChanged<int> onItemSelected;
  final List<SmartEveNavItem>? items;
  final Map<int, int>? badgeCounts;

  const SmartEveBottomNav({
    super.key,
    required this.selectedIndex,
    required this.onItemSelected,
    this.items,
    this.badgeCounts,
  });

  static const List<SmartEveNavItem> defaultAnchorItems = [
    SmartEveNavItem(icon: Icons.home_rounded, label: 'Home'),
    SmartEveNavItem(icon: Icons.calendar_month_rounded, label: 'Events'),
    SmartEveNavItem(icon: Icons.description_rounded, label: 'Scripts'),
    SmartEveNavItem(icon: Icons.notifications_rounded, label: 'Notif'),
    SmartEveNavItem(icon: Icons.person_rounded, label: 'Profile'),
  ];

  static const List<SmartEveNavItem> defaultOrganizerItems = [
    SmartEveNavItem(icon: Icons.home_filled, label: 'Home'),
    SmartEveNavItem(icon: Icons.calendar_month_rounded, label: 'Agenda'),
    SmartEveNavItem(icon: Icons.people_alt_rounded, label: 'Speakers'),
    SmartEveNavItem(icon: Icons.auto_awesome_rounded, label: 'AI Assist'),
    SmartEveNavItem(icon: Icons.person_rounded, label: 'Profile'),
  ];

  @override
  Widget build(BuildContext context) {
    final navItems = items ?? defaultAnchorItems;

    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Align(
          alignment: Alignment.bottomCenter,
          heightFactor: 1.0,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 440),
            child: Container(
              decoration: BoxDecoration(
                color: AppTheme.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppTheme.border, width: 1),
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.deepNavy.withValues(alpha: 0.1),
                    blurRadius: 16,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: List.generate(navItems.length, (index) {
                  return _buildNavItem(
                    index: index,
                    item: navItems[index],
                  );
                }),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem({
    required int index,
    required SmartEveNavItem item,
  }) {
    final bool isSelected = selectedIndex == index;
    final Color itemColor = isSelected ? AppTheme.primaryBlue : AppTheme.textSecondary;

    return Expanded(
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => onItemSelected(index),
          borderRadius: BorderRadius.circular(10),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Icon with subtle highlight when active + unread badge
                Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: isSelected ? AppTheme.primaryBlue.withValues(alpha: 0.12) : Colors.transparent,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        item.icon,
                        size: 20,
                        color: itemColor,
                      ),
                    ),
                    if ((badgeCounts?[index] ?? 0) > 0)
                      Positioned(
                        top: -4,
                        right: -6,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 5, vertical: 1),
                          decoration: BoxDecoration(
                            color: AppTheme.error,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                                color: AppTheme.surface, width: 1.5),
                          ),
                          constraints: const BoxConstraints(
                              minWidth: 16, minHeight: 16),
                          child: Text(
                            '${badgeCounts![index]}',
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 9,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 2),
                // Text Label with auto-scale down
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 2),
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      item.label,
                      maxLines: 1,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                        color: itemColor,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 2),
                // Selected indicator mark (✓ as wireframe specified)
                SizedBox(
                  height: 10,
                  child: isSelected
                      ? const Icon(
                          Icons.check_rounded,
                          size: 11,
                          color: AppTheme.primaryBlue,
                        )
                      : const SizedBox.shrink(),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
