import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../core/theme/app_theme.dart';
import '../../providers/event_provider.dart';

class StageDisplayScreen extends StatelessWidget {
  const StageDisplayScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Consumer<EventProvider>(
          builder: (context, provider, _) {
            final session = provider.currentSession;
            final speaker = provider.currentSpeaker;
            final nextSession = provider.nextSession;
            final notifications = provider.notifications;
            final isOvertime = provider.remainingSeconds < 0;

            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Top Bar: Event Name and Exit
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        provider.event?.name.toUpperCase() ?? 'STAGE DISPLAY',
                        style: const TextStyle(
                          fontSize: 16,
                          letterSpacing: 2,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.textSecondary,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close_rounded, color: AppTheme.textMuted),
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                    ],
                  ),

                  // Stage Announcement Banner
                  if (notifications.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                      decoration: BoxDecoration(
                        color: AppTheme.warningAmber.withValues(alpha: 0.18),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: AppTheme.warningAmber, width: 1.5),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.campaign_rounded, color: AppTheme.warningAmber, size: 24),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              notifications.first.message,
                              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppTheme.warningAmber),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],

                  const Spacer(),

                  // Giant Stage Countdown Timer
                  Center(
                    child: Text(
                      provider.formattedCountdown,
                      style: TextStyle(
                        fontSize: 96,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 4,
                        color: isOvertime
                            ? AppTheme.dangerRose
                            : (provider.remainingSeconds < 300
                                ? AppTheme.warningAmber
                                : AppTheme.cyan),
                        fontFeatures: const [FontFeature.tabularFigures()],
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    isOvertime ? 'OVERTIME — PLEASE WRAP UP' : 'SESSION TIME REMAINING',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 14,
                      letterSpacing: 3,
                      fontWeight: FontWeight.w800,
                      color: isOvertime ? AppTheme.dangerRose : AppTheme.textSecondary,
                    ),
                  ),
                  const Spacer(),

                  // Current Topic Billboard
                  Container(
                    padding: const EdgeInsets.all(28),
                    decoration: BoxDecoration(
                      color: AppTheme.surface,
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: AppTheme.border, width: 1.5),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'NOW ON STAGE',
                          style: TextStyle(
                            fontSize: 12,
                            letterSpacing: 2,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.cyan,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          session?.title ?? 'Intermission',
                          style: const TextStyle(
                            fontSize: 26,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.textPrimary,
                          ),
                        ),
                        if (speaker != null) ...[
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              if (speaker.photoUrl != null && speaker.photoUrl!.isNotEmpty) ...[
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(10),
                                  child: CachedNetworkImage(
                                    imageUrl: speaker.photoUrl!,
                                    width: 44,
                                    height: 44,
                                    fit: BoxFit.cover,
                                    placeholder: (_, __) => Container(color: AppTheme.surfaceLight),
                                    errorWidget: (_, __, ___) => const Icon(Icons.person, color: AppTheme.cyan),
                                  ),
                                ),
                                const SizedBox(width: 14),
                              ],
                              Expanded(
                                child: Text(
                                  '${speaker.name} • ${speaker.designation} (${speaker.organization})',
                                  style: const TextStyle(
                                    fontSize: 16,
                                    color: AppTheme.textSecondary,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Up Next Ticker
                  if (nextSession != null)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                      decoration: BoxDecoration(
                        color: AppTheme.surface.withValues(alpha: 0.5),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: AppTheme.border),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.arrow_forward_rounded, color: AppTheme.textMuted, size: 18),
                          const SizedBox(width: 10),
                          const Text(
                            'NEXT: ',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                              color: AppTheme.cyan,
                            ),
                          ),
                          Expanded(
                            child: Text(
                              nextSession.title,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 13,
                                color: AppTheme.textPrimary,
                              ),
                            ),
                          ),
                          Text(
                            '${nextSession.duration} min',
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppTheme.textMuted,
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
    );
  }
}
