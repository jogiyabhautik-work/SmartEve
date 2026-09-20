import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../models/anchor_dashboard_models.dart';
import '../../events/event_prep_screen.dart';
import '../../live_dashboard/live_dashboard_screen.dart';

class UpcomingEventCard extends StatelessWidget {
  final AnchorEventCardItem event;

  const UpcomingEventCard({
    super.key,
    required this.event,
  });

  @override
  Widget build(BuildContext context) {
    final bool isLive = event.status == AnchorEventStatus.active;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(AppTheme.radiusCard),
        border: Border.all(
          color: isLive ? AppTheme.success : AppTheme.border,
          width: isLive ? 1.5 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: isLive
                ? AppTheme.success.withValues(alpha: 0.1)
                : AppTheme.deepNavy.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _navigateToDetails(context),
          borderRadius: BorderRadius.circular(AppTheme.radiusCard),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top Row: Title, Type Icon & Status Badge
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: isLive
                            ? AppTheme.success.withValues(alpha: 0.12)
                            : AppTheme.primaryBlue.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        _getEventTypeIcon(event.eventType),
                        color: isLive ? AppTheme.success : AppTheme.primaryBlue,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            event.title,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            '${event.eventType} • ${event.date} at ${event.time}',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppTheme.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Status Badge (Invited/Accepted/Active/Completed)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: event.status.backgroundColor,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (isLive) ...[
                            Container(
                              width: 6,
                              height: 6,
                              margin: const EdgeInsets.only(right: 4),
                              decoration: const BoxDecoration(
                                color: AppTheme.success,
                                shape: BoxShape.circle,
                              ),
                            ),
                          ],
                          Text(
                            event.status.label,
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: event.status.color,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Organizer & College Details
                Row(
                  children: [
                    const Icon(Icons.person_outline_rounded, size: 14, color: AppTheme.textSecondary),
                    const SizedBox(width: 5),
                    Flexible(
                      child: Text(
                        event.organizerName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppTheme.textSecondary),
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Icon(Icons.school_outlined, size: 14, color: AppTheme.textSecondary),
                    const SizedBox(width: 5),
                    Expanded(
                      child: Text(
                        event.collegeName,
                        style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),

                // CTA Button: View Details (or Open Teleprompter HUD when live)
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () => _navigateToDetails(context),
                        icon: Icon(
                          isLive ? Icons.play_arrow_rounded : Icons.arrow_forward_rounded,
                          size: 16,
                        ),
                        label: Text(isLive ? 'OPEN LIVE TELEPROMPTER' : 'View Details'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: isLive ? AppTheme.success : AppTheme.primaryBlue,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(AppTheme.radiusButton),
                          ),
                          textStyle: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.3,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  IconData _getEventTypeIcon(String type) {
    switch (type.toLowerCase()) {
      case 'summit':
      case 'conference':
        return Icons.business_center_rounded;
      case 'competition':
      case 'hackathon':
        return Icons.emoji_events_rounded;
      case 'seminar':
      case 'workshop':
        return Icons.school_rounded;
      case 'cultural program':
      case 'cultural':
        return Icons.theater_comedy_rounded;
      default:
        return Icons.event_rounded;
    }
  }

  void _navigateToDetails(BuildContext context) {
    if (event.status == AnchorEventStatus.active) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => LiveDashboardScreen(eventId: event.id)),
      );
    } else {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => EventPrepScreen(
            eventId: event.id,
            status: event.status,
            organizerName: event.organizerName,
            collegeName: event.collegeName,
          ),
        ),
      );
    }
  }
}
