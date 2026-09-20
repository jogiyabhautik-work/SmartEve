import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_theme.dart';
import '../../models/event_model.dart';
import '../../models/agenda_item_model.dart';
import '../../models/anchor_dashboard_models.dart';
import '../../providers/event_provider.dart';
import '../../providers/anchor_provider.dart';
import '../../providers/checklist_provider.dart';
import '../anchor/anchor_teleprompter_screen.dart';
import 'widgets/countdown_chip.dart';
import 'widgets/event_info_tab.dart';
import 'widgets/speaker_lineup_tab.dart';
import 'widgets/agenda_overview_tab.dart';
import 'widgets/event_scripts_tab.dart';
import 'widgets/pre_event_checklist_tab.dart';

/// Anchor-facing Event Information screen with sticky header, 5 tabs
/// (Info / Speakers / Agenda / Checklist), and contextual bottom actions.
class EventPrepScreen extends StatefulWidget {
  final String eventId;
  final AnchorEventStatus status;
  final String? invitationId;
  final String organizerName;
  final String collegeName;

  const EventPrepScreen({
    super.key,
    required this.eventId,
    this.status = AnchorEventStatus.accepted,
    this.invitationId,
    this.organizerName = 'Event Organizer',
    this.collegeName = '',
  });

  @override
  State<EventPrepScreen> createState() => _EventPrepScreenState();
}

class _EventPrepScreenState extends State<EventPrepScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  late AnchorEventStatus _status;

  @override
  void initState() {
    super.initState();
    _status = widget.status;
    _tabController = TabController(length: 5, vsync: this);
    // Load data after first frame.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<EventProvider>().loadEvent(widget.eventId);
      context.read<ChecklistProvider>().loadForEvent(widget.eventId);
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  bool get _isLive => _status == AnchorEventStatus.active;

  // ---- Real-time change detection state ----
  String? _lastAgendaSig;
  Set<String> _lastSpeakerIds = {};
  bool _initialSyncDone = false;
  String? _pendingNotice;

  /// Compares the latest provider data against the last seen snapshot and
  /// surfaces a "Changes Detected" notice when the organizer pushes updates.
  void _detectRemoteChanges(EventProvider ep) {
    final agendaSig = ep.agenda
        .map((i) => '${i.id}|${i.title}|${i.startTime}|${i.endTime}|${i.status}')
        .join('~');
    final speakerIds = ep.speakers.map((s) => s.id).toSet();

    if (!_initialSyncDone) {
      // Wait until the first payload arrives before establishing a baseline.
      if (ep.agenda.isEmpty && ep.speakers.isEmpty) return;
      _initialSyncDone = true;
      _lastAgendaSig = agendaSig;
      _lastSpeakerIds = speakerIds;
      return;
    }

    final agendaChanged = _lastAgendaSig != agendaSig;
    final addedSpeakers =
        speakerIds.difference(_lastSpeakerIds).toList(growable: false);
    final speakersChanged = addedSpeakers.isNotEmpty ||
        _lastSpeakerIds.difference(speakerIds).isNotEmpty;

    if (!agendaChanged && !speakersChanged) return;

    if (speakersChanged && !agendaChanged && addedSpeakers.isNotEmpty) {
      final name = ep.speakers
          .firstWhere((s) => s.id == addedSpeakers.first,
              orElse: () => ep.speakers.first)
          .name;
      _pendingNotice = 'New speaker added: $name';
    } else if (speakersChanged && !agendaChanged) {
      _pendingNotice = 'Speaker lineup updated by organizer';
    } else {
      _pendingNotice = 'Changes detected — organizer updated the agenda';
    }

    _lastAgendaSig = agendaSig;
    _lastSpeakerIds = speakerIds;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || _pendingNotice == null) return;
      final message = _pendingNotice!;
      _pendingNotice = null;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.sync_rounded, size: 16, color: Colors.white),
              const SizedBox(width: 8),
              Expanded(child: Text(message)),
            ],
          ),
          backgroundColor: AppTheme.warning,
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 4),
          action: SnackBarAction(
            label: 'Refresh',
            textColor: Colors.white,
            onPressed: () => context.read<EventProvider>().loadEvent(widget.eventId),
          ),
        ),
      );
    });
  }

  bool get _eventTimeReached {
    final agenda = context.read<EventProvider>().agenda;
    if (agenda.isEmpty) return false;
    final sorted = [...agenda]..sort((a, b) => a.order - b.order);
    final start = DateTime.tryParse(sorted.first.startTime);
    if (start == null) return false;
    // Allow going live up to 15 minutes before the first session.
    return DateTime.now()
        .isAfter(start.subtract(const Duration(minutes: 15)));
  }

  Color get _statusColor {
    switch (_status) {
      case AnchorEventStatus.active:
        return AppTheme.success;
      case AnchorEventStatus.accepted:
        return AppTheme.primaryBlue;
      case AnchorEventStatus.invited:
        return AppTheme.warning;
      case AnchorEventStatus.completed:
        return AppTheme.textSecondary;
    }
  }

  @override
  Widget build(BuildContext context) {
    final eventProvider = context.watch<EventProvider>();
    final checklist = context.watch<ChecklistProvider>();
    final event = eventProvider.event;

    // Surface organizer-driven agenda / speaker changes as they arrive.
    _detectRemoteChanges(eventProvider);

    return Scaffold(
      backgroundColor: AppTheme.lightBackground,
      appBar: AppBar(
        backgroundColor: AppTheme.surface,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        title: const Text(
          'EVENT PREP',
          style: TextStyle(
            color: AppTheme.textPrimary,
            fontSize: 16,
            fontWeight: FontWeight.w800,
            letterSpacing: 1.5,
          ),
        ),
      ),
      body: event == null
          ? const Center(child: CircularProgressIndicator())
          : LayoutBuilder(
              builder: (context, constraints) {
                final width = constraints.maxWidth;
                if (width >= 1024) {
                  return _buildDesktopLayout(event, eventProvider, checklist);
                } else if (width >= 600) {
                  return _buildTabletLayout(event, eventProvider, checklist);
                }
                return _buildMobileLayout(event, eventProvider, checklist);
              },
            ),
      bottomNavigationBar: _buildBottomActions(eventProvider, checklist),
    );
  }
  // ---------------- STICKY HEADER ----------------

  Widget _buildHeader(EventModel event, List<AgendaItemModel> agenda) {
    DateTime? start;
    if (agenda.isNotEmpty) {
      final sorted = [...agenda]..sort((a, b) => a.order - b.order);
      start = DateTime.tryParse(sorted.first.startTime);
    }
    final showCountdown = start != null &&
        start.isAfter(DateTime.now()) &&
        start.difference(DateTime.now()).inHours < 1;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
        color: AppTheme.surface,
        border: Border(bottom: BorderSide(color: AppTheme.border)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  event.name,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: AppTheme.textPrimary,
                    height: 1.2,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              _statusBadge(),
            ],
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              _typeBadge(event.type),
              if (showCountdown)
                CountdownChip(targetTime: start, prefix: 'Live in '),
              if (_isLive)
                ElevatedButton.icon(
                  onPressed: _openTeleprompter,
                  icon: const Icon(Icons.play_arrow_rounded, size: 18),
                  label: const Text('GO LIVE'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.success,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 8),
                    textStyle: const TextStyle(
                        fontSize: 13, fontWeight: FontWeight.bold),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _typeBadge(String type) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: AppTheme.secondaryPurple.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
            color: AppTheme.secondaryPurple.withValues(alpha: 0.35)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.category_outlined,
              size: 13, color: AppTheme.secondaryPurple),
          const SizedBox(width: 5),
          Text(
            type,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: AppTheme.secondaryPurple,
            ),
          ),
        ],
      ),
    );
  }

  Widget _statusBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: _statusColor.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _statusColor.withValues(alpha: 0.4)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (_isLive)
            const Padding(
              padding: EdgeInsets.only(right: 5),
              child: Icon(Icons.circle, size: 7, color: AppTheme.success),
            ),
          Text(
            _status.label,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.6,
              color: _statusColor,
            ),
          ),
        ],
      ),
    );
  }

  // ---------------- LAYOUTS ----------------

  Widget _tabBar() {
    return Container(
      color: AppTheme.surface,
      child: TabBar(
        controller: _tabController,
        isScrollable: true,
        tabAlignment: TabAlignment.start,
        labelColor: AppTheme.primaryBlue,
        unselectedLabelColor: AppTheme.textSecondary,
        indicatorColor: AppTheme.primaryBlue,
        indicatorWeight: 2.5,
        labelStyle:
            const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
        tabs: const [
          Tab(text: 'Info'),
          Tab(text: 'Speakers'),
          Tab(text: 'Agenda'),
          Tab(text: 'Scripts'),
          Tab(text: 'Prep ✓'),
        ],
      ),
    );
  }

  Widget _tabView(EventModel event, EventProvider ep) {
    return TabBarView(
      controller: _tabController,
      children: [
        _scrollable(EventInfoTab(
          event: event,
          agenda: ep.agenda,
          organizerName: widget.organizerName,
          collegeName: widget.collegeName,
          onContactOrganizer: _showContactSheet,
        )),
        _scrollable(SpeakerLineupTab(speakers: ep.speakers, agenda: ep.agenda)),
        _scrollable(AgendaOverviewTab(agenda: ep.agenda, speakers: ep.speakers)),
        _scrollable(const EventScriptsTab()),
        _scrollable(const PreEventChecklistTab()),
      ],
    );
  }

  Widget _scrollable(Widget child) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: child,
    );
  }

  // Mobile: header + tabs + swipeable tab view
  Widget _buildMobileLayout(
      EventModel event, EventProvider ep, ChecklistProvider cl) {
    return Column(
      children: [
        _buildHeader(event, ep.agenda),
        _tabBar(),
        Expanded(child: _tabView(event, ep)),
      ],
    );
  }

  // Tablet: side-by-side — tabs (left, flex 3) + checklist (right, flex 2)
  Widget _buildTabletLayout(
      EventModel event, EventProvider ep, ChecklistProvider cl) {
    return Column(
      children: [
        _buildHeader(event, ep.agenda),
        Expanded(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                flex: 3,
                child: Column(
                  children: [
                    _tabBar(),
                    Expanded(
                      child: TabBarView(
                        controller: _tabController,
                        children: [
                          _scrollable(EventInfoTab(
                            event: event,
                            agenda: ep.agenda,
                            organizerName: widget.organizerName,
                            collegeName: widget.collegeName,
                            onContactOrganizer: _showContactSheet,
                          )),
                          _scrollable(SpeakerLineupTab(
                              speakers: ep.speakers, agenda: ep.agenda)),
                          _scrollable(AgendaOverviewTab(
                              agenda: ep.agenda, speakers: ep.speakers)),
                          _scrollable(const PreEventChecklistTab()),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const VerticalDivider(width: 1, color: AppTheme.border),
              Expanded(
                flex: 2,
                child: _scrollable(const PreEventChecklistTab()),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // Desktop: 2-column grid — tabs left, checklist pinned right
  Widget _buildDesktopLayout(
      EventModel event, EventProvider ep, ChecklistProvider cl) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          flex: 3,
          child: Column(
            children: [
              _buildHeader(event, ep.agenda),
              _tabBar(),
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    _scrollable(EventInfoTab(
                      event: event,
                      agenda: ep.agenda,
                      organizerName: widget.organizerName,
                      collegeName: widget.collegeName,
                      onContactOrganizer: _showContactSheet,
                    )),
                    _scrollable(SpeakerLineupTab(
                        speakers: ep.speakers, agenda: ep.agenda)),
                    _scrollable(AgendaOverviewTab(
                        agenda: ep.agenda, speakers: ep.speakers)),
                    _scrollable(const PreEventChecklistTab()),
                  ],
                ),
              ),
            ],
          ),
        ),
        const VerticalDivider(width: 1, color: AppTheme.border),
        SizedBox(
          width: 360,
          child: _scrollable(const PreEventChecklistTab()),
        ),
      ],
    );
  }

  // ---------------- BOTTOM ACTIONS ----------------

  Widget _buildBottomActions(EventProvider ep, ChecklistProvider cl) {
    final goLiveEnabled =
        _isLive || (cl.isAllComplete && _eventTimeReached);

    return SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
        decoration: const BoxDecoration(
          color: AppTheme.surface,
          border: Border(top: BorderSide(color: AppTheme.border)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: double.infinity,
              child: _primaryButton(goLiveEnabled),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _showContactSheet,
                    icon: const Icon(Icons.chat_bubble_outline_rounded,
                        size: 16),
                    label: const Text('Contact Organizer'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _showScriptChangeSheet,
                    icon: const Icon(Icons.edit_note_rounded, size: 18),
                    label: const Text('Request Script Change'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _primaryButton(bool goLiveEnabled) {
    if (_status == AnchorEventStatus.invited) {
      return ElevatedButton.icon(
        onPressed: _acceptEvent,
        icon: const Icon(Icons.check_circle_outline, size: 18),
        label: const Text('Accept Event'),
      );
    }
    if (_isLive || _eventTimeReached) {
      return ElevatedButton.icon(
        onPressed: goLiveEnabled ? _openTeleprompter : null,
        icon: const Icon(Icons.play_arrow_rounded, size: 20),
        label: Text(
          goLiveEnabled ? 'GO LIVE' : 'Complete checklist to Go Live',
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor:
              goLiveEnabled ? AppTheme.success : AppTheme.textMuted,
        ),
      );
    }
    return ElevatedButton.icon(
      onPressed: null,
      icon: const Icon(Icons.schedule, size: 18),
      label: const Text('Go Live (available at event time)'),
      style: ElevatedButton.styleFrom(
        backgroundColor: AppTheme.textMuted,
        disabledBackgroundColor: AppTheme.border,
        disabledForegroundColor: AppTheme.textSecondary,
      ),
    );
  }

  // ---------------- ACTIONS ----------------

  Future<void> _acceptEvent() async {
    final anchorProvider = context.read<AnchorProvider>();
    if (widget.invitationId != null) {
      await anchorProvider.acceptInvitation(widget.invitationId!);
    }
    setState(() => _status = AnchorEventStatus.accepted);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Event accepted! Organizer notified.'),
          backgroundColor: AppTheme.success,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  void _openTeleprompter() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const AnchorTeleprompterScreen()),
    );
  }

  InputDecoration _sheetFieldDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(color: AppTheme.textMuted),
      filled: true,
      fillColor: AppTheme.lightBackground,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppTheme.radiusButton),
        borderSide: const BorderSide(color: AppTheme.border),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppTheme.radiusButton),
        borderSide: const BorderSide(color: AppTheme.border),
      ),
    );
  }

  void _showContactSheet() {
    final controller = TextEditingController();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppTheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
          left: 20,
          right: 20,
          top: 20,
          bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Message ${widget.organizerName}',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppTheme.textPrimary,
              ),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: controller,
              maxLines: 4,
              decoration: _sheetFieldDecoration('Type your message…'),
            ),
            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Message sent to organizer'),
                      backgroundColor: AppTheme.primaryBlue,
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                },
                icon: const Icon(Icons.send_rounded, size: 16),
                label: const Text('Send Message'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showScriptChangeSheet() {
    final controller = TextEditingController();
    String scriptType = 'Opening';
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppTheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheetState) => Padding(
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 20,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Request Script Change',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textPrimary,
                ),
              ),
              const SizedBox(height: 14),
              DropdownButtonFormField<String>(
                initialValue: scriptType,
                decoration: InputDecoration(
                  labelText: 'Script',
                  filled: true,
                  fillColor: AppTheme.lightBackground,
                  border: OutlineInputBorder(
                    borderRadius:
                        BorderRadius.circular(AppTheme.radiusButton),
                  ),
                ),
                items: const [
                  DropdownMenuItem(
                      value: 'Opening', child: Text('Opening Script')),
                  DropdownMenuItem(
                      value: 'Speaker Intro',
                      child: Text('Speaker Introduction')),
                  DropdownMenuItem(
                      value: 'Transition', child: Text('Transition')),
                  DropdownMenuItem(
                      value: 'Closing', child: Text('Closing Script')),
                ],
                onChanged: (val) {
                  if (val != null) setSheetState(() => scriptType = val);
                },
              ),
              const SizedBox(height: 12),
              TextField(
                controller: controller,
                maxLines: 3,
                decoration:
                    _sheetFieldDecoration('Describe the change you need…'),
              ),
              const SizedBox(height: 14),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.pop(ctx);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                            'Change request sent for $scriptType script'),
                        backgroundColor: AppTheme.primaryBlue,
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  },
                  icon: const Icon(Icons.send_rounded, size: 16),
                  label: const Text('Submit Request'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

