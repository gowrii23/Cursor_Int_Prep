import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../models/models.dart';
import '../theme/app_theme.dart';

class TodayFocusCard extends StatelessWidget {
  const TodayFocusCard({
    super.key,
    required this.focus,
    required this.onTap,
  });

  final TodayFocus focus;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppTheme.accent.withValues(alpha: 0.3)),
          ),
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppTheme.accent.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Text(
                      "TODAY'S FOCUS",
                      style: TextStyle(
                        color: AppTheme.accent,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.2,
                      ),
                    ),
                  ),
                  const Spacer(),
                  if (focus.topic.isCritical)
                    const Icon(Icons.priority_high, color: AppTheme.critical, size: 20),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                focus.item.title,
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600, height: 1.3),
              ),
              const SizedBox(height: 8),
              Text(
                '${focus.phase.name} · ${focus.topic.name}',
                style: TextStyle(color: Colors.white.withValues(alpha: 0.5), fontSize: 13),
              ),
              const SizedBox(height: 6),
              Text(
                focus.reason,
                style: const TextStyle(color: AppTheme.accentSecondary, fontSize: 12),
              ),
            ],
          ),
        ),
      ),
    ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.08, end: 0);
  }
}

class StatusChip extends StatelessWidget {
  const StatusChip({super.key, required this.status, this.compact = false});

  final ItemStatus status;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final color = AppTheme.statusColor(status.value);
    return Container(
      padding: EdgeInsets.symmetric(horizontal: compact ? 8 : 10, vertical: compact ? 3 : 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Text(
        compact ? _shortLabel(status) : status.label,
        style: TextStyle(color: color, fontSize: compact ? 10 : 12, fontWeight: FontWeight.w600),
      ),
    );
  }

  String _shortLabel(ItemStatus status) {
    switch (status) {
      case ItemStatus.notStarted:
        return 'New';
      case ItemStatus.inProgress:
        return 'Active';
      case ItemStatus.done:
        return 'Done';
      case ItemStatus.needsRevision:
        return 'Revise';
    }
  }
}

class ConfidenceSlider extends StatelessWidget {
  const ConfidenceSlider({
    super.key,
    required this.value,
    required this.onChanged,
  });

  final int value;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('Confidence', style: TextStyle(fontWeight: FontWeight.w600)),
            Text('$value / 5', style: const TextStyle(color: AppTheme.accent)),
          ],
        ),
        const SizedBox(height: 4),
        Slider(
          value: value.toDouble(),
          min: 1,
          max: 5,
          divisions: 4,
          label: '$value',
          onChanged: (v) {
            HapticFeedback.selectionClick();
            onChanged(v.round());
          },
        ),
        Text(
          _confidenceLabel(value),
          style: TextStyle(color: Colors.white.withValues(alpha: 0.5), fontSize: 12),
        ),
      ],
    );
  }

  String _confidenceLabel(int v) {
    switch (v) {
      case 1:
        return 'Shaky — needs heavy revision';
      case 2:
        return 'Uncertain — schedule practice';
      case 3:
        return 'Moderate — keep practicing';
      case 4:
        return 'Solid — maintain with reviews';
      case 5:
        return 'Mastered — light touch-ups only';
      default:
        return '';
    }
  }
}

class StreakHeatmap extends StatelessWidget {
  const StreakHeatmap({super.key, required this.activeDates});

  final Set<String> activeDates;

  @override
  Widget build(BuildContext context) {
    final today = DateTime.now();
    final days = List.generate(28, (i) => today.subtract(Duration(days: 27 - i)));

    return Wrap(
      spacing: 4,
      runSpacing: 4,
      children: days.map((day) {
        final key = '${day.year}-${day.month.toString().padLeft(2, '0')}-${day.day.toString().padLeft(2, '0')}';
        final active = activeDates.contains(key);
        final isToday = day.year == today.year && day.month == today.month && day.day == today.day;

        return Container(
          width: 14,
          height: 14,
          decoration: BoxDecoration(
            color: active ? AppTheme.accent : Colors.white10,
            borderRadius: BorderRadius.circular(3),
            border: isToday ? Border.all(color: AppTheme.accentSecondary, width: 1.5) : null,
          ),
        );
      }).toList(),
    );
  }
}
