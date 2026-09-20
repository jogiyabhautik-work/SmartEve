import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../../../models/user_profile_model.dart';

class ProfileStatsSection extends StatelessWidget {
  final ProfileStats stats;

  const ProfileStatsSection({
    super.key,
    required this.stats,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth > 500;
        final crossAxisCount = isWide ? 4 : 2;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Padding(
              padding: EdgeInsets.only(left: 4, bottom: 12),
              child: Text(
                'STAGE PERFORMANCE METRICS',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.1,
                  color: AppTheme.textSecondary,
                ),
              ),
            ),
            GridView.count(
              crossAxisCount: crossAxisCount,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: isWide ? 1.6 : 1.35,
              children: [
                _buildStatCard(
                  icon: Icons.mic_external_on_rounded,
                  label: 'Events Anchored',
                  value: '${stats.eventsAnchored}',
                  iconColor: AppTheme.primaryBlue,
                  bgColor: AppTheme.primaryBlue.withValues(alpha: 0.08),
                ),
                _buildStatCard(
                  icon: Icons.timer_outlined,
                  label: 'Stage Hours',
                  value: '${stats.hoursOnStage}h',
                  iconColor: AppTheme.secondaryPurple,
                  bgColor: AppTheme.secondaryPurple.withValues(alpha: 0.08),
                ),
                _buildStatCard(
                  icon: Icons.star_rounded,
                  label: 'Average Rating',
                  value: '${stats.averageRating} / 5',
                  iconColor: const Color(0xFFF59E0B),
                  bgColor: const Color(0xFFFEF3C7),
                  starRating: stats.averageRating,
                ),
                _buildStatCard(
                  icon: Icons.task_alt_rounded,
                  label: 'Completion Rate',
                  value: '${stats.completionRate}%',
                  iconColor: AppTheme.success,
                  bgColor: AppTheme.success.withValues(alpha: 0.08),
                ),
              ],
            ),
          ],
        );
      },
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required String label,
    required String value,
    required Color iconColor,
    required Color bgColor,
    double? starRating,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(AppTheme.radiusCard),
        border: Border.all(color: AppTheme.border),
        boxShadow: [
          BoxShadow(
            color: AppTheme.deepNavy.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.all(7),
                decoration: BoxDecoration(
                  color: bgColor,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: iconColor, size: 18),
              ),
            ],
          ),
          const Spacer(),
          if (starRating != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 2),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: List.generate(5, (i) {
                  final filled = starRating >= i + 0.75;
                  final half = !filled && starRating >= i + 0.25;
                  return Icon(
                    filled
                        ? Icons.star_rounded
                        : (half ? Icons.star_half_rounded : Icons.star_outline_rounded),
                    size: 13,
                    color: const Color(0xFFF59E0B),
                  );
                }),
              ),
            ),
          Text(
            value,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary),
          ),
        ],
      ),
    );
  }
}
