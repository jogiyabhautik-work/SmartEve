import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../anchor/anchor_teleprompter_screen.dart';
import '../scripts/scripts_library_screen.dart';
import 'providers/live_dashboard_provider.dart';
import 'widgets/current_activity_section.dart';
import 'widgets/emergency_contact_dialog.dart';
import 'widgets/live_top_bar.dart';
import 'widgets/next_up_queue_section.dart';
import 'widgets/smart_controls_scripts_section.dart';

class LiveDashboardScreen extends StatefulWidget {
  final String eventId;
  const LiveDashboardScreen({
    super.key,
    this.eventId = "20b06ff2-bcdb-478d-9ebc-725f50f1f601",
  });

  @override
  State<LiveDashboardScreen> createState() => _LiveDashboardScreenState();
}

class _LiveDashboardScreenState extends State<LiveDashboardScreen> {
  bool _oneMinAlertShownForActivityId = false;
  String? _lastActivityId;

  @override
  void initState() {
    super.initState();
    // Enable immersive fullscreen and keep screen active during live stage performance
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
  }

  @override
  void dispose() {
    // Restore normal system overlays on exit
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    super.dispose();
  }

  void _openTeleprompter() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const AnchorTeleprompterScreen()),
    );
  }

  void _openScriptsLibrary() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const ScriptsLibraryScreen(),
      ),
    );
  }

  void _showAiAssistSheet(BuildContext context, LiveDashboardProvider provider) {
    final currentTitle = provider.currentActivity?.title ?? "current segment";
    final nextTitle = provider.nextActivity?.title ?? "next segment";
    final templates = {
      "Paraphrase this":
          "Paraphrase this for stage: '${provider.currentScript?.content ?? 'Welcome everyone to SmartEve Live.'}' Keep it warm, crisp and under 30 seconds.",
      "Give me transition":
          "Write a 2-line stage transition from '$currentTitle' to '$nextTitle'. Energetic, professional, with an applause cue.",
      "Emergency script":
          "Write a calm 30-second emergency holding script for a technical delay during '$currentTitle'. Reassure the audience and cue the backstage crew.",
    };

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: EdgeInsets.only(
          left: 20,
          right: 20,
          top: 20,
          bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
        ),
        decoration: const BoxDecoration(
          color: Color(0xFF0F172A),
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          border: Border(
            top: BorderSide(color: Color(0xFF6366F1), width: 2),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF4E6BEB), Color(0xFF7C5CFC)],
                    ),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.auto_awesome_rounded,
                      color: Colors.white, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Need script help?",
                        style: GoogleFonts.inter(
                          fontSize: 17,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                        ),
                      ),
                      Text(
                        "SmartEve AI Assist • on-stage co-pilot",
                        style: GoogleFonts.inter(
                            fontSize: 12, color: const Color(0xFF94A3B8)),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close, color: Colors.white54),
                  onPressed: () => Navigator.pop(ctx),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: templates.keys.map((label) {
                return ActionChip(
                  backgroundColor: const Color(0xFF1E293B),
                  side: BorderSide(
                      color: Colors.white.withValues(alpha: 0.12)),
                  label: Text(label,
                      style: GoogleFonts.inter(
                          fontSize: 12, color: const Color(0xFFE2E8F0))),
                  avatar: const Icon(Icons.bolt_rounded,
                      size: 14, color: Color(0xFFFBBF24)),
                  onPressed: () {
                    Navigator.pop(ctx);
                    final prompt = templates[label]!;
                    provider.postStageMessage(
                        "🤖 AI Assist requested: $label");
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          "SmartEve AI drafting: $label…\n$prompt",
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                        ),
                        backgroundColor: const Color(0xFF312E81),
                        behavior: SnackBarBehavior.floating,
                        duration: const Duration(seconds: 4),
                      ),
                    );
                  },
                );
              }).toList(),
            ),
            const SizedBox(height: 8),
            Text(
              "Tip: drafts appear in your On-Stage Script card and teleprompter.",
              style: GoogleFonts.inter(
                  fontSize: 11, color: const Color(0xFF64748B)),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<LiveDashboardProvider>(
      create: (_) => LiveDashboardProvider(eventId: widget.eventId),
      child: Builder(
        builder: (context) {
          final provider = context.watch<LiveDashboardProvider>();

          // One-minute warning: optional sound + banner (fires once per activity).
          final currentId = provider.currentActivity?.id;
          if (currentId != _lastActivityId) {
            _lastActivityId = currentId;
            _oneMinAlertShownForActivityId = false;
          }
          if (provider.isNextImminent && !_oneMinAlertShownForActivityId) {
            _oneMinAlertShownForActivityId = true;
            if (provider.soundEnabled) {
              SystemSound.play(SystemSoundType.alert);
            }
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (!context.mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    "⏰ '${provider.nextActivity?.title ?? 'Next activity'}' starts in 1 min — get ready!",
                    style: GoogleFonts.inter(fontWeight: FontWeight.w600),
                  ),
                  backgroundColor: const Color(0xFFB45309),
                  behavior: SnackBarBehavior.floating,
                  duration: const Duration(seconds: 4),
                ),
              );
            });
          }

          return Scaffold(
            backgroundColor: const Color(0xFF070B14), // Deep stage dark mode
            floatingActionButton: FloatingActionButton.extended(
              onPressed: () => _showAiAssistSheet(context, provider),
              backgroundColor: const Color(0xFF4E6BEB),
              foregroundColor: Colors.white,
              icon: const Icon(Icons.auto_awesome_rounded, size: 18),
              label: Text(
                "SmartEve AI Assist",
                style: GoogleFonts.inter(
                    fontSize: 12, fontWeight: FontWeight.w800),
              ),
            ),
            body: SafeArea(
              bottom: false,
              child: GestureDetector(
                onDoubleTap: () {
                  // Double tap shortcut for emergency dialog
                  showDialog(
                    context: context,
                    builder: (_) => ChangeNotifierProvider.value(
                      value: provider,
                      child: const EmergencyContactDialog(),
                    ),
                  );
                },
                child: Column(
                  children: [
                    // Top Bar (Compact, Always Visible)
                    LiveTopBar(
                      onExit: () => Navigator.of(context).pop(),
                    ),

                    // Quick Navigation Sub-Bar (Podium View, Teleprompter, Scripts)
                    Container(
                      height: 36,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      decoration: BoxDecoration(
                        color: const Color(0xFF0F172A).withValues(alpha: 0.6),
                        border: Border(
                          bottom: BorderSide(
                              color:
                                  Colors.white.withValues(alpha: 0.06)),
                        ),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: const Color(0xFF10B981)
                                  .withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.check_circle_rounded,
                                    size: 12, color: Color(0xFF10B981)),
                                const SizedBox(width: 4),
                                Text(
                                  "NEON DB SYNCED",
                                  style: GoogleFonts.inter(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w800,
                                    color: const Color(0xFF10B981),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              "Tip: Double-tap anywhere for emergency organizer dialer",
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.inter(
                                fontSize: 11,
                                color: const Color(0xFF94A3B8),
                              ),
                            ),
                          ),
                          // Sound toggle for 1-min warning
                          InkWell(
                            onTap: provider.toggleSound,
                            borderRadius: BorderRadius.circular(6),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.white
                                    .withValues(alpha: 0.05),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    provider.soundEnabled
                                        ? Icons.volume_up_rounded
                                        : Icons.volume_off_rounded,
                                    size: 13,
                                    color: provider.soundEnabled
                                        ? const Color(0xFF38BDF8)
                                        : Colors.white38,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    provider.soundEnabled
                                        ? "Sound On"
                                        : "Muted",
                                    style: GoogleFonts.inter(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w700,
                                      color: provider.soundEnabled
                                          ? const Color(0xFF38BDF8)
                                          : Colors.white38,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(width: 4),
                          // Quick jump buttons
                          TextButton.icon(
                            onPressed: _openTeleprompter,
                            icon: const Icon(Icons.tv_rounded,
                                size: 14, color: Color(0xFF38BDF8)),
                            label: Text(
                              "Teleprompter",
                              style: GoogleFonts.inter(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: const Color(0xFF38BDF8),
                              ),
                            ),
                            style: TextButton.styleFrom(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8),
                              visualDensity: VisualDensity.compact,
                            ),
                          ),
                          const SizedBox(width: 8),
                          TextButton.icon(
                            onPressed: _openScriptsLibrary,
                            icon: const Icon(Icons.library_books_rounded,
                                size: 14, color: Color(0xFFA78BFA)),
                            label: Text(
                              "Scripts Library",
                              style: GoogleFonts.inter(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: const Color(0xFFA78BFA),
                              ),
                            ),
                            style: TextButton.styleFrom(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8),
                              visualDensity: VisualDensity.compact,
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Imminent-next banner (immersive visual cue)
                    if (provider.isNextImminent)
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 6),
                        color: const Color(0xFFB45309)
                            .withValues(alpha: 0.25),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.timer_rounded,
                                size: 14, color: Color(0xFFFBBF24)),
                            const SizedBox(width: 6),
                            Text(
                              "Next: '${provider.nextActivity?.title ?? ''}' in ${provider.formatDuration(provider.timeUntilNextSeconds)} — standby",
                              style: GoogleFonts.inter(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: const Color(0xFFFDE68A),
                              ),
                            ),
                          ],
                        ),
                      ),

                    // Completed history fade strip
                    if (provider.completedHistory.isNotEmpty)
                      Container(
                        height: 30,
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        child: ListView.separated(
                          scrollDirection: Axis.horizontal,
                          itemCount: provider.completedHistory.length,
                          separatorBuilder: (_, __) =>
                              const SizedBox(width: 8),
                          itemBuilder: (ctx, i) {
                            final item =
                                provider.completedHistory[i];
                            return Opacity(
                              opacity: 0.45,
                              child: Chip(
                                backgroundColor:
                                    const Color(0xFF1E293B),
                                side: BorderSide(
                                    color: Colors.white.withValues(
                                        alpha: 0.08)),
                                avatar: const Icon(
                                    Icons.check_circle_outline_rounded,
                                    size: 14,
                                    color: Color(0xFF10B981)),
                                label: Text(
                                  item.title,
                                  style: GoogleFonts.inter(
                                      fontSize: 10,
                                      color: Colors.white70),
                                ),
                                visualDensity:
                                    VisualDensity.compact,
                              ),
                            );
                          },
                        ),
                      ),

                    // Main 3-Section Content Layout
                    Expanded(
                      child: provider.isLoading
                          ? const Center(
                              child: CircularProgressIndicator(
                                  color: Color(0xFF38BDF8)),
                            )
                          : LayoutBuilder(
                              builder: (context, constraints) {
                                final w = constraints.maxWidth;
                                // Desktop: 3-section split (landscape preferred)
                                if (w >= 1000) {
                                  // Landscape 3-Section Split: 50% / 25% / 25%
                                  return Padding(
                                    padding: const EdgeInsets.all(12),
                                    child: Row(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.stretch,
                                      children: [
                                        // Section 1: Current Activity (50% width)
                                        Expanded(
                                          flex: 5,
                                          child: AnimatedSwitcher(
                                            duration: const Duration(
                                                milliseconds: 450),
                                            switchInCurve: Curves.easeOut,
                                            switchOutCurve: Curves.easeIn,
                                            child: CurrentActivitySection(
                                              key: ValueKey(provider
                                                      .currentActivity?.id ??
                                                  'empty'),
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 12),

                                        // Section 2: Next Up & Queue (25% width)
                                        const Expanded(
                                          flex: 3,
                                          child: NextUpQueueSection(),
                                        ),
                                        const SizedBox(width: 12),

                                        // Section 3: Smart Controls & Scripts (25% width)
                                        Expanded(
                                          flex: 3,
                                          child:
                                              SmartControlsScriptsSection(
                                            onOpenTeleprompter:
                                                _openTeleprompter,
                                          ),
                                        ),
                                      ],
                                    ),
                                  );
                                } else if (w >= 700) {
                                  // Tablet: 2-column (Current + Next | Controls)
                                  return Padding(
                                    padding: const EdgeInsets.all(12),
                                    child: Row(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.stretch,
                                      children: [
                                        Expanded(
                                          flex: 7,
                                          child: Column(
                                            children: [
                                              Expanded(
                                                flex: 6,
                                                child: AnimatedSwitcher(
                                                  duration:
                                                      const Duration(
                                                          milliseconds:
                                                              450),
                                                  child:
                                                      CurrentActivitySection(
                                                    key: ValueKey(provider
                                                            .currentActivity
                                                            ?.id ??
                                                        'empty'),
                                                  ),
                                                ),
                                              ),
                                              const SizedBox(height: 12),
                                              const Expanded(
                                                flex: 4,
                                                child:
                                                    NextUpQueueSection(),
                                              ),
                                            ],
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          flex: 4,
                                          child:
                                              SmartControlsScriptsSection(
                                            onOpenTeleprompter:
                                                _openTeleprompter,
                                          ),
                                        ),
                                      ],
                                    ),
                                  );
                                } else {
                                  // Mobile: Vertical stack (Current | Next | Controls)
                                  return SingleChildScrollView(
                                    padding: const EdgeInsets.all(12),
                                    child: Column(
                                      children: [
                                        SizedBox(
                                          height: 480,
                                          child: AnimatedSwitcher(
                                            duration: const Duration(
                                                milliseconds: 450),
                                            child: CurrentActivitySection(
                                              key: ValueKey(provider
                                                      .currentActivity?.id ??
                                                  'empty'),
                                            ),
                                          ),
                                        ),
                                        const SizedBox(height: 12),
                                        const SizedBox(
                                          height: 380,
                                          child: NextUpQueueSection(),
                                        ),
                                        const SizedBox(height: 12),
                                        SizedBox(
                                          height: 480,
                                          child:
                                              SmartControlsScriptsSection(
                                            onOpenTeleprompter:
                                                _openTeleprompter,
                                          ),
                                        ),
                                        const SizedBox(height: 80),
                                      ],
                                    ),
                                  );
                                }
                              },
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
}
