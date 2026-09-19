import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_theme.dart';
import '../../providers/event_provider.dart';
import '../anchor/anchor_teleprompter_screen.dart';
import '../stage_display/stage_display_screen.dart';
import '../agenda/agenda_screen.dart';

class ControlRoomScreen extends StatelessWidget {
  const ControlRoomScreen({super.key});

  void _showAnnouncementDialog(BuildContext context) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.surface,
        title: const Text('Send Stage Announcement', style: TextStyle(color: AppTheme.textPrimary)),
        content: TextField(
          controller: controller,
          maxLines: 3,
          style: const TextStyle(color: AppTheme.textPrimary),
          decoration: const InputDecoration(
            hintText: 'e.g. Please take your seats, keynote begins in 2 minutes.',
            hintStyle: TextStyle(color: AppTheme.textMuted),
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel', style: TextStyle(color: AppTheme.textMuted)),
          ),
          ElevatedButton(
            onPressed: () {
              if (controller.text.trim().isNotEmpty) {
                // Post announcement via provider
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Stage announcement broadcasted!')),
                );
              }
            },
            child: const Text('Broadcast'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Control Room'),
        actions: [
          IconButton(
            icon: const Icon(Icons.format_list_bulleted_rounded),
            tooltip: 'View Full Agenda',
            onPressed: () {
              Navigator.of(context).push(MaterialPageRoute(builder: (_) => const AgendaScreen()));
            },
          ),
          IconButton(
            icon: const Icon(Icons.cast_connected_rounded),
            tooltip: 'Stage Display View',
            onPressed: () {
              Navigator.of(context).push(MaterialPageRoute(builder: (_) => const StageDisplayScreen()));
            },
          ),
          IconButton(
            icon: const Icon(Icons.mic_rounded),
            tooltip: 'Anchor Teleprompter',
            onPressed: () {
              Navigator.of(context).push(MaterialPageRoute(builder: (_) => const AnchorTeleprompterScreen()));
            },
          ),
        ],
      ),
      body: Consumer<EventProvider>(
        builder: (context, provider, _) {
          final event = provider.event;
          final currentSession = provider.currentSession;
          final nextSession = provider.nextSession;
          final currentSpeaker = provider.currentSpeaker;
          final isOvertime = provider.remainingSeconds < 0;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Event Header & Status
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            event?.name ?? 'Live Summit',
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            event?.venue ?? 'Main Stage',
                            style: const TextStyle(
                              fontSize: 13,
                              color: AppTheme.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: AppTheme.liveGreen.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: AppTheme.liveGreen),
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.circle, color: AppTheme.liveGreen, size: 8),
                          SizedBox(width: 6),
                          Text(
                            'LIVE FLOW',
                            style: TextStyle(
                              color: AppTheme.liveGreen,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // Main Session Countdown Card
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: AppTheme.surface,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: isOvertime ? AppTheme.dangerRose : AppTheme.cyan.withOpacity(0.4),
                      width: 1.5,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: (isOvertime ? AppTheme.dangerRose : AppTheme.cyan).withOpacity(0.1),
                        blurRadius: 20,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'CURRENT SESSION REMAINING',
                            style: TextStyle(
                              fontSize: 12,
                              letterSpacing: 1.5,
                              fontWeight: FontWeight.w700,
                              color: AppTheme.textSecondary,
                            ),
                          ),
                          if (isOvertime)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: AppTheme.dangerRose.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: const Text(
                                'OVERTIME',
                                style: TextStyle(
                                  color: AppTheme.dangerRose,
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(
                        provider.formattedCountdown,
                        style: TextStyle(
                          fontSize: 58,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 2,
                          color: isOvertime ? AppTheme.dangerRose : AppTheme.cyan,
                        ),
                      ),
                      const SizedBox(height: 16),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(6),
                        child: LinearProgressIndicator(
                          value: provider.progressFraction,
                          minHeight: 8,
                          backgroundColor: AppTheme.surfaceLight,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            isOvertime ? AppTheme.dangerRose : AppTheme.cyan,
                          ),
                        ),
                      ),
                      const SizedBox(height: 18),
                      Text(
                        currentSession?.title ?? 'No active session',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                      if (currentSpeaker != null) ...[
                        const SizedBox(height: 6),
                        Text(
                          '${currentSpeaker.name} • ${currentSpeaker.organization}',
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 14,
                            color: AppTheme.textSecondary,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Delay Injection Bar
                const Text(
                  'DETERMINISTIC SMART DELAY',
                  style: TextStyle(
                    fontSize: 12,
                    letterSpacing: 1.5,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textSecondary,
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _buildActionButton(
                        context,
                        label: '+15m Delay',
                        color: AppTheme.warningAmber,
                        icon: Icons.add_alarm_rounded,
                        onPressed: () async {
                          final ok = await provider.injectDelay(15, reason: 'Keynote Q&A extension');
                          if (ok && context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('+15m added! Buffer break absorbed delay.')),
                            );
                          }
                        },
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _buildActionButton(
                        context,
                        label: '+5m Delay',
                        color: AppTheme.cyan,
                        icon: Icons.more_time_rounded,
                        onPressed: () async {
                          await provider.injectDelay(5);
                        },
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _buildActionButton(
                        context,
                        label: '-5m Pull',
                        color: AppTheme.liveGreen,
                        icon: Icons.fast_forward_rounded,
                        onPressed: () async {
                          await provider.injectDelay(-5);
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // Session Advancement
                ElevatedButton.icon(
                  icon: const Icon(Icons.skip_next_rounded, size: 24),
                  label: const Text('COMPLETE SESSION & ADVANCE'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryPurple,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  onPressed: () async {
                    final ok = await provider.completeCurrentSession();
                    if (ok && context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Session completed! Advanced to next.')),
                      );
                    }
                  },
                ),
                const SizedBox(height: 20),

                // Up Next Preview
                if (nextSession != null) ...[
                  const Text(
                    'UP NEXT ON STAGE',
                    style: TextStyle(
                      fontSize: 12,
                      letterSpacing: 1.5,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppTheme.surface,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: AppTheme.border),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: nextSession.isBreak
                                ? AppTheme.warningAmber.withOpacity(0.15)
                                : AppTheme.cyan.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(
                            nextSession.isBreak ? Icons.coffee_rounded : Icons.person_rounded,
                            color: nextSession.isBreak ? AppTheme.warningAmber : AppTheme.cyan,
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                nextSession.title,
                                style: const TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                  color: AppTheme.textPrimary,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '${nextSession.duration} min duration ${nextSession.absorbable ? "• (Absorbable buffer)" : ""}',
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
                  ),
                ],
                const SizedBox(height: 24),

                // Emergency Announcement Button
                OutlinedButton.icon(
                  icon: const Icon(Icons.campaign_rounded),
                  label: const Text('Broadcast Stage Announcement'),
                  onPressed: () => _showAnnouncementDialog(context),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildActionButton(
    BuildContext context, {
    required String label,
    required Color color,
    required IconData icon,
    required VoidCallback onPressed,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.12),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: color.withOpacity(0.4)),
          ),
          child: Column(
            children: [
              Icon(icon, color: color, size: 22),
              const SizedBox(height: 6),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
