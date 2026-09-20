import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/smart_eve_bottom_nav.dart';
import '../../core/widgets/smarteve_ai_fab.dart';
import '../../models/event_model.dart';
import '../../providers/event_provider.dart';
import '../anchor/anchor_teleprompter_screen.dart';
import 'widgets/find_anchors_modal.dart';

class EventDetailsScreen extends StatefulWidget {
  final EventModel? event;

  const EventDetailsScreen({
    super.key,
    this.event,
  });

  @override
  State<EventDetailsScreen> createState() => _EventDetailsScreenState();
}

class _EventDetailsScreenState extends State<EventDetailsScreen> {
  // Wireframe specifies Scripts (tab index 2) selected by default with ✓ indicator
  int _currentTabIndex = 2;

  @override
  Widget build(BuildContext context) {
    final eventProvider = context.watch<EventProvider>();
    final currentEvent = widget.event ?? eventProvider.event ?? _buildFallbackEvent();

    return Scaffold(
      backgroundColor: AppTheme.lightBackground,
      appBar: AppBar(
        backgroundColor: AppTheme.surface,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        title: const Text(
          'EVENT DETAILS',
          style: TextStyle(
            color: AppTheme.textPrimary,
            fontSize: 16,
            fontWeight: FontWeight.w800,
            letterSpacing: 1.5,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.share_outlined, color: AppTheme.textPrimary, size: 20),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Join Code: ${currentEvent.joinCode} copied to clipboard!'),
                  backgroundColor: AppTheme.primaryBlue,
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
          ),
        ],
      ),
      extendBody: true,
      body: Stack(
        children: [
          // Main Scrollable Content for active tab
          Positioned.fill(
            child: SingleChildScrollView(
              padding: const EdgeInsets.only(
                left: 16,
                right: 16,
                top: 16,
                bottom: 110, // Space for floating bottom dock and SmartEve FAB
              ),
              child: _buildTabContent(currentEvent, eventProvider),
            ),
          ),

          // Bottom Right Floating SmartEve AI Assistant Button (💬 SmartEve)
          const Positioned(
            right: 20,
            bottom: 96, // Positioned safely above floating bottom nav
            child: SmartEveAiFab(),
          ),
        ],
      ),
      bottomNavigationBar: SmartEveBottomNav(
        selectedIndex: _currentTabIndex,
        onItemSelected: (idx) {
          setState(() => _currentTabIndex = idx);
        },
      ),
    );
  }

  Widget _buildTabContent(EventModel event, EventProvider eventProvider) {
    switch (_currentTabIndex) {
      case 0:
        return _buildHomeOverviewTab(event);
      case 1:
        return _buildEventsTab(event, eventProvider);
      case 2:
        return _buildScriptsTab(event, eventProvider); // Default active per wireframe!
      case 3:
        return _buildNotifTab(event);
      case 4:
        return _buildProfileTab();
      default:
        return _buildScriptsTab(event, eventProvider);
    }
  }

  // --- TAB 2: SCRIPTS (DEFAULT ACTIVE) ---
  Widget _buildScriptsTab(EventModel event, EventProvider eventProvider) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Hero Event Header Card
        _buildEventSummaryCard(event),
        const SizedBox(height: 20),

        // Section Title
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'STAGE SCRIPTS & PROMPTER',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.2,
                color: AppTheme.textSecondary,
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: AppTheme.primaryBlue.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Text(
                'AI CO-PILOT ACTIVE',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.primaryBlue,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),

        // Teleprompter Launcher Banner
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [AppTheme.deepNavy, AppTheme.darkBlue],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(AppTheme.radiusCard),
            boxShadow: [
              BoxShadow(
                color: AppTheme.deepNavy.withValues(alpha: 0.15),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryBlue.withValues(alpha: 0.25),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.mic_external_on_rounded, color: AppTheme.accentBlue, size: 20),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Live Stage Teleprompter',
                          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                        Text(
                          'Auto-scrolling, high-contrast & speech synthesis',
                          style: TextStyle(color: AppTheme.textMuted, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const AnchorTeleprompterScreen()),
                    );
                  },
                  icon: const Icon(Icons.play_arrow_rounded, size: 18),
                  label: const Text('OPEN TELEPROMPTER HUD'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryBlue,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppTheme.radiusButton)),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),

        // Script Items List
        _buildScriptCard(
          title: 'Opening Ceremony & VIP Welcome',
          speaker: 'Organizer Host',
          duration: '5 Mins',
          status: 'Ready',
          scriptPreview:
              'Ladies and gentlemen, esteemed guests, and innovators—welcome to ${event.name}! Today we bring together the brightest minds to push boundaries...',
        ),
        const SizedBox(height: 12),
        _buildScriptCard(
          title: 'Keynote Speaker Introduction: Dr. Aris Thorne',
          speaker: 'Dr. Aris Thorne (AI Research Lead)',
          duration: '2 Mins',
          status: 'AI Generated',
          scriptPreview:
              'Please join me in giving a warm welcome to Dr. Aris Thorne, pioneering architect in distributed intelligence. Dr. Thorne has led breakthroughs across...',
        ),
        const SizedBox(height: 12),
        _buildScriptCard(
          title: 'Emergency Delay & Buffer Announcement',
          speaker: 'Stage Anchor',
          duration: '1 Min',
          status: 'Buffer Template',
          scriptPreview:
              'Attention guests, we are currently refreshing the stage AV setup. Please enjoy networking with our sponsors at the main concourse...',
        ),
      ],
    );
  }

  // --- TAB 0: HOME ---
  Widget _buildHomeOverviewTab(EventModel event) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildEventSummaryCard(event),
        const SizedBox(height: 20),
        const Text(
          'STAGE STATUS & METRICS',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.2,
            color: AppTheme.textSecondary,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildMetricCard(
                title: 'Schedule Drift',
                value: '+0 min',
                subtitle: 'On Time',
                icon: Icons.timer_outlined,
                color: AppTheme.success,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildMetricCard(
                title: 'Total Sessions',
                value: '8',
                subtitle: '3 Completed',
                icon: Icons.list_alt_rounded,
                color: AppTheme.primaryBlue,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        _buildMetricCard(
          title: 'Join Code',
          value: event.joinCode,
          subtitle: 'Share with anchors and backstage team',
          icon: Icons.qr_code_2_rounded,
          color: AppTheme.secondaryPurple,
        ),
        const SizedBox(height: 12),
        InkWell(
          onTap: () => FindAnchorsModal.show(context, event),
          borderRadius: BorderRadius.circular(16),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppTheme.liveGreen.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppTheme.liveGreen.withValues(alpha: 0.4)),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppTheme.liveGreen.withValues(alpha: 0.2),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.person_search_rounded, color: AppTheme.liveGreen, size: 24),
                ),
                const SizedBox(width: 14),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Find & Invite Stage Anchors', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppTheme.textPrimary)),
                      SizedBox(height: 2),
                      Text('Explore registered hosts in Neon DB & send invitations', style: TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right_rounded, color: AppTheme.liveGreen),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // --- TAB 1: EVENTS / SCHEDULE ---
  Widget _buildEventsTab(EventModel event, EventProvider eventProvider) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildEventSummaryCard(event),
        const SizedBox(height: 20),
        const Text(
          'SCHEDULE RUN OF SHOW',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.2,
            color: AppTheme.textSecondary,
          ),
        ),
        const SizedBox(height: 12),
        _buildSessionTimelineItem(
          time: '09:00 AM - 09:30 AM',
          title: 'Registration & Welcome Coffee',
          venue: event.venue,
          isCompleted: true,
        ),
        _buildSessionTimelineItem(
          time: '09:30 AM - 10:30 AM',
          title: 'Opening Keynote: Next-Gen Stage Tech',
          venue: 'Main Auditorium',
          isLive: true,
        ),
        _buildSessionTimelineItem(
          time: '10:30 AM - 11:15 AM',
          title: 'Panel: Resilient Live Production',
          venue: 'Hall B',
        ),
        _buildSessionTimelineItem(
          time: '11:15 AM - 12:00 PM',
          title: 'Speaker Showcase & Live Q&A',
          venue: 'Main Stage',
        ),
      ],
    );
  }

  // --- TAB 3: NOTIFICATIONS ---
  Widget _buildNotifTab(EventModel event) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'STAGE NOTIFICATIONS & ALERTS',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.2,
            color: AppTheme.textSecondary,
          ),
        ),
        const SizedBox(height: 14),
        _buildNotificationCard(
          icon: Icons.notifications_active_rounded,
          title: 'VIP Speaker Arrived',
          time: '2 mins ago',
          message: 'Dr. Aris Thorne has checked in at the Green Room.',
          badgeColor: AppTheme.success,
        ),
        const SizedBox(height: 10),
        _buildNotificationCard(
          icon: Icons.schedule_rounded,
          title: 'Reflow Engine Buffer Added',
          time: '14 mins ago',
          message: '5-minute transition buffer automatically applied before Keynote.',
          badgeColor: AppTheme.warning,
        ),
        const SizedBox(height: 10),
        _buildNotificationCard(
          icon: Icons.campaign_rounded,
          title: 'Stage Pilot Connected',
          time: '35 mins ago',
          message: 'Anchor Teleprompter and Stage Display synced on channel #${event.joinCode}.',
          badgeColor: AppTheme.primaryBlue,
        ),
      ],
    );
  }

  // --- TAB 4: PROFILE ---
  Widget _buildProfileTab() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: AppTheme.surface,
            borderRadius: BorderRadius.circular(AppTheme.radiusCard),
            border: Border.all(color: AppTheme.border),
          ),
          child: Row(
            children: [
              CircleAvatar(
                radius: 30,
                backgroundColor: AppTheme.primaryBlue.withValues(alpha: 0.15),
                child: const Icon(Icons.person_rounded, size: 36, color: AppTheme.primaryBlue),
              ),
              const SizedBox(width: 16),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'SmartEve Stage Lead',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'organizer@smarteve.io',
                      style: TextStyle(fontSize: 13, color: AppTheme.textSecondary),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        _buildProfileSettingRow(Icons.color_lens_outlined, 'UI Theme & Brand Palette', 'Primary #4E6BEB'),
        _buildProfileSettingRow(Icons.record_voice_over_outlined, 'Speech Synthesis (TTS)', 'Enabled'),
        _buildProfileSettingRow(Icons.security_rounded, 'Neon PostgreSQL Cloud Connection', 'Active (TLS)'),
      ],
    );
  }

  // --- REUSABLE SUB-WIDGETS ---
  Widget _buildEventSummaryCard(EventModel event) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(AppTheme.radiusCard),
        border: Border.all(color: AppTheme.border),
        boxShadow: [
          BoxShadow(
            color: AppTheme.deepNavy.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 2),
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
                  color: AppTheme.primaryBlue.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  event.type.toUpperCase(),
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.primaryBlue,
                    letterSpacing: 0.8,
                  ),
                ),
              ),
              Row(
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                      color: AppTheme.success,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 6),
                  const Text(
                    'LIVE STAGE',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.success,
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            event.name,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              const Icon(Icons.calendar_today_rounded, size: 14, color: AppTheme.textSecondary),
              const SizedBox(width: 6),
              Text(
                event.date.isNotEmpty ? event.date : 'Today, 2026',
                style: const TextStyle(fontSize: 13, color: AppTheme.textSecondary),
              ),
              const SizedBox(width: 16),
              const Icon(Icons.location_on_rounded, size: 14, color: AppTheme.textSecondary),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  event.venue.isNotEmpty ? event.venue : 'Grand Auditorium',
                  style: const TextStyle(fontSize: 13, color: AppTheme.textSecondary),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildScriptCard({
    required String title,
    required String speaker,
    required String duration,
    required String status,
    required String scriptPreview,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(AppTheme.radiusCard),
        border: Border.all(color: AppTheme.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textPrimary,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppTheme.secondaryPurple.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  status,
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.secondaryPurple,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              const Icon(Icons.person_outline_rounded, size: 14, color: AppTheme.textSecondary),
              const SizedBox(width: 4),
              Text(speaker, style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
              const SizedBox(width: 12),
              const Icon(Icons.schedule_rounded, size: 14, color: AppTheme.textSecondary),
              const SizedBox(width: 4),
              Text(duration, style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppTheme.surfaceLight,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              scriptPreview,
              style: const TextStyle(
                fontSize: 13,
                height: 1.4,
                color: AppTheme.textPrimary,
                fontStyle: FontStyle.italic,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetricCard({
    required String title,
    required String value,
    required String subtitle,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(AppTheme.radiusCard),
        border: Border.all(color: AppTheme.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary, fontWeight: FontWeight.w600),
              ),
              Icon(icon, size: 20, color: color),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: color),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: const TextStyle(fontSize: 11, color: AppTheme.textMuted),
          ),
        ],
      ),
    );
  }

  Widget _buildSessionTimelineItem({
    required String time,
    required String title,
    required String venue,
    bool isCompleted = false,
    bool isLive = false,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isLive ? AppTheme.primaryBlue.withValues(alpha: 0.05) : AppTheme.surface,
        borderRadius: BorderRadius.circular(AppTheme.radiusCard),
        border: Border.all(
          color: isLive ? AppTheme.primaryBlue : AppTheme.border,
          width: isLive ? 1.5 : 1,
        ),
      ),
      child: Row(
        children: [
          Icon(
            isCompleted
                ? Icons.check_circle_rounded
                : isLive
                    ? Icons.play_circle_filled_rounded
                    : Icons.radio_button_unchecked_rounded,
            color: isCompleted
                ? AppTheme.success
                : isLive
                    ? AppTheme.primaryBlue
                    : AppTheme.textMuted,
            size: 22,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: isCompleted ? AppTheme.textSecondary : AppTheme.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '$time • $venue',
                  style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationCard({
    required IconData icon,
    required String title,
    required String time,
    required String message,
    required Color badgeColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(AppTheme.radiusCard),
        border: Border.all(color: AppTheme.border),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: badgeColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 18, color: badgeColor),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppTheme.textPrimary)),
                    Text(time, style: const TextStyle(fontSize: 11, color: AppTheme.textMuted)),
                  ],
                ),
                const SizedBox(height: 4),
                Text(message, style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileSettingRow(IconData icon, String title, String value) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(AppTheme.radiusCard),
        border: Border.all(color: AppTheme.border),
      ),
      child: Row(
        children: [
          Icon(icon, size: 20, color: AppTheme.primaryBlue),
          const SizedBox(width: 12),
          Expanded(
            child: Text(title, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppTheme.textPrimary)),
          ),
          Text(value, style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
        ],
      ),
    );
  }

  EventModel _buildFallbackEvent() {
    final now = DateTime.now();
    return EventModel(
      id: 'event-${now.millisecondsSinceEpoch}',
      name: 'SmartEve Stage Event',
      type: 'Conference',
      date: '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}',
      venue: 'Main Auditorium',
      tone: 'Inspiring & Engaging',
      ownerId: 'organizer',
      joinCode: 'EVT1',
      liveState: LiveStateModel(status: 'draft', totalDelayMin: 0),
      createdAt: now.millisecondsSinceEpoch,
    );
  }
}
