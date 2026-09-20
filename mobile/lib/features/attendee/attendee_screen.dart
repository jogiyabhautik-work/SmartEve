import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../core/services/auth_service.dart';
import '../../core/theme/app_theme.dart';
import '../../models/agenda_item_model.dart';
import '../../models/speaker_model.dart';
import '../../providers/event_provider.dart';
import '../auth/login_screen.dart';
import '../auth/role_selection_screen.dart';

class AttendeeScreen extends StatefulWidget {
  const AttendeeScreen({super.key});

  @override
  State<AttendeeScreen> createState() => _AttendeeScreenState();
}

class _AttendeeScreenState extends State<AttendeeScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _questionController = TextEditingController();
  final TextEditingController _authorNameController = TextEditingController();
  String _selectedFilter = 'all'; // all, live, upcoming, done
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final provider = context.read<EventProvider>();
      if (provider.event == null) {
        await provider.fetchOrganizerEvents();
        if (provider.organizerEvents.isNotEmpty) {
          provider.selectEvent(provider.organizerEvents.first);
        }
      } else {
        await provider.fetchAgenda(provider.event?.id);
        await provider.fetchSpeakers(provider.event?.id);
        await provider.fetchQnaQuestions();
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _questionController.dispose();
    _authorNameController.dispose();
    super.dispose();
  }

  void _handleSignOut() async {
    await AuthService().signOut();
    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (route) => false,
    );
  }

  void _showAskQuestionModal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppTheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (modalCtx, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                left: 20,
                right: 20,
                top: 20,
                bottom: MediaQuery.of(modalCtx).viewInsets.bottom + 20,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Expanded(
                        child: Row(
                          children: [
                            Icon(Icons.question_answer_rounded, color: AppTheme.liveGreen, size: 22),
                            SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Ask Active Speaker',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: AppTheme.textPrimary,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close_rounded, color: AppTheme.textMuted),
                        onPressed: () => Navigator.pop(modalCtx),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  TextField(
                    controller: _authorNameController,
                    style: const TextStyle(color: AppTheme.textPrimary),
                    decoration: InputDecoration(
                      hintText: 'Your Name (e.g. Romal Tandel)',
                      prefixIcon: const Icon(Icons.person_outline_rounded, color: AppTheme.cyan),
                      filled: true,
                      fillColor: AppTheme.background,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: AppTheme.border),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _questionController,
                    maxLines: 3,
                    style: const TextStyle(color: AppTheme.textPrimary),
                    decoration: InputDecoration(
                      hintText: 'Type your question for the stage speaker...',
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
                    onPressed: _isSubmitting
                        ? null
                        : () async {
                            final text = _questionController.text.trim();
                            if (text.isEmpty) return;
                            setModalState(() => _isSubmitting = true);
                            final provider = context.read<EventProvider>();
                            final ok = await provider.submitQnaQuestion(
                              text,
                              authorName: _authorNameController.text.trim(),
                            );
                            setModalState(() => _isSubmitting = false);
                            if (modalCtx.mounted && ok) {
                              _questionController.clear();
                              Navigator.pop(modalCtx);
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('🎉 Question submitted to stage control room!'),
                                  backgroundColor: AppTheme.liveGreen,
                                  behavior: SnackBarBehavior.floating,
                                ),
                              );
                            }
                          },
                    icon: _isSubmitting
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                          )
                        : const Icon(Icons.send_rounded, color: Colors.white),
                    label: Text(
                      _isSubmitting ? 'SUBMITTING...' : 'SUBMIT QUESTION TO STAGE',
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.liveGreen,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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

  void _showSpeakerDetailsModal(BuildContext context, SpeakerModel speaker) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppTheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppTheme.border,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  CircleAvatar(
                    radius: 36,
                    backgroundColor: AppTheme.cyan.withValues(alpha: 0.2),
                    backgroundImage: (speaker.photoUrl != null && speaker.photoUrl!.isNotEmpty)
                        ? CachedNetworkImageProvider(speaker.photoUrl!)
                        : null,
                    child: (speaker.photoUrl == null || speaker.photoUrl!.isEmpty)
                        ? Text(
                            speaker.name.isNotEmpty ? speaker.name.substring(0, 1) : '🎤',
                            style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: AppTheme.cyan),
                          )
                        : null,
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          speaker.name,
                          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${speaker.designation} • ${speaker.organization}',
                          style: const TextStyle(fontSize: 14, color: AppTheme.textSecondary),
                        ),
                        if (speaker.topic.isNotEmpty) ...[
                          const SizedBox(height: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: AppTheme.cyan.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              'Topic: ${speaker.topic}',
                              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppTheme.cyan),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              const Text('ABOUT THE SPEAKER', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1.2, color: AppTheme.textMuted)),
              const SizedBox(height: 8),
              Text(
                speaker.bio.isNotEmpty ? speaker.bio : 'Keynote speaker and industry leader showcasing insights at SmartEve Summit.',
                style: const TextStyle(fontSize: 14, height: 1.5, color: AppTheme.textSecondary),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () => Navigator.pop(ctx),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: AppTheme.border),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text('CLOSE', style: TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.bold)),
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
    final eventProvider = context.watch<EventProvider>();
    final currentEvent = eventProvider.event;
    final currentSession = eventProvider.currentSession;
    final currentSpeaker = eventProvider.currentSpeaker;
    final remainingSec = eventProvider.remainingSeconds;
    final isOvertime = remainingSec < 0;

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              currentEvent?.name ?? 'SmartEve Live Summit',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
            ),
            Row(
              children: [
                Container(
                  width: 6,
                  height: 6,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: currentEvent?.liveState.status == 'live' ? AppTheme.liveGreen : AppTheme.warningAmber,
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  currentEvent?.liveState.status == 'live' ? 'LIVE NOW • Real-Time Sync' : 'Upcoming Event',
                  style: TextStyle(
                    fontSize: 11,
                    color: currentEvent?.liveState.status == 'live' ? AppTheme.liveGreen : AppTheme.textSecondary,
                  ),
                ),
              ],
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: AppTheme.primaryBlue),
            tooltip: 'Sync Stage State',
            onPressed: () async {
              await eventProvider.fetchOrganizerEvents();
              await eventProvider.fetchAgenda(eventProvider.event?.id);
              await eventProvider.fetchSpeakers(eventProvider.event?.id);
              await eventProvider.fetchQnaQuestions();
            },
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert_rounded, color: AppTheme.textPrimary),
            color: AppTheme.surface,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: const BorderSide(color: AppTheme.border)),
            onSelected: (val) {
              if (val == 'roles') {
                Navigator.of(context).push(MaterialPageRoute(builder: (_) => const RoleSelectionScreen()));
              } else if (val == 'logout') {
                _handleSignOut();
              }
            },
            itemBuilder: (ctx) => [
              const PopupMenuItem(
                value: 'roles',
                child: Row(
                  children: [
                    Icon(Icons.swap_horiz_rounded, size: 18, color: AppTheme.warningAmber),
                    SizedBox(width: 10),
                    Text('Switch App Role', style: TextStyle(color: AppTheme.textPrimary, fontSize: 13)),
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
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppTheme.cyan,
          labelColor: AppTheme.cyan,
          unselectedLabelColor: AppTheme.textMuted,
          labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
          tabs: const [
            Tab(icon: Icon(Icons.schedule_rounded, size: 18), text: 'STAGE & TIMELINE'),
            Tab(icon: Icon(Icons.mic_external_on_rounded, size: 18), text: 'SPEAKERS'),
            Tab(icon: Icon(Icons.question_answer_rounded, size: 18), text: 'LIVE Q&A'),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppTheme.liveGreen,
        onPressed: () => _showAskQuestionModal(context),
        icon: const Icon(Icons.chat_bubble_outline_rounded, color: Colors.white),
        label: const Text('ASK SPEAKER', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // Tab 1: Live Stage Hero Banner + Agenda Timeline
          _buildStageAndTimelineTab(eventProvider, currentSession, currentSpeaker, remainingSec, isOvertime),

          // Tab 2: Speakers Roster Grid
          _buildSpeakersTab(eventProvider),

          // Tab 3: Live Q&A Stream
          _buildQnaTab(eventProvider),
        ],
      ),
    );
  }

  Widget _buildStageAndTimelineTab(
    EventProvider provider,
    AgendaItemModel? session,
    SpeakerModel? speaker,
    int remainingSec,
    bool isOvertime,
  ) {
    final agendaList = provider.agenda;
    final notifications = provider.notifications;

    List<AgendaItemModel> filteredList = agendaList;
    if (_selectedFilter == 'live') {
      filteredList = agendaList.where((a) => a.isLive).toList();
    } else if (_selectedFilter == 'upcoming') {
      filteredList = agendaList.where((a) => a.isUpcoming).toList();
    } else if (_selectedFilter == 'done') {
      filteredList = agendaList.where((a) => a.isDone).toList();
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Live Stage Hero Banner
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF1E293B), Color(0xFF0F172A)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppTheme.cyan.withValues(alpha: 0.4), width: 1.5),
              boxShadow: [
                BoxShadow(
                  color: AppTheme.cyan.withValues(alpha: 0.1),
                  blurRadius: 16,
                  spreadRadius: 2,
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
                        color: AppTheme.liveGreen.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.sensors_rounded, color: AppTheme.liveGreen, size: 14),
                          SizedBox(width: 6),
                          Text(
                            'LIVE STAGE PROJECTION',
                            style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppTheme.liveGreen),
                          ),
                        ],
                      ),
                    ),
                    Text(
                      provider.formattedCountdown,
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                        color: isOvertime ? AppTheme.dangerRose : AppTheme.cyan,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Text(
                  session?.title ?? 'Stage Session In Progress',
                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    const Icon(Icons.timer_outlined, color: AppTheme.textSecondary, size: 14),
                    const SizedBox(width: 4),
                    Text(
                      'Duration: ${session?.duration ?? 15} mins • ${session?.type.toUpperCase() ?? "TALK"}',
                      style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Active Speaker Sub-card
                if (speaker != null)
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppTheme.surface.withValues(alpha: 0.6),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: AppTheme.border),
                    ),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 20,
                          backgroundColor: AppTheme.cyan.withValues(alpha: 0.2),
                          backgroundImage: (speaker.photoUrl != null && speaker.photoUrl!.isNotEmpty)
                              ? CachedNetworkImageProvider(speaker.photoUrl!)
                              : null,
                          child: (speaker.photoUrl == null || speaker.photoUrl!.isEmpty)
                              ? Text(speaker.name.substring(0, 1), style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.cyan))
                              : null,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(speaker.name, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppTheme.textPrimary)),
                              Text('${speaker.designation} • ${speaker.organization}', style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                // Live Progress Line
                const SizedBox(height: 16),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: provider.progressFraction,
                    backgroundColor: AppTheme.border,
                    color: isOvertime ? AppTheme.dangerRose : AppTheme.cyan,
                    minHeight: 6,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Stage Delay Alert Pill
          if (notifications.isNotEmpty && notifications.first.type == 'delay') ...[
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppTheme.warningAmber.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppTheme.warningAmber.withValues(alpha: 0.4)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.notification_important_rounded, color: AppTheme.warningAmber, size: 20),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      notifications.first.message,
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppTheme.warningAmber),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
          ],

          // Filter Chips
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'STAGE TIMELINE',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1.2, color: AppTheme.textSecondary),
              ),
              Row(
                children: [
                  _buildFilterChip('All', 'all'),
                  const SizedBox(width: 6),
                  _buildFilterChip('Live', 'live'),
                  const SizedBox(width: 6),
                  _buildFilterChip('Upcoming', 'upcoming'),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Agenda Items List
          if (filteredList.isEmpty)
            Container(
              padding: const EdgeInsets.all(32),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: AppTheme.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppTheme.border),
              ),
              child: const Text('No session items found for selected filter.', style: TextStyle(color: AppTheme.textMuted)),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: filteredList.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (context, index) {
                final item = filteredList[index];
                Color badgeColor = AppTheme.textMuted;
                if (item.isLive) badgeColor = AppTheme.liveGreen;
                if (item.isUpcoming) badgeColor = AppTheme.cyan;
                if (item.isDone) badgeColor = AppTheme.textMuted;

                return Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: item.isLive ? AppTheme.liveGreen.withValues(alpha: 0.08) : AppTheme.surface,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: item.isLive ? AppTheme.liveGreen.withValues(alpha: 0.5) : AppTheme.border,
                      width: item.isLive ? 1.5 : 1.0,
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 42,
                        height: 42,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: badgeColor.withValues(alpha: 0.15),
                        ),
                        child: Text(
                          '${item.order}',
                          style: TextStyle(fontWeight: FontWeight.bold, color: badgeColor, fontSize: 16),
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: badgeColor.withValues(alpha: 0.2),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    item.status.toUpperCase(),
                                    style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: badgeColor),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  '${item.duration} min • ${item.type.toUpperCase()}',
                                  style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Text(
                              item.title,
                              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, String val) {
    final isSelected = _selectedFilter == val;
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      selectedColor: AppTheme.cyan,
      backgroundColor: AppTheme.surface,
      labelStyle: TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.bold,
        color: isSelected ? Colors.black : AppTheme.textSecondary,
      ),
      onSelected: (_) => setState(() => _selectedFilter = val),
    );
  }

  Widget _buildSpeakersTab(EventProvider provider) {
    final speakers = provider.speakers;
    if (speakers.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(32),
        alignment: Alignment.center,
        child: const Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.mic_external_off_rounded, size: 54, color: AppTheme.textMuted),
            SizedBox(height: 12),
            Text('No Speakers Registered Yet', style: TextStyle(fontWeight: FontWeight.bold, color: AppTheme.textPrimary)),
            SizedBox(height: 6),
            Text('Keynote speakers will appear here once added by the organizer.', style: TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
          ],
        ),
      );
    }

    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.82,
        crossAxisSpacing: 14,
        mainAxisSpacing: 14,
      ),
      itemCount: speakers.length,
      itemBuilder: (context, index) {
        final spk = speakers[index];
        return GestureDetector(
          onTap: () => _showSpeakerDetailsModal(context, spk),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppTheme.surface,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: AppTheme.border),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircleAvatar(
                  radius: 34,
                  backgroundColor: AppTheme.cyan.withValues(alpha: 0.2),
                  backgroundImage: (spk.photoUrl != null && spk.photoUrl!.isNotEmpty)
                      ? CachedNetworkImageProvider(spk.photoUrl!)
                      : null,
                  child: (spk.photoUrl == null || spk.photoUrl!.isEmpty)
                      ? Text(spk.name.substring(0, 1), style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppTheme.cyan))
                      : null,
                ),
                const SizedBox(height: 12),
                Text(
                  spk.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
                ),
                const SizedBox(height: 4),
                Text(
                  spk.designation.isNotEmpty ? spk.designation : 'Keynote Speaker',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary),
                ),
                const SizedBox(height: 2),
                Text(
                  spk.organization,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 10, color: AppTheme.textMuted),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildQnaTab(EventProvider provider) {
    final questions = provider.qnaQuestions;
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(14),
          color: AppTheme.surface,
          child: Row(
            children: [
              const Icon(Icons.help_center_rounded, color: AppTheme.liveGreen, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  '${questions.length} Live Questions Submitted for Active Stage Session',
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.refresh_rounded, size: 18, color: AppTheme.cyan),
                onPressed: () => provider.fetchQnaQuestions(),
              ),
            ],
          ),
        ),
        Expanded(
          child: questions.isEmpty
              ? Container(
                  padding: const EdgeInsets.all(32),
                  alignment: Alignment.center,
                  child: const Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.question_answer_outlined, size: 48, color: AppTheme.textMuted),
                      SizedBox(height: 12),
                      Text('No Questions Yet', style: TextStyle(fontWeight: FontWeight.bold, color: AppTheme.textPrimary)),
                      SizedBox(height: 6),
                      Text('Tap "ASK SPEAKER" below to post the first question!', style: TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
                    ],
                  ),
                )
              : ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: questions.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final q = questions[index];
                    return Container(
                      padding: const EdgeInsets.all(16),
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
                              Row(
                                children: [
                                  const Icon(Icons.account_circle_rounded, color: AppTheme.cyan, size: 18),
                                  const SizedBox(width: 6),
                                  Text(
                                    q['authorName'] ?? 'Attendee',
                                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
                                  ),
                                ],
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(
                                  color: AppTheme.liveGreen.withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: const Text(
                                  'AUDIENCE QUESTION',
                                  style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: AppTheme.liveGreen),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          Text(
                            q['question'] ?? '',
                            style: const TextStyle(fontSize: 14, height: 1.4, color: AppTheme.textPrimary),
                          ),
                        ],
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }
}
