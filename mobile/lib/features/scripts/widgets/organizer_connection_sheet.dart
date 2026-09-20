import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../../../providers/scripts_provider.dart';

class OrganizerConnectionSheet extends StatelessWidget {
  final ScriptsProvider provider;

  const OrganizerConnectionSheet({
    super.key,
    required this.provider,
  });

  static Future<void> show(BuildContext context, ScriptsProvider provider) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => OrganizerConnectionSheet(provider: provider),
    );
  }

  @override
  Widget build(BuildContext context) {
    final scripts = provider.scripts;
    final reviewedCount = scripts.where((s) => s.isReviewedByAnchor).length;
    final viewedCount = scripts.where((s) => s.viewedByAnchor).length;
    final modRequestsCount = scripts.fold<int>(
      0,
      (sum, s) => sum + s.modificationRequests.length,
    );

    final logs = provider.organizerActivityLog;

    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      decoration: const BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Drag handle
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppTheme.border,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 14),

          // Header
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppTheme.primaryBlue.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.hub_rounded, color: AppTheme.primaryBlue, size: 22),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Organizer Collaboration Hub',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                    Text(
                      'Live anchor-to-organizer telemetry & script synchronizer',
                      style: TextStyle(fontSize: 12, color: AppTheme.textSecondary),
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close_rounded),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Organizer Status KPI Cards
          Row(
            children: [
              _buildKpiCard(
                label: 'Reviewed',
                value: '$reviewedCount / ${scripts.length}',
                color: AppTheme.success,
                icon: Icons.check_circle_outline,
              ),
              const SizedBox(width: 10),
              _buildKpiCard(
                label: 'Viewed Live',
                value: '$viewedCount / ${scripts.length}',
                color: AppTheme.primaryBlue,
                icon: Icons.visibility_outlined,
              ),
              const SizedBox(width: 10),
              _buildKpiCard(
                label: 'Change Reqs',
                value: '$modRequestsCount',
                color: AppTheme.warning,
                icon: Icons.edit_notifications_outlined,
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Live Simulation Actions Banner
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppTheme.surfaceLight,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppTheme.border),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'SIMULATE REAL-TIME ORGANIZER UPDATES',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.8,
                    color: AppTheme.textSecondary,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () {
                          provider.simulateOrganizerPushNewScript();
                          Navigator.of(context).pop();
                        },
                        icon: const Icon(Icons.add_task_rounded, size: 15),
                        label: const Text('Push New Script (NEW badge)', style: TextStyle(fontSize: 11)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.cyan,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () {
                          if (scripts.isNotEmpty) {
                            provider.simulateOrganizerReviseScript(scripts.first.id);
                          }
                          Navigator.of(context).pop();
                        },
                        icon: const Icon(Icons.update_rounded, size: 15),
                        label: const Text('Push Revision (UPDATED)', style: TextStyle(fontSize: 11)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.warning,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Audit Stream Header
          const Text(
            'Live Activity & Audit Log (Organizer View)',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 8),

          // Log list
          Expanded(
            child: logs.isEmpty
                ? const Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.history_rounded, size: 40, color: AppTheme.textMuted),
                        SizedBox(height: 8),
                        Text(
                          'No recent anchor activity recorded yet.',
                          style: TextStyle(fontSize: 13, color: AppTheme.textSecondary),
                        ),
                        Text(
                          'Open or review scripts to see live entries here.',
                          style: TextStyle(fontSize: 11, color: AppTheme.textMuted),
                        ),
                      ],
                    ),
                  )
                : ListView.separated(
                    itemCount: logs.length,
                    separatorBuilder: (_, __) => const Divider(height: 1, color: AppTheme.border),
                    itemBuilder: (context, index) {
                      final log = logs[index];
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: _getLogColor(log['type'] as String).withValues(alpha: 0.12),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                _getLogIcon(log['type'] as String),
                                size: 14,
                                color: _getLogColor(log['type'] as String),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        log['title'] as String? ?? 'Activity',
                                        style: const TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w700,
                                          color: AppTheme.textPrimary,
                                        ),
                                      ),
                                      Text(
                                        log['time'] as String? ?? '',
                                        style: const TextStyle(
                                          fontSize: 11,
                                          color: AppTheme.textMuted,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 3),
                                  Text(
                                    log['detail'] as String? ?? '',
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: AppTheme.textSecondary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildKpiCard({
    required String label,
    required String value,
    required Color color,
    required IconData icon,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 10),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.25)),
        ),
        child: Column(
          children: [
            Icon(icon, size: 18, color: color),
            const SizedBox(height: 4),
            Text(
              value,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w900,
                color: color,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: AppTheme.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _getLogColor(String type) {
    switch (type) {
      case 'viewed':
        return AppTheme.primaryBlue;
      case 'reviewed':
        return AppTheme.success;
      case 'requested_change':
        return AppTheme.warning;
      case 'ai_applied':
        return AppTheme.secondaryPurple;
      case 'organizer_push':
        return AppTheme.cyan;
      case 'organizer_revised':
        return AppTheme.warning;
      default:
        return AppTheme.textSecondary;
    }
  }

  IconData _getLogIcon(String type) {
    switch (type) {
      case 'viewed':
        return Icons.visibility_rounded;
      case 'reviewed':
        return Icons.check_circle_rounded;
      case 'requested_change':
        return Icons.edit_note_rounded;
      case 'ai_applied':
        return Icons.auto_awesome_rounded;
      case 'organizer_push':
        return Icons.add_circle_outline_rounded;
      case 'organizer_revised':
        return Icons.change_circle_outlined;
      default:
        return Icons.info_outline_rounded;
    }
  }
}
