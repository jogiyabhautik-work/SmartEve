import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_theme.dart';
import '../../models/agenda_item_model.dart';
import '../../providers/event_provider.dart';

class AgendaScreen extends StatelessWidget {
  const AgendaScreen({super.key});

  String _formatTime(String isoString) {
    final dt = DateTime.tryParse(isoString);
    if (dt == null) return '--:--';
    return DateFormat('hh:mm a').format(dt);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Event Agenda'),
      ),
      body: Consumer<EventProvider>(
        builder: (context, provider, _) {
          final agenda = provider.agenda;

          if (agenda.isEmpty) {
            return const Center(
              child: Text(
                'No agenda items loaded.',
                style: TextStyle(color: AppTheme.textMuted),
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.all(20),
            itemCount: agenda.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final item = agenda[index];
              return _buildAgendaCard(context, item);
            },
          );
        },
      ),
    );
  }

  Widget _buildAgendaCard(BuildContext context, AgendaItemModel item) {
    Color statusColor = AppTheme.textMuted;
    String statusText = 'UPCOMING';

    if (item.isLive) {
      statusColor = AppTheme.liveGreen;
      statusText = 'LIVE NOW';
    } else if (item.isDone) {
      statusColor = AppTheme.primaryPurple;
      statusText = 'DONE';
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: item.isLive ? AppTheme.liveGreen : AppTheme.border,
          width: item.isLive ? 1.5 : 1.0,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '#${item.order} • ${item.type.toUpperCase()}',
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.2,
                  color: AppTheme.textMuted,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  statusText,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: statusColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            item.title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              const Icon(Icons.schedule_rounded, size: 14, color: AppTheme.cyan),
              const SizedBox(width: 6),
              Text(
                '${_formatTime(item.startTime)} - ${_formatTime(item.endTime)} (${item.duration} min)',
                style: const TextStyle(
                  fontSize: 12,
                  color: AppTheme.textSecondary,
                ),
              ),
              if (item.absorbable) ...[
                const SizedBox(width: 12),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppTheme.warningAmber.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: const Text(
                    'BUFFER BREAK',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.warningAmber,
                    ),
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
