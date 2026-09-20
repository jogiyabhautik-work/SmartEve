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
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return Padding(
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 24,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: (isPositive ? AppTheme.warningAmber : AppTheme.liveGreen).withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      isPositive ? Icons.add_alarm_rounded : Icons.fast_forward_rounded,
                      color: isPositive ? AppTheme.warningAmber : AppTheme.liveGreen,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          isPositive ? 'Inject Schedule Shift (Delay)' : 'Inject Time Pull (Catch Up)',
                          style: const TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          isPositive ? 'Add extra time to downstream sessions' : 'Reduce break times to regain schedule',
                          style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              const Text(
                'Downstream upcoming session timings will automatically reflow in Neon DB. Buffer break sessions will absorb shift up to their minimum duration.',
                style: TextStyle(fontSize: 12, color: AppTheme.textSecondary, height: 1.4),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  const Text(
                    'SHIFT MINUTES:',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                  const SizedBox(width: 16),
                  SizedBox(
                    width: 110,
                    child: TextFormField(
                      controller: _customDelayController,
                      keyboardType: TextInputType.number,
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppTheme.primaryBlue),
                      decoration: InputDecoration(
                        isDense: true,
                        filled: true,
                        fillColor: AppTheme.surfaceLight,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: const BorderSide(color: AppTheme.border),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              const Text(
                'REASON FOR SHIFT (OPTIONAL):',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1,
                  color: AppTheme.textSecondary,
                ),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _delayReasonController,
                decoration: InputDecoration(
                  hintText: 'e.g. Keynote audience Q&A extended',
                  hintStyle: const TextStyle(fontSize: 13, color: AppTheme.textMuted),
                  filled: true,
                  fillColor: AppTheme.surfaceLight,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(color: AppTheme.border),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 50,
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
                  label: const Text('APPLY REFLOW & RECALCULATE', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 14)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isPositive ? AppTheme.primaryBlue : AppTheme.liveGreen,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    elevation: 2,
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
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: AppTheme.primaryPurple.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(Icons.auto_awesome_rounded, color: AppTheme.primaryPurple, size: 24),
                      ),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Stage AI Script Studio', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.textPrimary)),
                            Text('Generates instant teleprompter introductions and announcements.', style: TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  Row(
                    children: [
                      ChoiceChip(
                        label: const Text('Speaker Intro'),
                        selected: selectedType == 'intro',
                        selectedColor: AppTheme.primaryPurple.withValues(alpha: 0.2),
                        labelStyle: TextStyle(
                          color: selectedType == 'intro' ? AppTheme.primaryPurple : AppTheme.textSecondary,
                          fontWeight: selectedType == 'intro' ? FontWeight.bold : FontWeight.normal,
                        ),
                        onSelected: (_) => setModalState(() => selectedType = 'intro'),
                      ),
                      const SizedBox(width: 8),
                      ChoiceChip(
                        label: const Text('Delay Notice'),
                        selected: selectedType == 'delay',
                        selectedColor: AppTheme.warningAmber.withValues(alpha: 0.2),
                        labelStyle: TextStyle(
                          color: selectedType == 'delay' ? AppTheme.warningAmber : AppTheme.textSecondary,
                          fontWeight: selectedType == 'delay' ? FontWeight.bold : FontWeight.normal,
                        ),
                        onSelected: (_) => setModalState(() => selectedType = 'delay'),
                      ),
                      const SizedBox(width: 8),
                      ChoiceChip(
                        label: const Text('Session Wrap-up'),
                        selected: selectedType == 'wrapup',
                        selectedColor: AppTheme.primaryBlue.withValues(alpha: 0.2),
                        labelStyle: TextStyle(
                          color: selectedType == 'wrapup' ? AppTheme.primaryBlue : AppTheme.textSecondary,
                          fontWeight: selectedType == 'wrapup' ? FontWeight.bold : FontWeight.normal,
                        ),
                        onSelected: (_) => setModalState(() => selectedType = 'wrapup'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  if (script != null) ...[
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppTheme.surfaceLight,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: AppTheme.primaryPurple.withValues(alpha: 0.3)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(script.provider ?? 'Quad-AI Engine', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppTheme.primaryPurple)),
                              const Icon(Icons.check_circle_rounded, size: 16, color: AppTheme.liveGreen),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(script.text, style: const TextStyle(fontSize: 14, color: AppTheme.textPrimary, height: 1.4)),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],

                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton.icon(
                      onPressed: () async {
                        await provider.generateAiScript(selectedType);
                        setModalState(() {});
                      },
                      icon: const Icon(Icons.auto_awesome_rounded, color: Colors.white),
                      label: const Text('GENERATE AI PROSE', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 14)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryPurple,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        elevation: 2,
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
            top: 24,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppTheme.warningAmber.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(Icons.campaign_rounded, color: AppTheme.warningAmber, size: 24),
                      ),
                      const SizedBox(width: 10),
                      const Text(
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
              const SizedBox(height: 14),
              TextField(
                controller: textController,
                maxLines: 3,
                style: const TextStyle(color: AppTheme.textPrimary, fontSize: 14),
                decoration: InputDecoration(
                  hintText: 'Type announcement (e.g. "Tea break extended by 10 mins")...',
                  hintStyle: const TextStyle(color: AppTheme.textMuted, fontSize: 13),
                  filled: true,
                  fillColor: AppTheme.surfaceLight,
                  contentPadding: const EdgeInsets.all(14),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: AppTheme.border),
                  ),
                ),
              ),
              const SizedBox(height: 20),
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
                icon: const Icon(Icons.send_rounded, color: Colors.white, size: 18),
                label: const Text('BROADCAST TO STAGE & ATTENDEES', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.warningAmber,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  elevation: 2,
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
      backgroundColor: AppTheme.lightBackground,
      appBar: AppBar(
        elevation: 0,
        scrolledUnderElevation: 0,
        backgroundColor: AppTheme.surface,
        toolbarHeight: 68,
        leading: IconButton(
          icon: Container(
            padding: const EdgeInsets.all(7),
            decoration: BoxDecoration(
              color: AppTheme.surfaceLight,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppTheme.border),
            ),
            child: const Icon(Icons.arrow_back_rounded, color: AppTheme.textPrimary, size: 18),
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: Row(
          children: [
            Image.asset(
              'assets/trans_icon.png',
              width: 28,
              height: 28,
              errorBuilder: (_, __, ___) => Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: AppTheme.primaryBlue.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.tune_rounded, color: AppTheme.primaryBlue, size: 18),
              ),
            ),
            const SizedBox(width: 10),
            const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Stage Control Room',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17, color: AppTheme.textPrimary),
                ),
                Text(
                  'SmartEve Live Operations & Reflow',
                  style: TextStyle(fontSize: 11, color: AppTheme.textSecondary, fontWeight: FontWeight.normal),
                ),
              ],
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: Container(
              padding: const EdgeInsets.all(7),
              decoration: BoxDecoration(
                color: AppTheme.warningAmber.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppTheme.warningAmber.withValues(alpha: 0.25)),
              ),
              child: const Icon(Icons.campaign_rounded, color: AppTheme.warningAmber, size: 18),
            ),
            tooltip: 'Broadcast Announcement',
            onPressed: () => _showBroadcastDialog(context),
          ),
          const SizedBox(width: 8),
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
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // 1. HERO EVENT BANNER (Sleek Gradient Highlight)
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF2563EB), Color(0xFF7C5CFC)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF2563EB).withValues(alpha: 0.3),
                        blurRadius: 16,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.white.withValues(alpha: 0.3)),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  isLive ? Icons.sensors_rounded : Icons.pause_circle_filled_rounded,
                                  color: Colors.white,
                                  size: 14,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  isLive ? 'STAGE LIVE' : 'STAGE READY',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 1,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              'Code: ${event?.joinCode ?? "TN26"}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      Text(
                        event?.name ?? 'TechNova Live Stage',
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          const Icon(Icons.location_on_rounded, color: Colors.white70, size: 16),
                          const SizedBox(width: 4),
                          Text(
                            event?.venue ?? 'Main Auditorium Stage A',
                            style: const TextStyle(fontSize: 13, color: Colors.white70),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // 2. QUICK ACTION SHORTCUT BAR
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  decoration: BoxDecoration(
                    color: AppTheme.surface,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppTheme.border),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildHeaderShortcut(
                        context,
                        icon: Icons.cast_connected_rounded,
                        label: 'Projector',
                        color: AppTheme.liveGreen,
                        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const StageDisplayScreen())),
                      ),
                      _buildHeaderShortcut(
                        context,
                        icon: Icons.mic_rounded,
                        label: 'Teleprompter',
                        color: AppTheme.primaryPurple,
                        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AnchorTeleprompterScreen())),
                      ),
                      _buildHeaderShortcut(
                        context,
                        icon: Icons.calendar_today_rounded,
                        label: 'Full Agenda',
                        color: AppTheme.primaryBlue,
                        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AgendaScreen())),
                      ),
                      _buildHeaderShortcut(
                        context,
                        icon: Icons.campaign_rounded,
                        label: 'Broadcast',
                        color: AppTheme.warningAmber,
                        onTap: () => _showBroadcastDialog(context),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // 3. START STAGE BANNER (if stage not started yet)
                if (!isLive) ...[
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton.icon(
                      onPressed: _isProcessing
                          ? null
                          : () async {
                              setState(() => _isProcessing = true);
                              await provider.startEvent();
                              setState(() => _isProcessing = false);
                            },
                      icon: const Icon(Icons.play_arrow_rounded, color: Colors.white, size: 24),
                      label: const Text('START STAGE TIMELINE & LIVE SYNC', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.white)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.liveGreen,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        elevation: 3,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],

                // 4. ABSORBABLE BREAK BUFFER BANNER
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryBlue.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppTheme.primaryBlue.withValues(alpha: 0.2)),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: AppTheme.primaryBlue.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(Icons.shield_rounded, size: 18, color: AppTheme.primaryBlue),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('REFLOW BUFFER PROTECTION', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppTheme.primaryBlue, letterSpacing: 1)),
                            Text(
                              '$absorbableMins mins available across upcoming breaks to absorb delays.',
                              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppTheme.textPrimary),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // 5. MAIN DIGITAL COUNTDOWN CONTROL UNIT
                Container(
                  padding: const EdgeInsets.all(22),
                  decoration: BoxDecoration(
                    color: AppTheme.surface,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: isOvertime ? AppTheme.dangerRose : AppTheme.primaryBlue.withValues(alpha: 0.3),
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
                              fontWeight: FontWeight.bold,
                              color: AppTheme.textSecondary,
                            ),
                          ),
                          if (isOvertime)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: AppTheme.dangerRose.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: AppTheme.dangerRose),
                              ),
                              child: const Text(
                                'OVERTIME',
                                style: TextStyle(
                                  color: AppTheme.dangerRose,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 1,
                                ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      Text(
                        provider.formattedCountdown,
                        style: TextStyle(
                          fontSize: 52,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 2,
                          color: isOvertime ? AppTheme.dangerRose : AppTheme.primaryBlue,
                        ),
                      ),
                      const SizedBox(height: 14),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: LinearProgressIndicator(
                          value: provider.progressFraction,
                          minHeight: 10,
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
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                      if (currentSpeaker != null) ...[
                        const SizedBox(height: 6),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.person_rounded, size: 15, color: AppTheme.primaryBlue),
                            const SizedBox(width: 4),
                            Text(
                              '${currentSpeaker.name} • ${currentSpeaker.organization}',
                              style: const TextStyle(
                                fontSize: 13,
                                color: AppTheme.textSecondary,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // 6. DELAY INJECTION CONTROL HEADER
                const Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'SCHEDULE SHIFT & REFLOW',
                      style: TextStyle(
                        fontSize: 11,
                        letterSpacing: 1.2,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                    Text(
                      'Auto-syncs Neon DB',
                      style: TextStyle(fontSize: 11, color: AppTheme.textMuted),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: _buildShiftButton(
                        context,
                        label: '+15m Shift',
                        color: AppTheme.warningAmber,
                        icon: Icons.add_alarm_rounded,
                        onPressed: () => _showDelayModal(context, 15),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _buildShiftButton(
                        context,
                        label: '+5m Shift',
                        color: AppTheme.primaryBlue,
                        icon: Icons.more_time_rounded,
                        onPressed: () => _showDelayModal(context, 5),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _buildShiftButton(
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

                // 7. SESSION ADVANCEMENT ACTIONS
                Row(
                  children: [
                    Expanded(
                      flex: 2,
                      child: SizedBox(
                        height: 50,
                        child: ElevatedButton.icon(
                          icon: const Icon(Icons.skip_next_rounded, size: 22, color: Colors.white),
                          label: const Text('COMPLETE & ADVANCE', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.white)),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.primaryPurple,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                            elevation: 2,
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
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      flex: 1,
                      child: SizedBox(
                        height: 50,
                        child: OutlinedButton.icon(
                          icon: const Icon(Icons.fast_forward_outlined, size: 18, color: AppTheme.textSecondary),
                          label: const Text('SKIP', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppTheme.textSecondary)),
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: AppTheme.border),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          ),
                          onPressed: () async {
                            await provider.skipCurrentSession();
                          },
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // 8. AI SCRIPT STUDIO BANNER
                OutlinedButton.icon(
                  icon: const Icon(Icons.auto_awesome_rounded, color: AppTheme.primaryPurple, size: 20),
                  label: const Text('OPEN AI SCRIPT STUDIO', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppTheme.primaryPurple)),
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: AppTheme.primaryPurple.withValues(alpha: 0.5)),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  onPressed: () => _showAiScriptModal(context),
                ),
                const SizedBox(height: 24),

                // 9. UP NEXT PREVIEW CARD
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
                  const SizedBox(height: 10),
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
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: nextSession.isBreak
                                ? AppTheme.warningAmber.withValues(alpha: 0.15)
                                : AppTheme.primaryBlue.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            nextSession.isBreak ? Icons.coffee_rounded : Icons.person_rounded,
                            color: nextSession.isBreak ? AppTheme.warningAmber : AppTheme.primaryBlue,
                            size: 22,
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
                  const SizedBox(height: 20),
                ],
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildHeaderShortcut(
    BuildContext context, {
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 22),
            ),
            const SizedBox(height: 6),
            Text(
              label,
              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildShiftButton(
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
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: color.withValues(alpha: 0.3)),
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
