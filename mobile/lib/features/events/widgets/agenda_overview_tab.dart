import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../../../models/agenda_item_model.dart';
import '../../../models/speaker_model.dart';
import 'agenda_timeline_item.dart';

/// Tab 3: Agenda Overview — vertical timeline of all activities.
class AgendaOverviewTab extends StatelessWidget {
  final List<AgendaItemModel> agenda;
  final List<SpeakerModel> speakers;

  const AgendaOverviewTab({
    super.key,
    required this.agenda,
    required this.speakers,
  });

  SpeakerModel? _speakerFor(AgendaItemModel item) {
    if (item.speakerIds.isEmpty) return null;
    final id = item.speakerIds.first;
    final found = speakers.where((s) => s.id == id);
    return found.isNotEmpty ? found.first : null;
  }

  @override
  Widget build(BuildContext context) {
    final items = [...agenda]..sort((a, b) => a.order - b.order);

    if (items.isEmpty) {
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
            Icon(Icons.event_busy_outlined,
                size: 40, color: AppTheme.textMuted),
            SizedBox(height: 12),
            Text('Agenda not published yet',
                style:
                    TextStyle(fontSize: 14, color: AppTheme.textSecondary)),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.only(bottom: 14),
          child: Text(
            'EVENT TIMELINE',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.1,
              color: AppTheme.textMuted,
            ),
          ),
        ),
        for (var i = 0; i < items.length; i++)
          AgendaTimelineItem(
            item: items[i],
            speaker: _speakerFor(items[i]),
            isFirst: i == 0,
            isLast: i == items.length - 1,
          ),
      ],
    );
  }
}
