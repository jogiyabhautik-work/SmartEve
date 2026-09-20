import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../../../models/event_model.dart';
import '../../../models/agenda_item_model.dart';
import 'countdown_chip.dart';

/// Tab 1: Event Information — date/time, organizer card, location,
/// expandable description, co-organizers, attendee count.
class EventInfoTab extends StatefulWidget {
  final EventModel event;
  final List<AgendaItemModel> agenda;
  final String organizerName;
  final String collegeName;
  final String? organizerAvatarUrl;
  final List<String> coOrganizers;
  final int? attendeeCount;
  final VoidCallback? onContactOrganizer;

  const EventInfoTab({
    super.key,
    required this.event,
    required this.agenda,
    this.organizerName = 'Event Organizer',
    this.collegeName = '',
    this.organizerAvatarUrl,
    this.coOrganizers = const [],
    this.attendeeCount,
    this.onContactOrganizer,
  });

  @override
  State<EventInfoTab> createState() => _EventInfoTabState();
}

class _EventInfoTabState extends State<EventInfoTab> {
  bool _descExpanded = false;

  DateTime? get _startTime {
    if (widget.agenda.isEmpty) return null;
    final sorted = [...widget.agenda]..sort((a, b) => a.order - b.order);
    return DateTime.tryParse(sorted.first.startTime);
  }

  DateTime? get _endTime {
    if (widget.agenda.isEmpty) return null;
    final sorted = [...widget.agenda]..sort((a, b) => a.order - b.order);
    return DateTime.tryParse(sorted.last.endTime);
  }

  String get _durationLabel {
    final s = _startTime;
    final e = _endTime;
    if (s == null || e == null) return 'TBD';
    final mins = e.difference(s).inMinutes;
    return '${mins ~/ 60}h ${(mins % 60).toString().padLeft(2, '0')}m';
  }

  String _fmtTime(DateTime? dt) {
    if (dt == null) return 'TBD';
    final local = dt.toLocal();
    final h = local.hour % 12 == 0 ? 12 : local.hour % 12;
    final ampm = local.hour < 12 ? 'AM' : 'PM';
    return '$h:${local.minute.toString().padLeft(2, '0')} $ampm';
  }

  @override
  Widget build(BuildContext context) {
    final start = _startTime;
    final showCountdown = start != null &&
        start.isAfter(DateTime.now()) &&
        start.difference(DateTime.now()).inHours < 24;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionTitle('Date & Time'),
        _buildDateTimeCard(showCountdown),
        const SizedBox(height: 20),
        _sectionTitle('Organizer'),
        _buildOrganizerCard(),
        const SizedBox(height: 20),
        _sectionTitle('Location'),
        _buildLocationCard(),
        const SizedBox(height: 20),
        _sectionTitle('About This Event'),
        _buildDescriptionCard(),
        if (widget.coOrganizers.isNotEmpty) ...[
          const SizedBox(height: 20),
          _sectionTitle('Co-organizers'),
          _buildCoOrganizersCard(),
        ],
        const SizedBox(height: 20),
        _sectionTitle('Attendance'),
        _buildAttendeeCard(),
      ],
    );
  }

  Widget _sectionTitle(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Text(
        text.toUpperCase(),
        style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w800,
          letterSpacing: 1.1,
          color: AppTheme.textMuted,
        ),
      ),
    );
  }

  Widget _card({required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(AppTheme.radiusCard),
        border: Border.all(color: AppTheme.border),
      ),
      child: child,
    );
  }
  Widget _buildDateTimeCard(bool showCountdown) {
    final start = _startTime;
    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.calendar_today_outlined,
                  size: 15, color: AppTheme.primaryBlue),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  widget.event.date,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textPrimary,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                DateTime.now().timeZoneName,
                style: const TextStyle(fontSize: 11, color: AppTheme.textMuted),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              _timeBlock('START', _fmtTime(start)),
              _timeDivider(),
              _timeBlock('DURATION', _durationLabel),
              _timeDivider(),
              _timeBlock('END', _fmtTime(_endTime)),
            ],
          ),
          if (showCountdown && start != null) ...[
            const SizedBox(height: 14),
            CountdownChip(targetTime: start, prefix: 'Starts in '),
          ],
        ],
      ),
    );
  }

  Widget _timeBlock(String label, String value) {
    return Expanded(
      child: Column(
        children: [
          Text(label,
              style: const TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.8,
                  color: AppTheme.textMuted)),
          const SizedBox(height: 4),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(value,
                style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textPrimary)),
          ),
        ],
      ),
    );
  }

  Widget _timeDivider() {
    return Container(width: 1, height: 34, color: AppTheme.border);
  }

  Widget _buildOrganizerCard() {
    return _card(
      child: Row(
        children: [
          CircleAvatar(
            radius: 24,
            backgroundColor: AppTheme.secondaryPurple.withValues(alpha: 0.12),
            backgroundImage: widget.organizerAvatarUrl != null
                ? NetworkImage(widget.organizerAvatarUrl!)
                : null,
            child: widget.organizerAvatarUrl == null
                ? Text(
                    widget.organizerName.isNotEmpty
                        ? widget.organizerName[0].toUpperCase()
                        : 'O',
                    style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.secondaryPurple),
                  )
                : null,
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(widget.organizerName,
                    style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textPrimary)),
                if (widget.collegeName.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      const Icon(Icons.school_outlined,
                          size: 13, color: AppTheme.textMuted),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(widget.collegeName,
                            style: const TextStyle(
                                fontSize: 12, color: AppTheme.textSecondary),
                            overflow: TextOverflow.ellipsis),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
          IconButton(
            onPressed: widget.onContactOrganizer,
            icon: const Icon(Icons.chat_bubble_outline_rounded,
                size: 20, color: AppTheme.primaryBlue),
            tooltip: 'Contact Organizer',
          ),
        ],
      ),
    );
  }

  Widget _buildLocationCard() {
    return _card(
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppTheme.primaryBlue.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.location_on_outlined,
                size: 20, color: AppTheme.primaryBlue),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              widget.event.venue,
              style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textPrimary),
            ),
          ),
          IconButton(
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Map view coming soon'),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
            icon: const Icon(Icons.map_outlined,
                size: 20, color: AppTheme.textMuted),
            tooltip: 'Open map',
          ),
        ],
      ),
    );
  }

  Widget _buildDescriptionCard() {
    final desc = widget.event.description.isNotEmpty
        ? widget.event.description
        : 'No description provided for this event yet.';
    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AnimatedCrossFade(
            firstChild: Text(
              desc,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                  fontSize: 13, color: AppTheme.textSecondary, height: 1.5),
            ),
            secondChild: Text(
              desc,
              style: const TextStyle(
                  fontSize: 13, color: AppTheme.textSecondary, height: 1.5),
            ),
            crossFadeState: _descExpanded
                ? CrossFadeState.showSecond
                : CrossFadeState.showFirst,
            duration: const Duration(milliseconds: 250),
          ),
          GestureDetector(
            onTap: () => setState(() => _descExpanded = !_descExpanded),
            child: Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                _descExpanded ? 'Show less' : 'Read more',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.primaryBlue,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCoOrganizersCard() {
    return _card(
      child: Row(
        children: [
          SizedBox(
            height: 36,
            width: (widget.coOrganizers.length * 26.0) + 12,
            child: Stack(
              children: [
                for (var i = 0; i < widget.coOrganizers.length; i++)
                  Positioned(
                    left: i * 26.0,
                    child: CircleAvatar(
                      radius: 18,
                      backgroundColor: Colors.white,
                      child: CircleAvatar(
                        radius: 16,
                        backgroundColor:
                            AppTheme.accentBlue.withValues(alpha: 0.15),
                        child: Text(
                          widget.coOrganizers[i].isNotEmpty
                              ? widget.coOrganizers[i][0].toUpperCase()
                              : '?',
                          style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.accentBlue),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              widget.coOrganizers.join(', '),
              style: const TextStyle(
                  fontSize: 12, color: AppTheme.textSecondary),
              overflow: TextOverflow.ellipsis,
              maxLines: 2,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAttendeeCard() {
    return _card(
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppTheme.success.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.groups_outlined,
                size: 20, color: AppTheme.success),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              widget.attendeeCount != null
                  ? '${widget.attendeeCount} attendees expected'
                  : 'Attendance count TBD',
              style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textPrimary),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

