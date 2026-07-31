import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../models/models.dart';
import '../theme/app_theme.dart';
import 'progress_ring.dart';

class PhaseCard extends StatelessWidget {
  const PhaseCard({
    super.key,
    required this.phaseProgress,
    required this.onTap,
  });

  final PhaseProgress phaseProgress;
  final VoidCallback onTap;

  IconData _iconFor(String icon) {
    switch (icon) {
      case 'code':
        return Icons.code_rounded;
      case 'architecture':
        return Icons.architecture_rounded;
      case 'cloud':
        return Icons.cloud_rounded;
      case 'memory':
        return Icons.memory_rounded;
      case 'psychology':
        return Icons.psychology_rounded;
      default:
        return Icons.school_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    final phase = phaseProgress.phase;

    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: AppTheme.accent.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(_iconFor(phase.icon), color: AppTheme.accent),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      phase.name,
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${phaseProgress.completedItems}/${phaseProgress.totalItems} items · ${phaseProgress.topicCount} topics',
                      style: TextStyle(color: Colors.white.withValues(alpha: 0.5), fontSize: 13),
                    ),
                    const SizedBox(height: 8),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: phaseProgress.progress,
                        minHeight: 4,
                        backgroundColor: Colors.white12,
                        color: AppTheme.accent,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Text(
                '${(phaseProgress.progress * 100).toStringAsFixed(0)}%',
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  color: AppTheme.accent,
                ),
              ),
              const Icon(Icons.chevron_right, color: Colors.white38),
            ],
          ),
        ),
      ),
    ).animate().fadeIn(duration: 300.ms).slideY(begin: 0.05, end: 0);
  }
}

class OverallProgressHeader extends StatelessWidget {
  const OverallProgressHeader({
    super.key,
    required this.progress,
    required this.streak,
  });

  final double progress;
  final StreakInfo streak;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppTheme.surfaceHigh,
            AppTheme.surfaceHigh.withValues(alpha: 0.6),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white10),
      ),
      child: Row(
        children: [
          ProgressRing(
            progress: progress,
            size: 100,
            strokeWidth: 8,
            label: 'Weighted',
            subtitle: 'overall',
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Interview Prep',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(Icons.local_fire_department, color: AppTheme.accentSecondary, size: 20),
                    const SizedBox(width: 6),
                    Text(
                      '${streak.currentStreak} day streak',
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  streak.practicedToday
                      ? 'Great work today — keep the chain alive!'
                      : 'Practice today to keep your streak',
                  style: TextStyle(color: Colors.white.withValues(alpha: 0.55), fontSize: 13),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
