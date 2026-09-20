import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/services/auth_service.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/smart_eve_bottom_nav.dart';
import '../../core/widgets/smarteve_ai_fab.dart';
import '../../providers/anchor_provider.dart';
import '../../providers/notification_provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../models/anchor_dashboard_models.dart';
import '../events/event_details_screen.dart';
import '../anchor/anchor_teleprompter_screen.dart';
import '../scripts/scripts_library_screen.dart';
import '../live_dashboard/live_dashboard_screen.dart';
import 'widgets/anchor_invitation_card.dart';
import 'widgets/upcoming_event_card.dart';
import 'widgets/completed_events_section.dart';
import '../profile/profile_settings_screen.dart';
import '../notifications/notification_center_screen.dart';

class AnchorDashboardScreen extends StatefulWidget {
  final String? anchorName;

  const AnchorDashboardScreen({
    super.key,
    this.anchorName,
  });

  @override
  State<AnchorDashboardScreen> createState() => _AnchorDashboardScreenState();
}

class _AnchorDashboardScreenState extends State<AnchorDashboardScreen> {
  // Bottom dock index: 0 = Home (active per prompt)
  int _currentTabIndex = 0;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AnchorProvider>().fetchDashboardFromBackend();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final anchorProvider = context.watch<AnchorProvider>();
    String resolvedName = widget.anchorName ?? 'Jordan Hayes';
    try {
      final user = AuthService().currentAppUser;
      if (user != null && user.fullName.isNotEmpty) {
        resolvedName = user.fullName;
      }
    } catch (_) {
      // Fallback for test / headless environment without Firebase
    }

    return Scaffold(
      backgroundColor: AppTheme.lightBackground,
      appBar: _buildTopHeader(resolvedName, anchorProvider),
      extendBody: true,
      body: Stack(
        children: [
          // Main Body Content
          Positioned.fill(
            child: _currentTabIndex == 0
                ? _buildDashboardHomeView(anchorProvider)
                : _buildOtherTabView(_currentTabIndex),
          ),

          // Floating SmartEve AI Co-Pilot Button (Bottom Right)
          const Positioned(
            right: 20,
            bottom: 96, // Elevated above bottom navigation dock
            child: SmartEveAiFab(),
          ),
        ],
      ),
      bottomNavigationBar: Consumer<NotificationProvider>(
        builder: (context, notif, __) => SmartEveBottomNav(
          selectedIndex: _currentTabIndex,
          badgeCounts: {3: notif.unreadCount},
          onItemSelected: (idx) {
          if (idx == 2) {
            // Direct navigation to Scripts Library
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const ScriptsLibraryScreen()),
            );
          } else if (idx == 1) {
            // Direct shortcut to Event Details
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const EventDetailsScreen()),
            );
          } else {
            setState(() => _currentTabIndex = idx);
          }
        },
        ),
      ),
    );
  }

  // --- TOP SECTION HEADER ---
  PreferredSizeWidget _buildTopHeader(String anchorName, AnchorProvider provider) {
    return AppBar(
      backgroundColor: AppTheme.surface,
      elevation: 0,
      scrolledUnderElevation: 0,
      automaticallyImplyLeading: false,
      toolbarHeight: 70,
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'SMARTEVE ANCHOR CO-PILOT',
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.2,
              color: AppTheme.primaryBlue,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            'Welcome back, $anchorName',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: AppTheme.textPrimary,
            ),
          ),
        ],
      ),
      actions: [
        // Notification bell with app-wide unread badge
        Consumer<NotificationProvider>(
          builder: (context, notif, __) => Padding(
            padding: const EdgeInsets.only(right: 4),
            child: Stack(
              alignment: Alignment.center,
              children: [
                IconButton(
                  icon: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppTheme.surfaceLight,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: AppTheme.border),
                    ),
                    child: const Icon(
                      Icons.notifications_none_rounded,
                      color: AppTheme.textSecondary,
                      size: 20,
                    ),
                  ),
                  onPressed: () =>
                      setState(() => _currentTabIndex = 3),
                ),
                if (notif.unreadCount > 0)
                  Positioned(
                    top: 8,
                    right: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 5, vertical: 1),
                      decoration: BoxDecoration(
                        color: AppTheme.error,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                            color: AppTheme.surface, width: 1.5),
                      ),
                      constraints: const BoxConstraints(
                          minWidth: 16, minHeight: 16),
                      child: Text(
                        '${notif.unreadCount}',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
        // SmartEve AI assist icon with notification badge
        Padding(
          padding: const EdgeInsets.only(right: 8),
          child: Stack(
            alignment: Alignment.center,
            children: [
              IconButton(
                icon: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppTheme.surfaceLight,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppTheme.border),
                  ),
                  child: const Icon(
                    Icons.auto_awesome_rounded,
                    color: AppTheme.primaryBlue,
                    size: 20,
                  ),
                ),
                onPressed: () => _showAiQuickAssistSheet(context),
              ),
              if (provider.unreadAiAlertCount > 0)
                Positioned(
                  top: 8,
                  right: 8,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(
                      color: AppTheme.error,
                      shape: BoxShape.circle,
                    ),
                    child: Text(
                      '${provider.unreadAiAlertCount}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 9,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),

        // Logout Action Button with Confirmation
        Padding(
          padding: const EdgeInsets.only(right: 16),
          child: IconButton(
            tooltip: 'Log Out',
            icon: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppTheme.surfaceLight,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppTheme.border),
              ),
              child: const Icon(
                Icons.logout_rounded,
                color: AppTheme.textSecondary,
                size: 20,
              ),
            ),
            onPressed: () => AuthService().confirmSignOut(context),
          ),
        ),
      ],
    );
  }

  // --- DASHBOARD HOME VIEW (RESPONSIVE) ---
  Widget _buildDashboardHomeView(AnchorProvider provider) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final double width = constraints.maxWidth;
        final bool isTablet = width >= 600 && width < 1024;
        final bool isDesktop = width >= 1024;

        return RefreshIndicator(
          onRefresh: () => provider.fetchDashboardFromBackend(),
          color: AppTheme.primaryBlue,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.only(
              left: 16,
              right: 16,
              top: 14,
              bottom: 110, // Margin for floating nav and FAB
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Searchable event list input
                _buildSearchBar(provider),
                const SizedBox(height: 14),

                // Live Stage Command Dashboard Banner
                _buildLiveStageCommandBanner(context, provider),
                const SizedBox(height: 12),

                // Quick Stage Scripts Library Banner
                _buildScriptsLibraryPromoBanner(context),
                const SizedBox(height: 20),

                // SECTION 1: STICKY EVENT INVITATIONS (if count > 0)
                if (provider.filteredInvitations.isNotEmpty) ...[
                  _buildStickyInvitationsSection(provider),
                  const SizedBox(height: 24),
                ],

                // Responsive Content Distribution
                if (isDesktop)
                  _buildDesktopLayout(provider)
                else if (isTablet)
                  _buildTabletLayout(provider)
                else
                  _buildMobileLayout(provider),
              ],
            ),
          ),
        );
      },
    );
  }

  // Search Bar
  Widget _buildSearchBar(AnchorProvider provider) {
    return Container(
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
      child: TextField(
        controller: _searchController,
        onChanged: (val) => provider.setSearchQuery(val),
        style: const TextStyle(fontSize: 14, color: AppTheme.textPrimary),
        decoration: InputDecoration(
          hintText: 'Search by event name, date, organizer...',
          hintStyle: const TextStyle(fontSize: 13, color: AppTheme.textMuted),
          prefixIcon: const Icon(Icons.search_rounded, color: AppTheme.primaryBlue, size: 20),
          suffixIcon: _searchController.text.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear_rounded, size: 18, color: AppTheme.textMuted),
                  onPressed: () {
                    _searchController.clear();
                    provider.setSearchQuery('');
                  },
                )
              : null,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          border: InputBorder.none,
        ),
      ),
    );
  }

  Widget _buildScriptsLibraryPromoBanner(BuildContext context) {
    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const ScriptsLibraryScreen()),
        );
      },
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF2563EB), Color(0xFF7C5CFC)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF4E6BEB).withValues(alpha: 0.25),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.description_rounded, color: Colors.white, size: 22),
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Browse Scripts Library',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                    ),
                  ),
                  SizedBox(height: 2),
                  Text(
                    'Search, filter, and review stage scripts with SmartEve AI',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      color: Colors.white70,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.arrow_forward_rounded, color: Colors.white, size: 16),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLiveStageCommandBanner(BuildContext context, AnchorProvider provider) {
    final activeEvent = provider.upcomingEvents.firstWhere(
      (e) => e.status == AnchorEventStatus.active,
      orElse: () => provider.upcomingEvents.isNotEmpty
          ? provider.upcomingEvents.first
          : const AnchorEventCardItem(
              id: "20b06ff2-bcdb-478d-9ebc-725f50f1f601",
              title: "ABC (Live Conclave)",
              eventType: "Seminar",
              date: "Today",
              time: "10:30 AM",
              organizerName: "Romal Tandel",
              collegeName: "SmartEve Partner Arena",
              status: AnchorEventStatus.active,
              joinCode: "AB26",
              venue: "Main Stage & Auditorium",
              duration: "3h 30m",
            ),
    );

    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => LiveDashboardScreen(eventId: activeEvent.id),
          ),
        );
      },
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF0F172A), Color(0xFF1E293B)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFFEF4444).withValues(alpha: 0.4), width: 1.5),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFFEF4444).withValues(alpha: 0.15),
              blurRadius: 14,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFFEF4444).withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.co_present_rounded, color: Color(0xFFEF4444), size: 24),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          color: Color(0xFFEF4444),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'LIVE STAGE COMMAND ACTIVE',
                        style: GoogleFonts.inter(
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          color: const Color(0xFFEF4444),
                          letterSpacing: 0.8,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 3),
                  Text(
                    'Enter Live Stage Dashboard',
                    style: GoogleFonts.inter(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${activeEvent.title} • Fullscreen podium view with real-time controls',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      color: const Color(0xFF94A3B8),
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFFEF4444).withValues(alpha: 0.2),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.arrow_forward_rounded, color: Colors.white, size: 16),
            ),
          ],
        ),
      ),
    );
  }

  // Section 1: Sticky Invitations Header & Cards
  Widget _buildStickyInvitationsSection(AnchorProvider provider) {
    final invitations = provider.filteredInvitations;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.primaryBlue.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(AppTheme.radiusCard),
        border: Border.all(color: AppTheme.primaryBlue.withValues(alpha: 0.25), width: 1.2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: const BoxDecoration(
                  color: AppTheme.primaryBlue,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 8),
              const Expanded(
                child: Text(
                  'PENDING EVENT INVITATIONS',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.2,
                    color: AppTheme.primaryBlue,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: AppTheme.primaryBlue,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${invitations.length} Action Required',
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...invitations.map((inv) => AnchorInvitationCard(
                invitation: inv,
                onAccept: () {
                  provider.acceptInvitation(inv.id);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('🎉 Accepted invitation for ${inv.title}! Moved to Upcoming Events.'),
                      backgroundColor: AppTheme.success,
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                },
                onDecline: () {
                  provider.declineInvitation(inv.id);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Declined invitation for ${inv.title}.'),
                      backgroundColor: AppTheme.textSecondary,
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                },
              )),
        ],
      ),
    );
  }

  // Mobile Layout (Stacked Vertically, 16px margins)
  Widget _buildMobileLayout(AnchorProvider provider) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildUpcomingEventsSection(provider),
        const SizedBox(height: 24),
        CompletedEventsSection(completedEvents: provider.filteredCompletedEvents),
      ],
    );
  }

  // Tablet Layout (2-Column)
  Widget _buildTabletLayout(AnchorProvider provider) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          flex: 3,
          child: _buildUpcomingEventsSection(provider),
        ),
        const SizedBox(width: 16),
        Expanded(
          flex: 2,
          child: CompletedEventsSection(completedEvents: provider.filteredCompletedEvents),
        ),
      ],
    );
  }

  // Desktop Layout (3-Column)
  Widget _buildDesktopLayout(AnchorProvider provider) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          flex: 4,
          child: _buildUpcomingEventsSection(provider),
        ),
        const SizedBox(width: 20),
        Expanded(
          flex: 3,
          child: CompletedEventsSection(completedEvents: provider.filteredCompletedEvents),
        ),
      ],
    );
  }

  // Section 2: Upcoming Events
  Widget _buildUpcomingEventsSection(AnchorProvider provider) {
    final events = provider.displayedUpcomingEvents;
    final totalCount = provider.filteredUpcomingEvents.length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'UPCOMING ASSIGNMENTS',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.1,
                color: AppTheme.textSecondary,
              ),
            ),
            if (totalCount > 3)
              TextButton(
                onPressed: () => provider.toggleViewAllUpcoming(),
                child: Text(
                  provider.isViewAllUpcoming ? 'Show Less' : 'View All ($totalCount)',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.primaryBlue,
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 10),

        if (events.isEmpty)
          _buildEmptyUpcomingState()
        else
          ...events.map((e) => UpcomingEventCard(event: e)),

        if (totalCount > 3 && !provider.isViewAllUpcoming)
          Center(
            child: TextButton.icon(
              onPressed: () => provider.toggleViewAllUpcoming(),
              icon: const Icon(Icons.arrow_downward_rounded, size: 14),
              label: Text('View All $totalCount Upcoming Events'),
              style: TextButton.styleFrom(foregroundColor: AppTheme.primaryBlue),
            ),
          ),
      ],
    );
  }

  // Empty State for Upcoming Events
  Widget _buildEmptyUpcomingState() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 36, horizontal: 20),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(AppTheme.radiusCard),
        border: Border.all(color: AppTheme.border),
      ),
      child: const Column(
        children: [
          Icon(Icons.event_busy_rounded, size: 48, color: AppTheme.textMuted),
          SizedBox(height: 12),
          Text(
            'No upcoming events',
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
          ),
          SizedBox(height: 4),
          Text(
            'Pending event invitations or new stage assignments will appear here.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 12, color: AppTheme.textSecondary),
          ),
        ],
      ),
    );
  }

  // Tab View for secondary tabs (Events, Notifications, Profile)
  Widget _buildOtherTabView(int index) {
    if (index == 3) {
      // Full notification center (filter + sort + list + thread)
      return const NotificationCenterScreen(isEmbedded: true);
    }

    if (index == 4) {
      // Full Profile and Settings Screen
      return const ProfileSettingsScreen(isEmbedded: true);
    }

    return const SizedBox.shrink();
  }

  void _showAiQuickAssistSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.auto_awesome_rounded, color: AppTheme.primaryBlue),
                      SizedBox(width: 8),
                      Text(
                        'SmartEve AI Assist',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
                      ),
                    ],
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded, color: AppTheme.textSecondary),
                    onPressed: () => Navigator.pop(ctx),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              const Text(
                'AI stage assistance active. Quick commands available for immediate broadcast:',
                style: TextStyle(fontSize: 13, color: AppTheme.textSecondary),
              ),
              const SizedBox(height: 16),
              ListTile(
                leading: const Icon(Icons.record_voice_over_rounded, color: AppTheme.primaryBlue),
                title: const Text('Generate Speaker Intro'),
                subtitle: const Text('Instantly write tailored stage prose'),
                trailing: const Icon(Icons.chevron_right_rounded),
                onTap: () {
                  Navigator.pop(ctx);
                  Navigator.push(context, MaterialPageRoute(builder: (_) => const AnchorTeleprompterScreen()));
                },
              ),
              ListTile(
                leading: const Icon(Icons.timer_rounded, color: AppTheme.warning),
                title: const Text('Emergency Buffer Announcement'),
                subtitle: const Text('Announce stage AV delays politely'),
                trailing: const Icon(Icons.chevron_right_rounded),
                onTap: () {
                  Navigator.pop(ctx);
                  Navigator.push(context, MaterialPageRoute(builder: (_) => const AnchorTeleprompterScreen()));
                },
              ),
            ],
          ),
        );
      },
    );
  }
}
