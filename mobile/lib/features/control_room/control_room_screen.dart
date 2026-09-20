import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_theme.dart';
import '../../providers/event_provider.dart';
import '../anchor/anchor_teleprompter_screen.dart';
import '../stage_display/stage_display_screen.dart';
import '../agenda/agenda_screen.dart';

class ControlRoomScreen extends StatefulWidget {
  const ControlRoomScreen({super.key});

  @override
  State<ControlRoomScreen> createState() => _ControlRoomScreenState();
}

class _ControlRoomScreenState extends State<ControlRoomScreen> {
  final TextEditingController _delayReasonController = TextEditingController();
  final TextEditingController _customDelayController = TextEditingController();
  bool _isProcessing = false;

  @override
  void dispose() {
    _delayReasonController.dispose();
    _customDelayController.dispose();
    super.dispose();
  }

  void _showDelayModal(BuildContext context, int initialMins) {
    _customDelayController.text = initialMins.abs().toString();
    bool isPositive = initialMins >= 0;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppTheme.surface,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) {
        return Padding(
          padding: EdgeInsets.only(left: 20, right: 20, top: 24, bottom: MediaQuery.of(ctx).viewInsets.bottom + 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    isPositive ? Icons.add_alarm_rounded : Icons.fast_forward_rounded,
                    color: isPositive ? AppTheme.warningAmber : AppTheme.liveGreen,
                  ),
                  const SizedBox(width: 10),
                  Text(
                    isPositive ? 'Inject Schedule Shift (Delay)' : 'Inject Time Pull (Catch Up)',
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              const Text(
                'Downstream upcoming session timings will automatically reflow in Neon DB. Buffer break sessions will absorb shift up to their minimum duration.',
                style: TextStyle(fontSize: 12, color: AppTheme.textSecondary, height: 1.3),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  const Text('SHIFT MINUTES:', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1, color: AppTheme.textSecondary)),
                  const SizedBox(width: 12),
                  SizedBox(
                    width: 100,
                    child: TextFormField(
                      controller: _customDelayController,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        isDense: true,
                        filled: true,
                        fillColor: AppTheme.surfaceLight,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              const Text('REASON FOR SHIFT (OPTIONAL):', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1, color: AppTheme.textSecondary)),
              const SizedBox(height: 8),
              TextFormField(
                controller: _delayReasonController,
                decoration: InputDecoration(
                  hintText: 'e.g. Keynote audience Q&A extended',
                  filled: true,
                  fillColor: AppTheme.surfaceLight,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton.icon(
                  onPressed: () async {
                    final mins = int.tryParse(_customDelayController.text.trim()) ?? 5;
                    final actualMins = isPositive ? mins : -mins;
                    Navigator.pop(ctx);
                    final messenger = ScaffoldMessenger.of(context);
                    setState(() => _isProcessing = true);
                    final provider = context.read<EventProvider>();
                    final ok = await provider.injectDelay(actualMins, reason: _delayReasonController.text.trim());
                    if (!mounted) return;
                    setState(() => _isProcessing = false);

                    if (ok) {
                      messenger.showSnackBar(
                        SnackBar(
                          content: Text(isPositive
                              ? '⏰ Inject +${mins}m delay! Schedule reflowed in Neon DB.'
                              : '🚀 Applied -${mins}m catch up across agenda!'),
                          backgroundColor: isPositive ? AppTheme.warningAmber : AppTheme.liveGreen,
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                    }
                  },
                  icon: const Icon(Icons.bolt_rounded, color: Colors.white),
                  label: const Text('APPLY REFLOW & RECALCULATE', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isPositive ? AppTheme.primaryBlue : AppTheme.liveGreen,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showAiScriptModal(BuildContext context) {
    String selectedType = 'intro';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppTheme.surface,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            final provider = context.watch<EventProvider>();
            final script = provider.activeScript;

            return Padding(
              padding: EdgeInsets.only(left: 20, right: 20, top: 24, bottom: MediaQuery.of(ctx).viewInsets.bottom + 24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.psychology_rounded, color: AppTheme.primaryPurple, size: 24),
                      SizedBox(width: 10),
                      Text('Quad-AI Stage Script Studio', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.textPrimary)),
                    ],
                  ),
                  const SizedBox(height: 6),
                  const Text('Generates instant teleprompter introductions and announcements with quad-provider fallback.', style: TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
                  const SizedBox(height: 16),

                  Row(
                    children: [
                      ChoiceChip(
                        label: const Text('Speaker Intro'),
                        selected: selectedType == 'intro',
                        onSelected: (_) => setModalState(() => selectedType = 'intro'),
                      ),
                      const SizedBox(width: 8),
                      ChoiceChip(
                        label: const Text('Delay Notice'),
                        selected: selectedType == 'delay',
                        onSelected: (_) => setModalState(() => selectedType = 'delay'),
                      ),
                      const SizedBox(width: 8),
                      ChoiceChip(
                        label: const Text('Session Wrap-up'),
                        selected: selectedType == 'wrapup',
                        onSelected: (_) => setModalState(() => selectedType = 'wrapup'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  if (script != null) ...[
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: AppTheme.surfaceLight,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppTheme.primaryPurple.withValues(alpha: 0.3)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(script.provider ?? 'Quad-AI Engine', style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppTheme.primaryPurple)),
                              const Icon(Icons.check_circle_rounded, size: 14, color: AppTheme.liveGreen),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(script.text, style: const TextStyle(fontSize: 13, color: AppTheme.textPrimary, height: 1.4)),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],

                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton.icon(
                      onPressed: () async {
                        await provider.generateAiScript(selectedType);
                        setModalState(() {});
                      },
                      icon: const Icon(Icons.auto_awesome_rounded, color: Colors.white),
                      label: const Text('GENERATE AI PROSE', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryPurple,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _showAnnouncementDialog(BuildContext context) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.surface,
        title: const Text('Broadcast Stage Announcement', style: TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.bold)),
        content: TextField(
          controller: controller,
          maxLines: 3,
          style: const TextStyle(color: AppTheme.textPrimary),
          decoration: const InputDecoration(
            hintText: 'e.g. Please take your seats, next keynote starts in 2 minutes.',
            hintStyle: TextStyle(color: AppTheme.textMuted),
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('CANCEL', style: TextStyle(color: AppTheme.textMuted)),
          ),
          ElevatedButton(
            onPressed: () {
              if (controller.text.trim().isNotEmpty) {
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('📣 Stage announcement broadcasted to all stage displays!'), backgroundColor: AppTheme.primaryBlue),
                );
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primaryBlue),
            child: const Text('BROADCAST', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  void _showBroadcastDialog(BuildContext context) {
    final textController = TextEditingController();
    final messenger = ScaffoldMessenger.of(context);
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppTheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return Padding(
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 20,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.campaign_rounded, color: AppTheme.warningAmber, size: 24),
                      SizedBox(width: 8),
                      Text(
                        'Broadcast Announcement',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
                      ),
                    ],
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded, color: AppTheme.textMuted),
                    onPressed: () => Navigator.pop(ctx),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              TextField(
                controller: textController,
                maxLines: 3,
                style: const TextStyle(color: AppTheme.textPrimary),
                decoration: InputDecoration(
                  hintText: 'Type announcement (e.g. "Tea break extended by 10 mins")...',
                  hintStyle: const TextStyle(color: AppTheme.textMuted),
                  filled: true,
                  fillColor: AppTheme.background,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: AppTheme.border),
                  ),
                ),
              ),
              const SizedBox(height: 18),
              ElevatedButton.icon(
                onPressed: () async {
                  final msg = textController.text.trim();
                  if (msg.isEmpty) return;
                  Navigator.pop(ctx);
                  final ok = await context.read<EventProvider>().broadcastAnnouncement(msg);
                  if (ok) {
                    messenger.showSnackBar(
                      SnackBar(
                        content: Text('📣 Broadcasted stage announcement: "$msg"'),
                        backgroundColor: AppTheme.warningAmber,
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  }
                },
                icon: const Icon(Icons.send_rounded, color: Colors.black),
                label: const Text('BROADCAST TO STAGE & ATTENDEES', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.warningAmber,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text('Stage Pilot Control Room', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        actions: [
          IconButton(
            icon: const Icon(Icons.campaign_rounded, color: AppTheme.warningAmber),
            tooltip: 'Broadcast Stage Announcement',
            onPressed: () => _showBroadcastDialog(context),
          ),
          IconButton(
            icon: const Icon(Icons.format_list_bulleted_rounded, color: AppTheme.primaryBlue),
            tooltip: 'View Full Agenda',
            onPressed: () {
              Navigator.of(context).push(MaterialPageRoute(builder: (_) => const AgendaScreen()));
            },
          ),
          IconButton(
            icon: const Icon(Icons.cast_connected_rounded, color: AppTheme.liveGreen),
            tooltip: 'Stage Display View',
            onPressed: () {
              Navigator.of(context).push(MaterialPageRoute(builder: (_) => const StageDisplayScreen()));
            },
          ),
          IconButton(
            icon: const Icon(Icons.mic_rounded, color: AppTheme.primaryPurple),
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
          final isLive = event?.liveState.status == 'live';

          // Calculate total absorbable buffer mins across agenda
          final absorbableMins = provider.agenda
              .where((it) => it.absorbable && (it.isUpcoming || it.isLive))
              .fold<int>(0, (sum, it) => sum + (it.duration - (it.minDuration ?? 5)).clamp(0, 99));

          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Event Header & Status Banner
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppTheme.surface,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppTheme.border),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              event?.name ?? 'No Event Selected',
                              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '${event?.venue ?? "Main Stage"} • Join Code: ${event?.joinCode ?? "TN26"}',
                              style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: (isLive ? AppTheme.liveGreen : AppTheme.warningAmber).withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: isLive ? AppTheme.liveGreen : AppTheme.warningAmber),
                        ),
                        child: Text(
                          isLive ? 'STAGE LIVE' : 'STAGE READY',
                          style: TextStyle(
                            color: isLive ? AppTheme.liveGreen : AppTheme.warningAmber,
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Start Event Banner (if not live yet)
                if (!isLive) ...[
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton.icon(
                      onPressed: _isProcessing ? null : () async {
                        setState(() => _isProcessing = true);
                        await provider.startEvent();
                        setState(() => _isProcessing = false);
                      },
                      icon: const Icon(Icons.play_arrow_rounded, color: Colors.white),
                      label: const Text('START STAGE EVENT & TIMELINE', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Colors.white)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.liveGreen,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],

                // Absorbable Buffer Status Banner
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryBlue.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppTheme.primaryBlue.withValues(alpha: 0.25)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.shield_rounded, size: 18, color: AppTheme.primaryBlue),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Absorbable Break Buffer: $absorbableMins mins available across upcoming breaks.',
                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppTheme.textPrimary),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Main Session Countdown Card
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: AppTheme.surface,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: isOvertime ? AppTheme.dangerRose : AppTheme.primaryBlue.withValues(alpha: 0.4),
                      width: 1.5,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: (isOvertime ? AppTheme.dangerRose : AppTheme.primaryBlue).withValues(alpha: 0.08),
                        blurRadius: 16,
                        offset: const Offset(0, 4),
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
                              fontSize: 11,
                              letterSpacing: 1.5,
                              fontWeight: FontWeight.w700,
                              color: AppTheme.textSecondary,
                            ),
                          ),
                          if (isOvertime)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: AppTheme.dangerRose.withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: const Text(
                                'OVERTIME',
                                style: TextStyle(
                                  color: AppTheme.dangerRose,
                                  fontSize: 10,
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
                          fontSize: 54,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 2,
                          color: isOvertime ? AppTheme.dangerRose : AppTheme.primaryBlue,
                        ),
                      ),
                      const SizedBox(height: 14),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(6),
                        child: LinearProgressIndicator(
                          value: provider.progressFraction,
                          minHeight: 8,
                          backgroundColor: AppTheme.surfaceLight,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            isOvertime ? AppTheme.dangerRose : AppTheme.primaryBlue,
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        currentSession?.title ?? 'No active session running',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                      if (currentSpeaker != null) ...[
                        const SizedBox(height: 4),
                        Text(
                          '${currentSpeaker.name} • ${currentSpeaker.organization}',
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 13,
                            color: AppTheme.textSecondary,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // Delay Injection Controls Header
                const Text(
                  'REFLOW ENGINE & DELAY INJECTION',
                  style: TextStyle(
                    fontSize: 11,
                    letterSpacing: 1.2,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textSecondary,
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: _buildActionButton(
                        context,
                        label: '+15m Shift',
                        color: AppTheme.warningAmber,
                        icon: Icons.add_alarm_rounded,
                        onPressed: () => _showDelayModal(context, 15),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _buildActionButton(
                        context,
                        label: '+5m Shift',
                        color: AppTheme.primaryBlue,
                        icon: Icons.more_time_rounded,
                        onPressed: () => _showDelayModal(context, 5),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _buildActionButton(
                        context,
                        label: '-5m Pull',
                        color: AppTheme.liveGreen,
                        icon: Icons.fast_forward_rounded,
                        onPressed: () => _showDelayModal(context, -5),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // Session Advancement Controls
                Row(
                  children: [
                    Expanded(
                      flex: 2,
                      child: ElevatedButton.icon(
                        icon: const Icon(Icons.skip_next_rounded, size: 20, color: Colors.white),
                        label: const Text('COMPLETE & ADVANCE', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.white)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primaryPurple,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        onPressed: _isProcessing
                            ? null
                            : () async {
                                setState(() => _isProcessing = true);
                                final ok = await provider.completeCurrentSession();
                                setState(() => _isProcessing = false);
                                if (ok && context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text('✅ Session completed! Advanced to next live session.'), backgroundColor: AppTheme.liveGreen),
                                  );
                                }
                              },
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      flex: 1,
                      child: OutlinedButton.icon(
                        icon: const Icon(Icons.fast_forward_outlined, size: 18, color: AppTheme.textSecondary),
                        label: const Text('SKIP', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: AppTheme.textSecondary)),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        onPressed: () async {
                          await provider.skipCurrentSession();
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // AI Script & Emergency Buttons
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        icon: const Icon(Icons.auto_awesome_rounded, color: AppTheme.primaryPurple, size: 18),
                        label: const Text('AI Script Studio', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: AppTheme.primaryPurple)),
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: AppTheme.primaryPurple),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        onPressed: () => _showAiScriptModal(context),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: OutlinedButton.icon(
                        icon: const Icon(Icons.campaign_rounded, color: AppTheme.primaryBlue, size: 18),
                        label: const Text('Broadcast Alert', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: AppTheme.primaryBlue)),
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: AppTheme.primaryBlue),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        onPressed: () => _showAnnouncementDialog(context),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // Up Next Preview Card
                if (nextSession != null) ...[
                  const Text(
                    'UP NEXT ON STAGE',
                    style: TextStyle(
                      fontSize: 11,
                      letterSpacing: 1.2,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppTheme.surface,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppTheme.border),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: nextSession.isBreak
                                ? AppTheme.warningAmber.withValues(alpha: 0.15)
                                : AppTheme.primaryBlue.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(
                            nextSession.isBreak ? Icons.coffee_rounded : Icons.person_rounded,
                            color: nextSession.isBreak ? AppTheme.warningAmber : AppTheme.primaryBlue,
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
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: color.withValues(alpha: 0.4)),
          ),
          child: Column(
            children: [
              Icon(icon, color: color, size: 20),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  fontSize: 11,
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
