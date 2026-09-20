import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../../models/agenda_item_model.dart';
import '../../../models/event_model.dart';
import '../../../providers/event_provider.dart';
import '../../dashboard/stagepilot_dashboard_screen.dart';
import 'agenda_add_screen.dart';
import 'speaker_add_screen.dart';
import '../../events/widgets/find_anchors_modal.dart';

class EventDetailScreen extends StatefulWidget {
  final EventModel event;

  const EventDetailScreen({super.key, required this.event});

  @override
  State<EventDetailScreen> createState() => _EventDetailScreenState();
}

class _EventDetailScreenState extends State<EventDetailScreen> {
  late EventModel _currentEvent;

  @override
  void initState() {
    super.initState();
    _currentEvent = widget.event;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = context.read<EventProvider>();
      provider.loadEvent(_currentEvent.id);
    });
  }

  void _togglePublishState() {
    final isPublished = _currentEvent.liveState.status == 'published';
    final newStatus = isPublished ? 'draft' : 'published';

    setState(() {
      _currentEvent = EventModel(
        id: _currentEvent.id,
        name: _currentEvent.name,
        type: _currentEvent.type,
        date: _currentEvent.date,
        venue: _currentEvent.venue,
        tone: _currentEvent.tone,
        description: _currentEvent.description,
        ownerId: _currentEvent.ownerId,
        joinCode: _currentEvent.joinCode,
        anchorIds: _currentEvent.anchorIds,
        liveState: LiveStateModel(status: newStatus),
        createdAt: _currentEvent.createdAt,
      );
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          newStatus == 'published'
              ? '🚀 Event published! Anchors can now join using code "${_currentEvent.joinCode}"'
              : '📝 Event set back to Draft mode.',
        ),
        backgroundColor: newStatus == 'published' ? AppTheme.liveGreen : AppTheme.warningAmber,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _openAddSession() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => const AgendaAddScreen(),
      ),
    );
  }

  void _openEditSession(AgendaItemModel item) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => AgendaAddScreen(itemToEdit: item),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<EventProvider>();
    final agendaList = provider.agenda;

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: Text(
          _currentEvent.name,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          overflow: TextOverflow.ellipsis,
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.share_rounded, color: AppTheme.primaryBlue),
            tooltip: 'Share Join Code',
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Copied Join Code "${_currentEvent.joinCode}" to clipboard!'),
                  backgroundColor: AppTheme.primaryBlue,
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Event Overview Banner
            _buildOverviewHeader(),
            const SizedBox(height: 20),

            // Main Action Buttons
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      provider.selectEvent(_currentEvent);
                      Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => const StagePilotDashboardScreen()),
                      );
                    },
                    icon: const Icon(Icons.play_arrow_rounded, color: Colors.white, size: 20),
                    label: const FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        'CONTROL ROOM',
                        style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 13),
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryBlue,
                      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _togglePublishState,
                    icon: Icon(
                      _currentEvent.liveState.status == 'published'
                          ? Icons.pause_circle_outline_rounded
                          : Icons.publish_rounded,
                      color: _currentEvent.liveState.status == 'published'
                          ? AppTheme.warningAmber
                          : AppTheme.liveGreen,
                      size: 20,
                    ),
                    label: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        _currentEvent.liveState.status == 'published' ? 'UNPUBLISH' : 'PUBLISH EVENT',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                          color: _currentEvent.liveState.status == 'published'
                              ? AppTheme.warningAmber
                              : AppTheme.liveGreen,
                        ),
                      ),
                    ),
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(
                        color: _currentEvent.liveState.status == 'published'
                            ? AppTheme.warningAmber
                            : AppTheme.liveGreen,
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 28),

            // STAGE TIMELINE & AGENDA BUILDER SECTION
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'STAGE TIMELINE & AGENDA',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.2,
                          color: AppTheme.textSecondary,
                        ),
                      ),
                      SizedBox(height: 2),
                      Text(
                        'Live session sequence synced with Neon DB',
                        style: TextStyle(fontSize: 11, color: AppTheme.textMuted),
                      ),
                    ],
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: _openAddSession,
                  icon: const Icon(Icons.add_rounded, size: 18, color: Colors.white),
                  label: const Text('Add Session', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryBlue,
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),

            if (agendaList.isEmpty)
              _buildEmptyAgendaCard()
            else
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: agendaList.length,
                separatorBuilder: (_, __) => const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  final item = agendaList[index];
                  return _buildAgendaItemTile(context, provider, item, index, agendaList.length);
                },
              ),

            const SizedBox(height: 28),

            // Modules Overview Cards
            const Text(
              'EVENT MANAGEMENT MODULES',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.2,
                color: AppTheme.textSecondary,
              ),
            ),
            const SizedBox(height: 14),

            // Speaker Roster
            _buildModuleCard(
              icon: Icons.record_voice_over_rounded,
              iconColor: AppTheme.liveGreen,
              title: 'Speaker & Guest Roster',
              subtitle: '${provider.speakers.length} speakers registered in Neon DB',
              badge: '${provider.speakers.length} Speakers',
              onTap: () async {
                await Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const SpeakerAddScreen()),
                );
                if (mounted) {
                  provider.fetchSpeakers(_currentEvent.id);
                }
              },
            ),
            const SizedBox(height: 12),

            // AI Script Studio
            _buildModuleCard(
              icon: Icons.psychology_rounded,
              iconColor: AppTheme.primaryPurple,
              title: 'AI Anchor Script Studio',
              subtitle: 'Tone: ${_currentEvent.tone}. Auto-generated intros & stage transitions ready.',
              badge: 'AI READY',
              onTap: () {
                provider.selectEvent(_currentEvent);
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const StagePilotDashboardScreen()),
                );
              },
            ),
            const SizedBox(height: 12),

            // Find & Invite Anchors
            _buildModuleCard(
              icon: Icons.person_search_rounded,
              iconColor: AppTheme.liveGreen,
              title: 'Find & Invite Stage Anchors',
              subtitle: 'Browse registered hosts in Neon DB & send stage event invitations',
              badge: 'EXPLORE TALENT',
              onTap: () {
                FindAnchorsModal.show(context, _currentEvent);
              },
            ),
            const SizedBox(height: 12),

            // Team & Anchors Code
            _buildModuleCard(
              icon: Icons.people_alt_rounded,
              iconColor: AppTheme.warningAmber,
              title: 'Anchors & Co-Organizers',
              subtitle: 'Share access code "${_currentEvent.joinCode}" with stage anchors',
              badge: 'ANCHOR CODE',
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Join Code "${_currentEvent.joinCode}" copied to share!'),
                    backgroundColor: AppTheme.primaryBlue,
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyAgendaCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.border, style: BorderStyle.solid),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppTheme.primaryBlue.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.event_note_rounded, size: 36, color: AppTheme.primaryBlue),
          ),
          const SizedBox(height: 14),
          const Text(
            'No Stage Agenda Sessions Yet',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
          ),
          const SizedBox(height: 6),
          const Text(
            'Build your stage timeline by adding keynote speeches, presentations, and absorbable tea breaks.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 13, color: AppTheme.textSecondary, height: 1.3),
          ),
          const SizedBox(height: 18),
          OutlinedButton.icon(
            onPressed: _openAddSession,
            icon: const Icon(Icons.add_rounded, color: AppTheme.primaryBlue),
            label: const Text('ADD FIRST SESSION', style: TextStyle(fontWeight: FontWeight.bold, color: AppTheme.primaryBlue)),
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: AppTheme.primaryBlue),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAgendaItemTile(BuildContext context, EventProvider provider, AgendaItemModel item, int index, int total) {
    Color typeColor = AppTheme.primaryBlue;
    if (item.type == 'keynote') typeColor = AppTheme.primaryPurple;
    if (item.type == 'break') typeColor = AppTheme.warningAmber;
    if (item.type == 'opening' || item.type == 'closing') typeColor = AppTheme.liveGreen;

    String plannedTimeStr = '';
    if (item.plannedStart.isNotEmpty) {
      final dt = DateTime.tryParse(item.plannedStart);
      if (dt != null) {
        final hour = dt.hour % 12 == 0 ? 12 : dt.hour % 12;
        final ampm = dt.hour >= 12 ? 'PM' : 'AM';
        final min = dt.minute.toString().padLeft(2, '0');
        plannedTimeStr = '$hour:$min $ampm';
      }
    }

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
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Order Badge
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: typeColor.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    '${index + 1}',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: typeColor),
                  ),
                ),
              ),
              const SizedBox(width: 12),

              // Title & Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: typeColor.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            item.type.toUpperCase(),
                            style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: typeColor),
                          ),
                        ),
                        if (item.absorbable) ...[
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppTheme.warningAmber.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              'BUFFER (${item.minDuration ?? 5}m min)',
                              style: const TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: AppTheme.warningAmber),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      item.title,
                      style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(Icons.timer_outlined, size: 14, color: AppTheme.textSecondary),
                        const SizedBox(width: 4),
                        Text('${item.duration} mins', style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
                        if (plannedTimeStr.isNotEmpty) ...[
                          const SizedBox(width: 12),
                          const Icon(Icons.access_time_rounded, size: 14, color: AppTheme.textSecondary),
                          const SizedBox(width: 4),
                          Text(plannedTimeStr, style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
                        ],
                      ],
                    ),
                  ],
                ),
              ),

              // Reorder & Action Controls
              Column(
                children: [
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (index > 0)
                        IconButton(
                          icon: const Icon(Icons.arrow_upward_rounded, size: 18, color: AppTheme.textSecondary),
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                          onPressed: () {
                            final list = List<AgendaItemModel>.from(provider.agenda);
                            final temp = list[index];
                            list[index] = list[index - 1];
                            list[index - 1] = temp;
                            provider.reorderAgenda(list);
                          },
                        ),
                      if (index < total - 1)
                        IconButton(
                          icon: const Icon(Icons.arrow_downward_rounded, size: 18, color: AppTheme.textSecondary),
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                          onPressed: () {
                            final list = List<AgendaItemModel>.from(provider.agenda);
                            final temp = list[index];
                            list[index] = list[index + 1];
                            list[index + 1] = temp;
                            provider.reorderAgenda(list);
                          },
                        ),
                    ],
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 10),
          const Divider(height: 1, color: AppTheme.border),
          const SizedBox(height: 8),

          // Actions Row (Edit, Delete)
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton.icon(
                onPressed: () => _openEditSession(item),
                icon: const Icon(Icons.edit_rounded, size: 15, color: AppTheme.primaryBlue),
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
                      title: const Text('Delete Session', style: TextStyle(fontWeight: FontWeight.bold)),
                      content: Text('Remove "${item.title}" from stage timeline in Neon DB?'),
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
                    await provider.deleteAgendaItem(item.id);
                  }
                },
                icon: const Icon(Icons.delete_outline_rounded, size: 15, color: AppTheme.dangerRose),
                label: const Text('Delete', style: TextStyle(fontSize: 12, color: AppTheme.dangerRose, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildOverviewHeader() {
    Color statusColor;
    String statusText;

    switch (_currentEvent.liveState.status) {
      case 'live':
        statusColor = AppTheme.liveGreen;
        statusText = 'STAGE LIVE';
        break;
      case 'published':
        statusColor = AppTheme.primaryBlue;
        statusText = 'PUBLISHED';
        break;
      default:
        statusColor = AppTheme.warningAmber;
        statusText = 'DRAFT MODE';
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
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
                      fontWeight: FontWeight.bold,
                      color: statusColor,
                      letterSpacing: 1,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Flexible(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryBlue.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    'Code: ${_currentEvent.joinCode}',
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.primaryBlue,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          Text(
            _currentEvent.name,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: AppTheme.textPrimary,
            ),
          ),
          if (_currentEvent.description.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              _currentEvent.description,
              style: const TextStyle(
                fontSize: 14,
                color: AppTheme.textSecondary,
                height: 1.4,
              ),
            ),
          ],
          const SizedBox(height: 16),
          const Divider(color: AppTheme.border),
          const SizedBox(height: 12),

          Row(
            children: [
              const Icon(Icons.category_rounded, size: 16, color: AppTheme.primaryBlue),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  _currentEvent.type,
                  style: const TextStyle(fontSize: 13, color: AppTheme.textSecondary, fontWeight: FontWeight.w600),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              const Icon(Icons.calendar_month_rounded, size: 16, color: AppTheme.primaryBlue),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  _currentEvent.date,
                  style: const TextStyle(fontSize: 13, color: AppTheme.textSecondary),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(Icons.location_on_rounded, size: 16, color: AppTheme.primaryBlue),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  _currentEvent.venue,
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

  Widget _buildModuleCard({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required String badge,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
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
                  color: iconColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: iconColor, size: 24),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
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
                        Flexible(
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: iconColor.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              badge,
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: iconColor,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              const Icon(Icons.chevron_right_rounded, color: AppTheme.textMuted),
            ],
          ),
        ),
      ),
    );
  }
}
