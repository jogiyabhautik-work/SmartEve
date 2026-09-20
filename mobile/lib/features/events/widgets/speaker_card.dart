import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_theme.dart';
import '../../../models/speaker_model.dart';
import '../../../models/agenda_item_model.dart';

/// Vertical speaker card: avatar, name, designation, organization, expertise,
/// speaking slot, arrival status, and an expandable bio.
class SpeakerCard extends StatefulWidget {
  final SpeakerModel speaker;
  final AgendaItemModel? session;

  const SpeakerCard({
    super.key,
    required this.speaker,
    this.session,
  });

  @override
  State<SpeakerCard> createState() => _SpeakerCardState();
}

class _SpeakerCardState extends State<SpeakerCard> {
  bool _bioExpanded = false;

  Color get _statusColor {
    switch (widget.speaker.status) {
      case 'arrived':
        return AppTheme.success;
      case 'absent':
        return AppTheme.error;
      default:
        return AppTheme.warning;
    }
  }

  String get _statusLabel {
    switch (widget.speaker.status) {
      case 'arrived':
        return 'Arrived';
      case 'absent':
        return 'Absent';
      default:
        return 'Expected';
    }
  }

  String get _slotLabel {
    final session = widget.session;
    if (session == null) return 'Slot TBD';
    final start = DateTime.tryParse(session.startTime);
    if (start == null) return '${session.duration} min';
    return '${DateFormat('h:mm a').format(start.toLocal())} · ${session.duration} min';
  }

  String _initials(String name) {
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty) return '?';
    if (parts.length == 1) return parts.first.substring(0, 1).toUpperCase();
    return (parts.first.substring(0, 1) + parts.last.substring(0, 1))
        .toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final speaker = widget.speaker;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
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
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                radius: 28,
                backgroundColor: AppTheme.primaryBlue.withValues(alpha: 0.12),
                backgroundImage: speaker.photoUrl != null
                    ? CachedNetworkImageProvider(speaker.photoUrl!)
                    : null,
                child: speaker.photoUrl == null
                    ? Text(
                        _initials(speaker.name),
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.primaryBlue,
                        ),
                      )
                    : null,
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      speaker.name,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${speaker.designation}${speaker.organization.isNotEmpty ? " · ${speaker.organization}" : ""}',
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: _statusColor.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.circle, size: 7, color: _statusColor),
                          const SizedBox(width: 4),
                          Text(
                            _statusLabel,
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: _statusColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Divider(height: 1, color: AppTheme.border),
          const SizedBox(height: 12),
          Row(
            children: [
              const Icon(Icons.psychology_outlined,
                  size: 14, color: AppTheme.primaryBlue),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  speaker.topic.isNotEmpty ? speaker.topic : 'Expert speaker',
                  style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textPrimary),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              const Icon(Icons.access_time_rounded,
                  size: 14, color: AppTheme.textMuted),
              const SizedBox(width: 6),
              Text(
                _slotLabel,
                style: const TextStyle(
                    fontSize: 12, color: AppTheme.textSecondary),
              ),
            ],
          ),
          if (speaker.bio.isNotEmpty) ...[
            const SizedBox(height: 10),
            AnimatedCrossFade(
              firstChild: Text(
                speaker.bio,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                    fontSize: 12, color: AppTheme.textSecondary, height: 1.4),
              ),
              secondChild: Text(
                speaker.bio,
                style: const TextStyle(
                    fontSize: 12, color: AppTheme.textSecondary, height: 1.4),
              ),
              crossFadeState: _bioExpanded
                  ? CrossFadeState.showSecond
                  : CrossFadeState.showFirst,
              duration: const Duration(milliseconds: 250),
            ),
            GestureDetector(
              onTap: () => setState(() => _bioExpanded = !_bioExpanded),
              child: Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      _bioExpanded ? 'Show less' : 'View Bio',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.primaryBlue,
                      ),
                    ),
                    Icon(
                      _bioExpanded
                          ? Icons.keyboard_arrow_up_rounded
                          : Icons.keyboard_arrow_down_rounded,
                      size: 16,
                      color: AppTheme.primaryBlue,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

