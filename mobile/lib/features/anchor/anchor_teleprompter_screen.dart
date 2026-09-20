import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../core/services/tts_service.dart';
import '../../core/services/auth_service.dart';
import '../../core/theme/app_theme.dart';
import '../../providers/event_provider.dart';
import '../dashboard/stagepilot_dashboard_screen.dart';
import '../auth/role_selection_screen.dart';
import '../scripts/scripts_library_screen.dart';
import '../live_dashboard/live_dashboard_screen.dart';

class AnchorTeleprompterScreen extends StatefulWidget {
  const AnchorTeleprompterScreen({super.key});

  @override
  State<AnchorTeleprompterScreen> createState() => _AnchorTeleprompterScreenState();
}

class _AnchorTeleprompterScreenState extends State<AnchorTeleprompterScreen> {
  final TtsService _ttsService = TtsService();
  String _currentScriptText = '';
  String _scriptSource = 'AI Generated';
  bool _isGenerating = false;
  bool _isSpeaking = false;

  @override
  void initState() {
    super.initState();
    _ttsService.init();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final provider = context.read<EventProvider>();
      if (provider.event == null) {
        await provider.fetchOrganizerEvents();
        if (provider.organizerEvents.isNotEmpty) {
          provider.selectEvent(provider.organizerEvents.first);
        }
      }
      _generateScript('speaker_intro');
    });
  }

  @override
  void dispose() {
    _ttsService.stop();
    super.dispose();
  }

  Future<void> _generateScript(String type) async {
    setState(() => _isGenerating = true);
    final provider = context.read<EventProvider>();
    final result = await provider.generateAiScript(type);

    if (mounted) {
      setState(() {
        _isGenerating = false;
        if (result != null && result.isNotEmpty) {
          _currentScriptText = result;
          _scriptSource = provider.activeScript?.provider?.toUpperCase() ?? 'AI CO-PILOT';
        } else {
          // Fallback script
          _currentScriptText =
              'Good morning everyone, please give a warm welcome to our esteemed speaker on stage today!';
          _scriptSource = 'OFFLINE TEMPLATE';
        }
      });
    }
  }

  Future<void> _toggleTts() async {
    if (_isSpeaking) {
      await _ttsService.stop();
      setState(() => _isSpeaking = false);
    } else {
      if (_currentScriptText.isNotEmpty) {
        setState(() => _isSpeaking = true);
        await _ttsService.speak(_currentScriptText);
      }
    }
  }

  void _handleSignOut() async {
    await AuthService().confirmSignOut(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Anchor Teleprompter'),
        actions: [
          Consumer<EventProvider>(
            builder: (context, provider, _) {
              return Container(
                margin: const EdgeInsets.only(right: 8),
                alignment: Alignment.center,
                child: Text(
                  provider.formattedCountdown,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                    color: provider.remainingSeconds < 0 ? AppTheme.dangerRose : AppTheme.cyan,
                  ),
                ),
              );
            },
          ),
          IconButton(
            tooltip: 'Live Stage Dashboard',
            icon: const Icon(Icons.co_present_rounded, color: Color(0xFFEF4444)),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const LiveDashboardScreen()),
              );
            },
          ),
          IconButton(
            tooltip: 'Scripts Library',
            icon: const Icon(Icons.description_rounded, color: AppTheme.primaryBlue),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const ScriptsLibraryScreen()),
              );
            },
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert_rounded, color: AppTheme.textPrimary),
            color: AppTheme.surface,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: const BorderSide(color: AppTheme.border),
            ),
            onSelected: (value) {
              if (value == 'live_stage') {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const LiveDashboardScreen()),
                );
              } else if (value == 'scripts') {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const ScriptsLibraryScreen()),
                );
              } else if (value == 'organizer') {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const StagePilotDashboardScreen()),
                );
              } else if (value == 'roles') {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const RoleSelectionScreen()),
                );
              } else if (value == 'logout') {
                _handleSignOut();
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'live_stage',
                child: Row(
                  children: [
                    Icon(Icons.co_present_rounded, size: 18, color: Color(0xFFEF4444)),
                    SizedBox(width: 10),
                    Text('Live Stage Dashboard', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFFEF4444))),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'scripts',
                child: Row(
                  children: [
                    Icon(Icons.description_rounded, size: 18, color: AppTheme.primaryBlue),
                    SizedBox(width: 10),
                    Text('Scripts Library', style: TextStyle(color: AppTheme.textPrimary, fontSize: 13)),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'organizer',
                child: Row(
                  children: [
                    Icon(Icons.dashboard_customize_rounded, size: 18, color: AppTheme.cyan),
                    SizedBox(width: 10),
                    Text('Organizer Suite', style: TextStyle(color: AppTheme.textPrimary, fontSize: 13)),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'roles',
                child: Row(
                  children: [
                    Icon(Icons.swap_horiz_rounded, size: 18, color: AppTheme.warningAmber),
                    SizedBox(width: 10),
                    Text('Switch Role / Join Code', style: TextStyle(color: AppTheme.textPrimary, fontSize: 13)),
                  ],
                ),
              ),
              const PopupMenuDivider(),
              const PopupMenuItem(
                value: 'logout',
                child: Row(
                  children: [
                    Icon(Icons.logout_rounded, size: 18, color: AppTheme.dangerRose),
                    SizedBox(width: 10),
                    Text('Sign Out', style: TextStyle(color: AppTheme.dangerRose, fontSize: 13)),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: Consumer<EventProvider>(
        builder: (context, provider, _) {
          final speaker = provider.currentSpeaker;
          final session = provider.currentSession;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Active Speaker Banner
                Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: AppTheme.surface,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppTheme.border),
                  ),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 28,
                        backgroundColor: AppTheme.cyan.withValues(alpha: 0.2),
                        backgroundImage: (speaker?.photoUrl != null && speaker!.photoUrl!.isNotEmpty)
                            ? CachedNetworkImageProvider(speaker.photoUrl!)
                            : null,
                        child: (speaker?.photoUrl == null || speaker!.photoUrl!.isEmpty)
                            ? Text(
                                speaker != null && speaker.name.isNotEmpty
                                    ? speaker.name.substring(0, 1)
                                    : '🎤',
                                style: const TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                  color: AppTheme.cyan,
                                ),
                              )
                            : null,
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              speaker?.name ?? 'Keynote Speaker',
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${speaker?.designation ?? "Guest"} • ${speaker?.organization ?? "Summit"}',
                              style: const TextStyle(
                                fontSize: 13,
                                color: AppTheme.textSecondary,
                              ),
                            ),
                            if (session != null) ...[
                              const SizedBox(height: 6),
                              Text(
                                'Topic: "${session.title}"',
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: AppTheme.cyan,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // AI Co-Pilot Script Generator Toolbar
                const Text(
                  'AI CO-PILOT GENERATOR',
                  style: TextStyle(
                    fontSize: 12,
                    letterSpacing: 1.5,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textSecondary,
                  ),
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _buildAiChip('Speaker Intro', Icons.record_voice_over_rounded, () {
                      _generateScript('speaker_intro');
                    }),
                    _buildAiChip('Transition', Icons.swap_horiz_rounded, () {
                      _generateScript('transition');
                    }),
                    _buildAiChip('Delay Announcement', Icons.timer_outlined, () {
                      _generateScript('delay');
                    }),
                    _buildAiChip('Ad-hoc Banter', Icons.theater_comedy_rounded, () {
                      _generateScript('unexpected');
                    }),
                    _buildAiChip('Closing Ceremony', Icons.celebration_rounded, () {
                      _generateScript('closing');
                    }),
                  ],
                ),
                const SizedBox(height: 24),

                // Large Speakable Teleprompter Box
                Container(
                  padding: const EdgeInsets.all(22),
                  decoration: BoxDecoration(
                    color: AppTheme.surface,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: AppTheme.cyan.withValues(alpha: 0.5), width: 1.5),
                    boxShadow: [
                      BoxShadow(
                        color: AppTheme.cyan.withValues(alpha: 0.08),
                        blurRadius: 20,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: AppTheme.cyan.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.auto_awesome, color: AppTheme.cyan, size: 14),
                                const SizedBox(width: 6),
                                Text(
                                  _scriptSource,
                                  style: const TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    color: AppTheme.cyan,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const Text(
                            'SPEAK OUT LOUD',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1.5,
                              color: AppTheme.textMuted,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 18),
                      if (_isGenerating)
                        const Center(
                          child: Padding(
                            padding: EdgeInsets.symmetric(vertical: 40),
                            child: CircularProgressIndicator(color: AppTheme.cyan),
                          ),
                        )
                      else
                        Text(
                          _currentScriptText.isEmpty
                              ? 'Tap an AI prompt above to craft an instant speakable stage script.'
                              : _currentScriptText,
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w600,
                            height: 1.5,
                            letterSpacing: 0.3,
                            color: AppTheme.textPrimary,
                          ),
                        ),
                      const SizedBox(height: 24),

                      // Read Aloud TTS Button
                      ElevatedButton.icon(
                        icon: Icon(
                          _isSpeaking ? Icons.stop_circle_rounded : Icons.volume_up_rounded,
                          size: 22,
                        ),
                        label: Text(
                          _isSpeaking ? 'STOP AUDIO AUDITION' : 'LISTEN / READ ALOUD (TTS)',
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _isSpeaking ? AppTheme.dangerRose : AppTheme.cyan,
                          foregroundColor: Colors.black,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                        onPressed: _currentScriptText.isEmpty ? null : _toggleTts,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildAiChip(String label, IconData icon, VoidCallback onTap) {
    return ActionChip(
      avatar: Icon(icon, size: 16, color: AppTheme.cyan),
      label: Text(label),
      labelStyle: const TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.bold,
        color: AppTheme.textPrimary,
      ),
      backgroundColor: AppTheme.surface,
      side: const BorderSide(color: AppTheme.border),
      onPressed: onTap,
    );
  }
}
