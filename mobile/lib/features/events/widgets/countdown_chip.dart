import 'dart:async';
import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';

/// A self-ticking countdown chip that shows time remaining until [targetTime].
/// Ticks every second when under 1 hour, otherwise every minute.
class CountdownChip extends StatefulWidget {
  final DateTime targetTime;
  final String prefix;

  const CountdownChip({
    super.key,
    required this.targetTime,
    this.prefix = '',
  });

  @override
  State<CountdownChip> createState() => _CountdownChipState();
}

class _CountdownChipState extends State<CountdownChip> {
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _scheduleTick();
  }

  void _scheduleTick() {
    _timer?.cancel();
    final remaining = widget.targetTime.difference(DateTime.now());
    final interval = remaining.inHours < 1
        ? const Duration(seconds: 1)
        : const Duration(minutes: 1);
    _timer = Timer.periodic(interval, (_) {
      if (mounted) {
        setState(() {});
        _scheduleTick();
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  String get _label {
    final remaining = widget.targetTime.difference(DateTime.now());
    if (remaining.isNegative) return 'Starting now';
    final d = remaining.inDays;
    final h = remaining.inHours % 24;
    final m = remaining.inMinutes % 60;
    final s = remaining.inSeconds % 60;
    if (d > 0) return '${d}d ${h}h ${m}m';
    if (remaining.inHours > 0) return '${h}h ${m}m';
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final remaining = widget.targetTime.difference(DateTime.now());
    final isUrgent = remaining.inMinutes < 10 && !remaining.isNegative;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: isUrgent
            ? AppTheme.warning.withValues(alpha: 0.12)
            : AppTheme.primaryBlue.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isUrgent
              ? AppTheme.warning.withValues(alpha: 0.4)
              : AppTheme.primaryBlue.withValues(alpha: 0.25),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.timer_outlined,
            size: 14,
            color: isUrgent ? AppTheme.warning : AppTheme.primaryBlue,
          ),
          const SizedBox(width: 5),
          Text(
            '${widget.prefix}$_label',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: isUrgent ? AppTheme.warning : AppTheme.primaryBlue,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
        ],
      ),
    );
  }
}
