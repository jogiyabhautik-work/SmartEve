import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_theme.dart';
import '../../../models/agenda_item_model.dart';
import '../../../models/speaker_model.dart';

/// Vertical timeline row for the Agenda Overview tab.
class AgendaTimelineItem extends StatelessWidget {
  final AgendaItemModel item;
  final SpeakerModel? speaker;
  final bool isFirst;
  final bool isLast;

  const AgendaTimelineItem({
    super.key,
    required this.item,
    this.speaker,
    this.isFirst = false,
    this.isLast = false,
  });

  Color get _statusColor {
    switch (item.status) {
      case 'live':
      case 'in_progress':
        return AppTheme.success;
      case 'done':
      case 'completed':
        return AppTheme.primaryBlue;
      case 'delayed':
        return AppTheme.warning;
      case 'cancelled':
      case 'skipped':
        return AppTheme.error;
      default:
        return AppTheme.textMuted;
    }
  }

  String get _statusLabel {
    switch (item.status) {
      case 'live':
      case 'in_progress':
        return 'In Progress';
      case 'done':
      case 'completed':
        return 'Completed';
      case 'delayed':
        return 'Delayed';
      case 'cancelled':
        return 'Cancelled';
      case 'skipped':
        return 'Skipped';
      default:
        return 'Scheduled';
    }
  }

  IconData get _typeIcon {
    switch (item.type) {
      case 'opening':
        return Icons.waving_hand_outlined;
      case 'keynote':
      case 'talk':
      case 'speaker_session':
        return Icons.mic_none_rounded;
      case 'break':
        return Icons.coffee_outlined;
      case 'panel':
        return Icons.groups_outlined;
      case 'workshop':
        return Icons.build_outlined;
      case 'closing':
        return Icons.flag_outlined;
      default:
        return Icons.event_note_outlined;
    }
  }

  String _fmt(String iso) {
    final dt = DateTime.tryParse(iso);
    if (dt == null) return '--:--';
    return DateFormat('h:mm a').format(dt.toLocal());
  }
  @override
  Widget build(BuildContext context) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            width: 32,
            child: Column(
              children: [
                Expanded(
                  child: Container(
                    width: 2,
                    color: isFirst ? Colors.transparent : AppTheme.border,
                  ),
                ),
                Container(
                  width: 14,
                  height: 14,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: _statusColor,
                    border: Border.all(color: Colors.white, width: 2),
                    boxShadow: [
                      BoxShadow(
                        color: _statusColor.withValues(alpha: 0.3),
                        blurRadius: 4,
                      ),
                    ],
                  ),
                ),
                Expanded(
                  flex: 3,
                  child: Container(
                    width: 2,
                    color: isLast ? Colors.transparent : AppTheme.border,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Expanded(child: _buildCard()),
        ],
      ),
    );
  }

  Widget _buildCard() {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(AppTheme.radiusCard),
        border: Border.all(
          color: item.isLive
              ? AppTheme.success.withValues(alpha: 0.5)
              : AppTheme.border,
          width: item.isLive ? 1.5 : 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(_typeIcon, size: 15, color: AppTheme.primaryBlue),
              const SizedBox(width: 6),
              Text(
                '${_fmt(item.startTime)} – ${_fmt(item.endTime)}',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.primaryBlue,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: _statusColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  _statusLabel,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: _statusColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            item.title,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              const Icon(Icons.schedule, size: 13, color: AppTheme.textMuted),
              const SizedBox(width: 4),
              Text(
                '${item.duration} min',
                style: const TextStyle(
                    fontSize: 12, color: AppTheme.textSecondary),
              ),
              if (speaker != null) ...[
                const SizedBox(width: 14),
                const Icon(Icons.person_outline,
                    size: 13, color: AppTheme.textMuted),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    speaker!.name,
                    style: const TextStyle(
                        fontSize: 12, color: AppTheme.textSecondary),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

