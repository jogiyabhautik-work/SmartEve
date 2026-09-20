import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../../../models/script_model.dart';

class ScriptCard extends StatelessWidget {
  final ScriptModel script;
  final VoidCallback onTap;
  final VoidCallback? onViewFullScript;
  final bool isCurrentOrNext;

  const ScriptCard({
    super.key,
    required this.script,
    required this.onTap,
    this.onViewFullScript,
    this.isCurrentOrNext = false,
  });

  @override
  Widget build(BuildContext context) {
    final typeBadgeColor = script.badgeColor;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          decoration: BoxDecoration(
            color: AppTheme.surface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: isCurrentOrNext
                  ? AppTheme.primaryBlue
                  : (script.isNew
                      ? AppTheme.cyan
                      : (script.isUpdated ? AppTheme.warning : AppTheme.border)),
              width: isCurrentOrNext ? 2.0 : 1.2,
            ),
            boxShadow: [
              BoxShadow(
                color: isCurrentOrNext
                    ? AppTheme.primaryBlue.withValues(alpha: 0.12)
                    : AppTheme.deepNavy.withValues(alpha: 0.04),
                blurRadius: isCurrentOrNext ? 12 : 8,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // --- Top Meta Row: Badge, Status, NEW/UPDATED chips ---
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Color-coded Script Type Badge
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: typeBadgeColor.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(
                        color: typeBadgeColor.withValues(alpha: 0.35),
                        width: 1,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 7,
                          height: 7,
                          decoration: BoxDecoration(
                            color: typeBadgeColor,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          script.typeLabel.toUpperCase(),
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.6,
                            color: typeBadgeColor,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(width: 8),

                  // NEW badge
                  if (script.isNew)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                      decoration: BoxDecoration(
                        color: AppTheme.cyan.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(5),
                        border: Border.all(color: AppTheme.cyan.withValues(alpha: 0.5)),
                      ),
                      child: const Text(
                        'NEW',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 0.5,
                          color: AppTheme.cyan,
                        ),
                      ),
                    ),

                  // UPDATED badge
                  if (script.isUpdated)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                      decoration: BoxDecoration(
                        color: AppTheme.warning.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(5),
                        border: Border.all(color: AppTheme.warning.withValues(alpha: 0.5)),
                      ),
                      child: const Text(
                        'UPDATED',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 0.5,
                          color: AppTheme.warning,
                        ),
                      ),
                    ),

                  const Spacer(),

                  // Status indicator (Approved green checkmark, Pending yellow dot, Revised blue dot)
                  _buildStatusIndicator(),
                ],
              ),

              const SizedBox(height: 12),

              // --- Script Title ---
              Text(
                script.title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                  color: AppTheme.textPrimary,
                  height: 1.25,
                ),
              ),

              const SizedBox(height: 8),

              // --- Time Slot & Duration Row ---
              Row(
                children: [
                  Icon(
                    Icons.access_time_rounded,
                    size: 14,
                    color: AppTheme.textSecondary.withValues(alpha: 0.8),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    script.timeSlot ?? 'Time TBD',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Container(
                    width: 3,
                    height: 3,
                    decoration: const BoxDecoration(
                      color: AppTheme.textMuted,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Icon(
                    Icons.hourglass_bottom_rounded,
                    size: 14,
                    color: AppTheme.textSecondary.withValues(alpha: 0.8),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '${script.durationMinutes} mins',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 10),

              // --- Quick Preview Text (first 50 chars + "...") ---
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  color: AppTheme.surfaceLight.withValues(alpha: 0.4),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppTheme.border.withValues(alpha: 0.6)),
                ),
                child: Text(
                  script.previewText(50),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 13,
                    height: 1.4,
                    color: AppTheme.textPrimary.withValues(alpha: 0.85),
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ),

              const SizedBox(height: 14),

              // --- Bottom Action Row: Review state & "View Full Script" CTA ---
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Reviewed by Anchor tag
                  Row(
                    children: [
                      Icon(
                        script.isReviewedByAnchor
                            ? Icons.verified_user_rounded
                            : Icons.visibility_outlined,
                        size: 14,
                        color: script.isReviewedByAnchor
                            ? AppTheme.success
                            : (script.viewedByAnchor
                                ? AppTheme.primaryBlue
                                : AppTheme.textMuted),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        script.isReviewedByAnchor
                            ? 'Anchor Reviewed'
                            : (script.viewedByAnchor ? 'Viewed' : 'Unread'),
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: script.isReviewedByAnchor
                              ? AppTheme.success
                              : (script.viewedByAnchor
                                  ? AppTheme.primaryBlue
                                  : AppTheme.textMuted),
                        ),
                      ),
                    ],
                  ),

                  // "View Full Script" CTA Button
                  InkWell(
                    onTap: onViewFullScript ?? onTap,
                    borderRadius: BorderRadius.circular(8),
                    child: const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'View Full Script',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w800,
                              color: AppTheme.primaryBlue,
                            ),
                          ),
                          SizedBox(width: 4),
                          Icon(
                            Icons.arrow_forward_rounded,
                            size: 14,
                            color: AppTheme.primaryBlue,
                          ),
                        ],
                      ),
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

  Widget _buildStatusIndicator() {
    if (script.isApproved) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: AppTheme.success.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(6),
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.check_circle_rounded,
              size: 13,
              color: AppTheme.success,
            ),
            SizedBox(width: 4),
            Text(
              'Approved',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: AppTheme.success,
              ),
            ),
          ],
        ),
      );
    } else if (script.isPending) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: AppTheme.warning.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(6),
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.circle,
              size: 9,
              color: AppTheme.warning,
            ),
            SizedBox(width: 4),
            Text(
              'Pending',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: AppTheme.warning,
              ),
            ),
          ],
        ),
      );
    } else {
      // Revised
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: AppTheme.accentBlue.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(6),
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.circle,
              size: 9,
              color: AppTheme.accentBlue,
            ),
            SizedBox(width: 4),
            Text(
              'Revised',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: AppTheme.accentBlue,
              ),
            ),
          ],
        ),
      );
    }
  }
}
