import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../../../models/speaker_model.dart';
import '../../../models/agenda_item_model.dart';
import 'speaker_card.dart';

/// Tab 2: Speaker Lineup — speakers in order of appearance with sort control.
class SpeakerLineupTab extends StatefulWidget {
  final List<SpeakerModel> speakers;
  final List<AgendaItemModel> agenda;

  const SpeakerLineupTab({
    super.key,
    required this.speakers,
    required this.agenda,
  });

  @override
  State<SpeakerLineupTab> createState() => _SpeakerLineupTabState();
}

class _SpeakerLineupTabState extends State<SpeakerLineupTab> {
  String _sortBy = 'time'; // 'time' | 'name'

  /// Maps each speaker to their agenda session (first session they appear in).
  AgendaItemModel? _sessionFor(String speakerId) {
    for (final item in widget.agenda) {
      if (item.speakerIds.contains(speakerId)) return item;
    }
    return null;
  }

  List<SpeakerModel> get _sortedSpeakers {
    final list = [...widget.speakers];
    if (_sortBy == 'name') {
      list.sort((a, b) => a.name.compareTo(b.name));
    } else {
      list.sort((a, b) {
        final sa = _sessionFor(a.id);
        final sb = _sessionFor(b.id);
        final oa = sa?.order ?? 999;
        final ob = sb?.order ?? 999;
        return oa.compareTo(ob);
      });
    }
    return list;
  }

  @override
  Widget build(BuildContext context) {
    final speakers = _sortedSpeakers;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header row: count + sort dropdown
        Row(
          children: [
            Text(
              'SPEAKERS (${speakers.length})',
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w800,
                letterSpacing: 1.1,
                color: AppTheme.textMuted,
              ),
            ),
            const Spacer(),
            const Text('Sort by:',
                style: TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10),
              decoration: BoxDecoration(
                color: AppTheme.surface,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppTheme.border),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: _sortBy,
                  isDense: true,
                  style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textPrimary),
                  items: const [
                    DropdownMenuItem(value: 'time', child: Text('Time')),
                    DropdownMenuItem(value: 'name', child: Text('Name')),
                  ],
                  onChanged: (val) {
                    if (val != null) setState(() => _sortBy = val);
                  },
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        if (speakers.isEmpty)
          _emptyState()
        else
          ...speakers.map(
            (s) => SpeakerCard(speaker: s, session: _sessionFor(s.id)),
          ),
      ],
    );
  }

  Widget _emptyState() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(AppTheme.radiusCard),
        border: Border.all(color: AppTheme.border),
      ),
      child: const Column(
        children: [
          Icon(Icons.mic_off_outlined, size: 40, color: AppTheme.textMuted),
          SizedBox(height: 12),
          Text('No speakers announced yet',
              style: TextStyle(fontSize: 14, color: AppTheme.textSecondary)),
        ],
      ),
    );
  }
}
