import 'dart:io';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/services/auth_service.dart';
import '../../../models/event_model.dart';
import '../../../models/speaker_model.dart';
import '../../../providers/event_provider.dart';
import '../../auth/login_screen.dart';
import '../../dashboard/stagepilot_dashboard_screen.dart';
import 'event_create_screen.dart';
import 'event_detail_screen.dart';
import 'speaker_add_screen.dart';

class OrganizerDashboardScreen extends StatefulWidget {
  const OrganizerDashboardScreen({super.key});

  @override
  State<OrganizerDashboardScreen> createState() => _OrganizerDashboardScreenState();
}

class _OrganizerDashboardScreenState extends State<OrganizerDashboardScreen> {
  int _currentTabIndex = 0; // 0: Home, 1: Events, 2: Create (Action), 3: Speakers, 4: Anchors & Reports
  String _selectedFilter = 'all'; // 'all', 'live', 'upcoming', 'draft'
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = context.read<EventProvider>();
      provider.fetchOrganizerEvents();
      provider.fetchSpeakers(provider.event?.id);
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _confirmLogout() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: const Row(
          children: [
            Icon(Icons.logout_rounded, color: AppTheme.dangerRose),
            SizedBox(width: 10),
            Text(
              'Sign Out',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: AppTheme.textPrimary),
            ),
          ],
        ),
        content: const Text(
          'Are you sure you want to sign out of SmartEve?',
          style: TextStyle(color: AppTheme.textSecondary, fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('CANCEL', style: TextStyle(color: AppTheme.textMuted, fontWeight: FontWeight.bold)),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await AuthService().signOut();
              if (mounted) {
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (_) => const LoginScreen()),
                  (route) => false,
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.dangerRose,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            ),
            child: const Text('LOGOUT', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  void _showProfileModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppTheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return DraggableScrollableSheet(
          initialChildSize: 0.75,
          minChildSize: 0.5,
          maxChildSize: 0.9,
          expand: false,
          builder: (_, controller) {
            return SingleChildScrollView(
              controller: controller,
              padding: const EdgeInsets.all(24),
              child: _buildProfileContent(context),
            );
          },
        );
      },
    );
  }

  List<EventModel> _getFilteredEvents(List<EventModel> events) {
    final query = _searchController.text.toLowerCase().trim();
    return events.where((evt) {
      final matchesQuery = query.isEmpty ||
          evt.name.toLowerCase().contains(query) ||
          evt.venue.toLowerCase().contains(query) ||
          evt.joinCode.toLowerCase().contains(query);

      if (!matchesQuery) return false;

      if (_selectedFilter == 'live') {
        return evt.liveState.status == 'live';
      } else if (_selectedFilter == 'upcoming') {
        return evt.liveState.status == 'published';
      } else if (_selectedFilter == 'draft') {
        return evt.liveState.status == 'draft';
      }
      return true;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = MediaQuery.of(context).size.width > 600;
    final navHeight = isDesktop ? 72.0 : 64.0;
    final user = AuthService().currentAppUser;

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: Row(
          children: [
            Image.asset(
              'assets/trans_icon.png',
              width: 32,
              height: 32,
              errorBuilder: (_, __, ___) => const Icon(Icons.dashboard_customize_rounded, color: AppTheme.primaryBlue),
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _getAppBarTitle(),
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: AppTheme.textPrimary),
                ),
                const Text(
                  'SmartEve Event Organizer Portal',
                  style: TextStyle(fontSize: 11, color: AppTheme.textSecondary),
                ),
              ],
            ),
          ],
        ),
        actions: [
          // Profile Avatar replacing Logout in top bar
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: InkWell(
              onTap: _showProfileModal,
              borderRadius: BorderRadius.circular(20),
              child: Container(
                padding: const EdgeInsets.all(3),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: AppTheme.primaryBlue.withValues(alpha: 0.4), width: 1.5),
                ),
                child: CircleAvatar(
                  radius: 16,
                  backgroundColor: AppTheme.primaryBlue.withValues(alpha: 0.15),
                  child: Text(
                    (user?.fullName.isNotEmpty == true) ? user!.fullName[0].toUpperCase() : 'A',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppTheme.primaryBlue),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
      body: Stack(
        children: [
          // Main Body Tab Views
          Positioned.fill(
            child: Consumer<EventProvider>(
              builder: (context, provider, _) {
                final events = provider.organizerEvents;
                final filteredEvents = _getFilteredEvents(events);

                return IndexedStack(
                  index: _currentTabIndex,
                  children: [
                    // Tab 0: Home Overview
                    _buildHomeTab(events, filteredEvents, provider),

                    // Tab 1: Events Management
                    _buildEventsTab(events, filteredEvents, provider),

                    // Tab 2: Create (Placeholder while pushing screen)
                    const SizedBox.shrink(),

                    // Tab 3: Milestone 2 Speakers & Guest Management
                    _buildSpeakersTab(provider),

                    // Tab 4: Anchors & Reports
                    _buildAnchorsAndReportsTab(events),
                  ],
                );
              },
            ),
          ),

          // Floating Glassmorphism Bottom Navigation Bar (5 Tabs)
          Positioned(
            left: 16,
            right: 16,
            bottom: 16,
            child: _buildFloatingBottomNav(navHeight),
          ),
        ],
      ),
    );
  }

  String _getAppBarTitle() {
    switch (_currentTabIndex) {
      case 0:
        return 'Dashboard';
      case 1:
        return 'Manage Events';
      case 3:
        return 'Speakers & Guests';
      case 4:
        return 'Anchors & Analytics';
      default:
        return 'Organizer Portal';
    }
  }

  // Floating Bottom Navigation Bar Widget (5 Tabs)
  Widget _buildFloatingBottomNav(double navHeight) {
    return Consumer<EventProvider>(
      builder: (context, provider, _) {
        final events = provider.organizerEvents;
        final speakers = provider.speakers;
        final pendingDraftsCount = events.where((e) => e.liveState.status == 'draft').length;

        return ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
            child: Container(
              height: navHeight,
              padding: const EdgeInsets.symmetric(horizontal: 8),
              decoration: BoxDecoration(
                color: const Color(0xFF0F172A).withValues(alpha: 0.88),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.15),
                  width: 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.3),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  // 1. HOME
                  _buildNavItem(
                    index: 0,
                    icon: Icons.grid_view_rounded,
                    label: 'Home',
                  ),

                  // 2. EVENTS
                  _buildNavItem(
                    index: 1,
                    icon: Icons.event_note_rounded,
                    label: 'Events',
                    badgeCount: pendingDraftsCount > 0 ? pendingDraftsCount : null,
                  ),

                  // 3. CREATE (Center Featured Button)
                  _buildCenterCreateNavItem(),

                  // 4. SPEAKERS (Milestone 2)
                  _buildNavItem(
                    index: 3,
                    icon: Icons.record_voice_over_rounded,
                    label: 'Speakers',
                    badgeCount: speakers.isNotEmpty ? speakers.length : null,
                  ),

                  // 5. ANCHORS & REPORTS
                  _buildNavItem(
                    index: 4,
                    icon: Icons.bar_chart_rounded,
                    label: 'Reports',
                    hasDotBadge: true,
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildNavItem({
    required int index,
    required IconData icon,
    required String label,
    int? badgeCount,
    bool hasDotBadge = false,
  }) {
    final isSelected = _currentTabIndex == index;
    const activeColor = AppTheme.primaryBlue;
    const inactiveColor = Colors.white60;

    return InkWell(
      onTap: () => setState(() => _currentTabIndex = index),
      borderRadius: BorderRadius.circular(12),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? activeColor.withValues(alpha: 0.18) : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                Icon(
                  icon,
                  size: isSelected ? 28 : 24,
                  color: isSelected ? activeColor : inactiveColor,
                ),
                if (badgeCount != null)
                  Positioned(
                    top: -4,
                    right: -8,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: const BoxDecoration(
                        color: AppTheme.dangerRose,
                        shape: BoxShape.circle,
                      ),
                      constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
                      child: Text(
                        '$badgeCount',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  )
                else if (hasDotBadge)
                  Positioned(
                    top: -2,
                    right: -2,
                    child: Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                        color: AppTheme.liveGreen,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 3),
            AnimatedDefaultTextStyle(
              duration: const Duration(milliseconds: 200),
              style: TextStyle(
                fontSize: 10,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                color: isSelected ? activeColor : inactiveColor,
              ),
              child: Text(label),
            ),
          ],
        ),
      ),
    );
  }

  // Center Featured CREATE Button
  Widget _buildCenterCreateNavItem() {
    return GestureDetector(
      onTap: () async {
        await Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const EventCreateScreen()),
        );
        if (mounted) {
          final p = context.read<EventProvider>();
          await p.fetchOrganizerEvents();
        }
      },
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [AppTheme.primaryBlue, Color(0xFF1D4ED8)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: AppTheme.primaryBlue.withValues(alpha: 0.5),
              blurRadius: 14,
              spreadRadius: 2,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: const Icon(
          Icons.add_rounded,
          color: Colors.white,
          size: 28,
        ),
      ),
    );
  }

  // TAB 0: HOME OVERVIEW
  Widget _buildHomeTab(List<EventModel> events, List<EventModel> filteredEvents, EventProvider provider) {
    return RefreshIndicator(
      onRefresh: () async {
        await provider.fetchOrganizerEvents();
        await provider.fetchSpeakers(provider.event?.id);
      },
      color: AppTheme.primaryBlue,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.only(left: 20, right: 20, top: 16, bottom: 120),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildWelcomeHeader(context, events.length),
            const SizedBox(height: 20),
            _buildMetricsBar(events),
            const SizedBox(height: 24),
            const Text(
              'ACTIVE & UPCOMING STAGE EVENTS',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1.2, color: AppTheme.textSecondary),
            ),
            const SizedBox(height: 14),
            if (events.isEmpty)
              _buildEmptyState(context)
            else
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: events.take(3).length,
                separatorBuilder: (_, __) => const SizedBox(height: 14),
                itemBuilder: (context, index) {
                  return _buildEventCard(context, events[index], provider);
                },
              ),
          ],
        ),
      ),
    );
  }

  // TAB 1: EVENTS MANAGEMENT
  Widget _buildEventsTab(List<EventModel> events, List<EventModel> filteredEvents, EventProvider provider) {
    return RefreshIndicator(
      onRefresh: () async {
        await provider.fetchOrganizerEvents();
      },
      color: AppTheme.primaryBlue,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.only(left: 20, right: 20, top: 16, bottom: 120),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    onChanged: (_) => setState(() {}),
                    decoration: InputDecoration(
                      hintText: 'Search events, venue or join code...',
                      hintStyle: const TextStyle(fontSize: 13, color: AppTheme.textMuted),
                      prefixIcon: const Icon(Icons.search_rounded, color: AppTheme.textSecondary, size: 20),
                      filled: true,
                      fillColor: AppTheme.surface,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppTheme.border)),
                      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppTheme.border)),
                      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppTheme.primaryBlue, width: 1.5)),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _buildFilterChip('All Events', 'all', events.length),
                  const SizedBox(width: 8),
                  _buildFilterChip('Live Now', 'live', events.where((e) => e.liveState.status == 'live').length, activeColor: AppTheme.liveGreen),
                  const SizedBox(width: 8),
                  _buildFilterChip('Upcoming', 'upcoming', events.where((e) => e.liveState.status == 'published').length, activeColor: AppTheme.primaryBlue),
                  const SizedBox(width: 8),
                  _buildFilterChip('Drafts', 'draft', events.where((e) => e.liveState.status == 'draft').length, activeColor: AppTheme.warningAmber),
                ],
              ),
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'YOUR MANAGED EVENTS (${filteredEvents.length})',
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1.2, color: AppTheme.textSecondary),
                ),
                if (provider.isLoading)
                  const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: AppTheme.primaryBlue)),
              ],
            ),
            const SizedBox(height: 14),
            if (filteredEvents.isEmpty)
              _buildEmptyState(context)
            else
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: filteredEvents.length,
                separatorBuilder: (_, __) => const SizedBox(height: 14),
                itemBuilder: (context, index) {
                  return _buildEventCard(context, filteredEvents[index], provider);
                },
              ),
          ],
        ),
      ),
    );
  }

  // TAB 3: MILESTONE 2 SPEAKERS MANAGEMENT
  Widget _buildSpeakersTab(EventProvider provider) {
    final speakers = provider.speakers;

    return RefreshIndicator(
      onRefresh: () async {
        await provider.fetchSpeakers(provider.event?.id);
      },
      color: AppTheme.primaryBlue,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.only(left: 20, right: 20, top: 16, bottom: 120),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Banner Card with CTA
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [AppTheme.liveGreen, Color(0xFF047857)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.liveGreen.withValues(alpha: 0.25),
                    blurRadius: 16,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Row(
                          children: [
                            Icon(Icons.mic_external_on_rounded, color: Colors.white, size: 20),
                            SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                'MILESTONE 2: SPEAKER ROSTER',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 1.2,
                                  color: Colors.white70,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Speaker & Guest Management',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${speakers.length} keynote speakers registered. Saved directly to Neon DB.',
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.white70,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 10),
                  ElevatedButton.icon(
                    onPressed: () async {
                      final p = provider;
                      await Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => const SpeakerAddScreen()),
                      );
                      await p.fetchSpeakers(p.event?.id);
                    },
                    icon: const Icon(Icons.add_rounded, size: 18, color: AppTheme.liveGreen),
                    label: const Text('ADD', style: TextStyle(fontWeight: FontWeight.bold, color: AppTheme.liveGreen)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'REGISTERED SPEAKERS (${speakers.length})',
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1.2, color: AppTheme.textSecondary),
                ),
                IconButton(
                  icon: const Icon(Icons.refresh_rounded, size: 20, color: AppTheme.primaryBlue),
                  tooltip: 'Refresh Speakers from Neon DB',
                  onPressed: () => provider.fetchSpeakers(provider.event?.id),
                ),
              ],
            ),
            const SizedBox(height: 12),

            if (speakers.isEmpty)
              Container(
                padding: const EdgeInsets.all(32),
                decoration: BoxDecoration(
                  color: AppTheme.surface,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppTheme.border),
                ),
                child: Column(
                  children: [
                    const Icon(Icons.record_voice_over_rounded, size: 54, color: AppTheme.textMuted),
                    const SizedBox(height: 14),
                    const Text('No Speakers Added Yet', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.textPrimary)),
                    const SizedBox(height: 6),
                    const Text('Add keynote speakers and VIP guests to generate AI stage intros.', textAlign: TextAlign.center, style: TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
                    const SizedBox(height: 18),
                    ElevatedButton.icon(
                      onPressed: () async {
                        final p = provider;
                        await Navigator.of(context).push(MaterialPageRoute(builder: (_) => const SpeakerAddScreen()));
                        await p.fetchSpeakers(p.event?.id);
                      },
                      style: ElevatedButton.styleFrom(backgroundColor: AppTheme.liveGreen),
                      icon: const Icon(Icons.add_rounded, color: Colors.white),
                      label: const Text('ADD FIRST SPEAKER', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
              )
            else
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: speakers.length,
                separatorBuilder: (_, __) => const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  final spk = speakers[index];
                  return _buildSpeakerCard(context, spk, provider);
                },
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildSpeakerCard(BuildContext context, SpeakerModel speaker, EventProvider provider) {
    ImageProvider? avatarImage;
    if (speaker.photoUrl != null && speaker.photoUrl!.isNotEmpty) {
      if (speaker.photoUrl!.startsWith('http://') || speaker.photoUrl!.startsWith('https://')) {
        avatarImage = NetworkImage(speaker.photoUrl!);
      } else {
        avatarImage = FileImage(File(speaker.photoUrl!));
      }
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 24,
                backgroundColor: AppTheme.primaryBlue.withValues(alpha: 0.15),
                backgroundImage: avatarImage,
                child: avatarImage == null
                    ? Text(speaker.name.isNotEmpty ? speaker.name[0].toUpperCase() : 'S', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.primaryBlue))
                    : null,
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      speaker.name,
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${speaker.designation} • ${speaker.organization}',
                      style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppTheme.liveGreen.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Text('READY', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppTheme.liveGreen)),
              ),
            ],
          ),
          if (speaker.topic.isNotEmpty) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppTheme.surfaceLight,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  const Icon(Icons.topic_rounded, size: 16, color: AppTheme.primaryBlue),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Topic: ${speaker.topic}',
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppTheme.textPrimary),
                    ),
                  ),
                ],
              ),
            ),
          ],
          if (speaker.bio.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              speaker.bio,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary, height: 1.3),
            ),
          ],
          const SizedBox(height: 12),
          const Divider(height: 1, color: AppTheme.border),
          const SizedBox(height: 8),

          // Actions Row
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton.icon(
                onPressed: () async {
                  await Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => SpeakerAddScreen(speakerToEdit: speaker),
                    ),
                  );
                  if (context.mounted) {
                    await provider.fetchSpeakers(provider.event?.id);
                  }
                },
                icon: const Icon(Icons.edit_rounded, size: 16, color: AppTheme.primaryBlue),
                label: const Text('Edit', style: TextStyle(fontSize: 12, color: AppTheme.primaryBlue, fontWeight: FontWeight.bold)),
              ),
              const SizedBox(width: 8),
              TextButton.icon(
                onPressed: () async {
                  final confirm = await showDialog<bool>(
                    context: context,
                    builder: (ctx) => AlertDialog(
                      backgroundColor: AppTheme.surface,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      title: const Text('Delete Speaker', style: TextStyle(fontWeight: FontWeight.bold)),
                      content: Text('Remove "${speaker.name}" from Neon DB?'),
                      actions: [
                        TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('CANCEL')),
                        ElevatedButton(
                          onPressed: () => Navigator.pop(ctx, true),
                          style: ElevatedButton.styleFrom(backgroundColor: AppTheme.dangerRose),
                          child: const Text('DELETE', style: TextStyle(color: Colors.white)),
                        ),
                      ],
                    ),
                  );

                  if (confirm == true) {
                    await provider.deleteSpeaker(speaker.id);
                  }
                },
                icon: const Icon(Icons.delete_outline_rounded, size: 16, color: AppTheme.dangerRose),
                label: const Text('Delete', style: TextStyle(fontSize: 12, color: AppTheme.dangerRose, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // TAB 4: ANCHORS & REPORTS
  Widget _buildAnchorsAndReportsTab(List<EventModel> events) {
    final provider = context.watch<EventProvider>();
    final speakersCount = provider.speakers.length;
    final publishedCount = events.where((e) => e.liveState.status == 'published').length;
    final liveCount = events.where((e) => e.liveState.status == 'live').length;
    final draftCount = events.where((e) => e.liveState.status == 'draft').length;

    return SingleChildScrollView(
      padding: const EdgeInsets.only(left: 20, right: 20, top: 16, bottom: 100),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
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
                    color: AppTheme.liveGreen.withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.mic_external_on_rounded, color: AppTheme.liveGreen, size: 28),
                ),
                const SizedBox(width: 16),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Stage Anchors & Analytics', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.textPrimary)),
                      SizedBox(height: 4),
                      Text('Real-time stage timeline metrics and active join codes from Neon DB.', style: TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          const Text('STAGE JOIN CODES & ANCHOR ACCESS', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1.2, color: AppTheme.textSecondary)),
          const SizedBox(height: 14),

          if (events.isEmpty)
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppTheme.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppTheme.border),
              ),
              child: const Column(
                children: [
                  Icon(Icons.vpn_key_rounded, size: 32, color: AppTheme.textMuted),
                  SizedBox(height: 10),
                  Text('No Active Event Join Codes', style: TextStyle(fontWeight: FontWeight.bold, color: AppTheme.textPrimary)),
                  SizedBox(height: 4),
                  Text('Create an event to generate secure join codes for stage anchors.', style: TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
                ],
              ),
            )
          else
            Column(
              children: events.map((evt) {
                final isLive = evt.liveState.status == 'live';
                final isPub = evt.liveState.status == 'published';
                final color = isLive ? AppTheme.liveGreen : (isPub ? AppTheme.primaryBlue : AppTheme.warningAmber);
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _buildAnchorCard('Stage Anchor', evt.type, evt.name, evt.joinCode, color),
                );
              }).toList(),
            ),

          const SizedBox(height: 24),
          const Text('ORGANIZATION METRICS (NEON DB)', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1.2, color: AppTheme.textSecondary)),
          const SizedBox(height: 14),
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 2,
            crossAxisSpacing: 14,
            mainAxisSpacing: 14,
            childAspectRatio: 1.3,
            children: [
              _buildAnalyticsCard('Total Events', '${events.length} Events', Icons.event_rounded, AppTheme.primaryBlue),
              _buildAnalyticsCard('Registered Speakers', '$speakersCount Speakers', Icons.record_voice_over_rounded, AppTheme.liveGreen),
              _buildAnalyticsCard('Published Events', '$publishedCount Published', Icons.publish_rounded, AppTheme.primaryPurple),
              _buildAnalyticsCard('Live / Draft State', '$liveCount Live • $draftCount Draft', Icons.sensors_rounded, AppTheme.warningAmber),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAnchorCard(String name, String role, String eventName, String code, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.border),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 22,
            backgroundColor: color.withValues(alpha: 0.2),
            child: Text(name[0], style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: color)),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppTheme.textPrimary)),
                Text('$role • $eventName', style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(color: color.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(8)),
            child: Text('Code: $code', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: color)),
          ),
        ],
      ),
    );
  }

  Widget _buildAnalyticsCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: AppTheme.surface, borderRadius: BorderRadius.circular(16), border: Border.all(color: AppTheme.border)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Icon(icon, color: color, size: 24),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(value, style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: color)),
              const SizedBox(height: 2),
              Text(title, style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary)),
            ],
          ),
        ],
      ),
    );
  }

  // Profile Content Modal View
  Widget _buildProfileContent(BuildContext context) {
    final user = AuthService().currentAppUser;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Center(
          child: Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(color: AppTheme.border, borderRadius: BorderRadius.circular(2)),
          ),
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(color: AppTheme.surfaceLight, borderRadius: BorderRadius.circular(18), border: Border.all(color: AppTheme.border)),
          child: Row(
            children: [
              CircleAvatar(
                radius: 30,
                backgroundColor: AppTheme.primaryBlue.withValues(alpha: 0.15),
                child: Text(
                  (user?.fullName.isNotEmpty == true) ? user!.fullName[0].toUpperCase() : 'A',
                  style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppTheme.primaryBlue),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(user?.fullName ?? 'Alex Rivera', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.textPrimary)),
                    const SizedBox(height: 2),
                    Text(user?.email ?? 'alex@technova.io', style: const TextStyle(fontSize: 13, color: AppTheme.textSecondary)),
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(color: AppTheme.primaryBlue.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(6)),
                      child: const Text('EVENT ORGANIZER', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppTheme.primaryBlue)),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        const Text('ACCOUNT & PREFERENCES', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1.2, color: AppTheme.textSecondary)),
        const SizedBox(height: 12),
        _buildSettingsTile(Icons.notifications_active_rounded, 'Push Notification Alerts', 'Receive real-time delay & anchor updates', true),
        _buildSettingsTile(Icons.smart_toy_rounded, 'Quad-AI Provider Fallback', 'Gemini -> Llama 3.3 -> Nvidia NIM', true),
        _buildSettingsTile(Icons.storage_rounded, 'Neon Tech Database TLS Sync', 'Direct PostgreSQL connection active', true),
        const SizedBox(height: 24),
        SizedBox(
          width: double.infinity,
          height: 48,
          child: OutlinedButton.icon(
            onPressed: () {
              Navigator.pop(context);
              _confirmLogout();
            },
            icon: const Icon(Icons.logout_rounded, color: AppTheme.dangerRose),
            label: const Text('SIGN OUT', style: TextStyle(color: AppTheme.dangerRose, fontWeight: FontWeight.bold)),
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: AppTheme.dangerRose),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildSettingsTile(IconData icon, String title, String subtitle, bool value) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(color: AppTheme.surface, borderRadius: BorderRadius.circular(14), border: Border.all(color: AppTheme.border)),
      child: Row(
        children: [
          Icon(icon, color: AppTheme.primaryBlue, size: 22),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppTheme.textPrimary)),
                Text(subtitle, style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
              ],
            ),
          ),
          Switch(value: value, onChanged: (_) {}, activeThumbColor: AppTheme.primaryBlue),
        ],
      ),
    );
  }

  Widget _buildWelcomeHeader(BuildContext context, int totalEvents) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppTheme.primaryBlue, Color(0xFF1E40AF)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryBlue.withValues(alpha: 0.25),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(Icons.stars_rounded, color: AppTheme.warningAmber, size: 20),
                    SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        'EVENT ORGANIZER DASHBOARD',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.2,
                          color: Colors.white70,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                const Text(
                  'Welcome Back, Organizer!',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'You have $totalEvents active event configurations ready for execution.',
                  style: const TextStyle(
                    fontSize: 13,
                    color: Colors.white70,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetricsBar(List<EventModel> events) {
    final liveCount = events.where((e) => e.liveState.status == 'live').length;
    final publishedCount = events.where((e) => e.liveState.status == 'published').length;

    return Row(
      children: [
        Expanded(
          child: _buildMetricTile(
            label: 'Total Events',
            value: '${events.length}',
            icon: Icons.event_available_rounded,
            color: AppTheme.primaryBlue,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildMetricTile(
            label: 'Live Stage',
            value: '$liveCount',
            icon: Icons.sensors_rounded,
            color: AppTheme.liveGreen,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildMetricTile(
            label: 'Upcoming',
            value: '$publishedCount',
            icon: Icons.schedule_rounded,
            color: AppTheme.primaryPurple,
          ),
        ),
      ],
    );
  }

  Widget _buildMetricTile({
    required String label,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                value,
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
              Icon(icon, size: 20, color: color),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(
              fontSize: 11,
              color: AppTheme.textSecondary,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, String value, int count, {Color? activeColor}) {
    final isSelected = _selectedFilter == value;
    final color = activeColor ?? AppTheme.primaryBlue;

    return ChoiceChip(
      label: Text('$label ($count)'),
      selected: isSelected,
      onSelected: (_) => setState(() => _selectedFilter = value),
      selectedColor: color.withValues(alpha: 0.15),
      side: BorderSide(color: isSelected ? color : AppTheme.border),
      labelStyle: TextStyle(
        fontSize: 12,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        color: isSelected ? color : AppTheme.textSecondary,
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
    );
  }

  Widget _buildEventCard(BuildContext context, EventModel event, EventProvider provider) {
    Color statusColor;
    String statusText;

    switch (event.liveState.status) {
      case 'live':
        statusColor = AppTheme.liveGreen;
        statusText = '● STAGE LIVE';
        break;
      case 'published':
        statusColor = AppTheme.primaryBlue;
        statusText = 'PUBLISHED';
        break;
      default:
        statusColor = AppTheme.warningAmber;
        statusText = 'DRAFT';
    }

    return Container(
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppTheme.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: const BoxDecoration(
              color: AppTheme.surfaceLight,
              borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
              border: Border(bottom: BorderSide(color: AppTheme.border)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Flexible(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: statusColor.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: statusColor.withValues(alpha: 0.4)),
                    ),
                    child: Text(
                      statusText,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        color: statusColor,
                        letterSpacing: 0.8,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Flexible(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryBlue.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.qr_code_rounded, size: 14, color: AppTheme.primaryBlue),
                        const SizedBox(width: 4),
                        Flexible(
                          child: Text(
                            'Code: ${event.joinCode}',
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.primaryBlue,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  event.name,
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textPrimary,
                  ),
                ),
                if (event.description.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Text(
                    event.description,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 13,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                ],
                const SizedBox(height: 14),
                Row(
                  children: [
                    const Icon(Icons.calendar_today_rounded, size: 14, color: AppTheme.textMuted),
                    const SizedBox(width: 6),
                    Flexible(
                      child: Text(
                        event.date,
                        style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Icon(Icons.location_on_rounded, size: 14, color: AppTheme.textMuted),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        event.venue,
                        style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                const Divider(height: 1, color: AppTheme.border),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => EventDetailScreen(event: event),
                            ),
                          );
                        },
                        icon: const Icon(Icons.edit_calendar_rounded, size: 16, color: AppTheme.primaryBlue),
                        label: const Text(
                          'Manage Event',
                          style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppTheme.primaryBlue),
                        ),
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: AppTheme.primaryBlue),
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () {
                          provider.selectEvent(event);
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => const StagePilotDashboardScreen(),
                            ),
                          );
                        },
                        icon: const Icon(Icons.tune_rounded, size: 16, color: Colors.white),
                        label: const Text(
                          'Control Room',
                          style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primaryBlue,
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.border),
      ),
      child: Column(
        children: [
          const Icon(Icons.event_note_rounded, size: 60, color: AppTheme.textMuted),
          const SizedBox(height: 16),
          const Text(
            'No Events Found',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
          ),
          const SizedBox(height: 6),
          const Text(
            'Get started by creating your first mission-critical event configuration.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 13, color: AppTheme.textSecondary),
          ),
          const SizedBox(height: 20),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const EventCreateScreen()),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryBlue,
            ),
            icon: const Icon(Icons.add_rounded, color: Colors.white),
            label: const Text('CREATE NEW EVENT', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}
