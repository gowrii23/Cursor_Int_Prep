import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/plan_models.dart';
import '../providers/providers.dart';
import '../services/content_service.dart';
import '../theme/app_theme.dart';
import 'topic_detail_screen.dart';

class PlanScreen extends ConsumerWidget {
  const PlanScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final planAsync = ref.watch(planProgressProvider);
    final reviewAsync = ref.watch(topicsNeedingReviewProvider);
    final plan = ref.watch(studyPlanProvider);

    return planAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Error: $e')),
      data: (progress) => ListView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
        children: [
          Text(
            plan?.title ?? '90-Day Plan',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 4),
          Text(
            plan?.profile ?? '',
            style: TextStyle(color: Colors.white.withValues(alpha: 0.5), fontSize: 13),
          ),
          const SizedBox(height: 16),
          _ProgressCard(progress: progress),
          if (progress.week != null) ...[
            const SizedBox(height: 16),
            _WeekCard(week: progress.week!, day: progress.currentDay),
          ],
          if (progress.todayRhythm != null) ...[
            const SizedBox(height: 16),
            _RhythmCard(rhythm: progress.todayRhythm!),
          ],
          const SizedBox(height: 20),
          const Text('Retention techniques', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
          const SizedBox(height: 10),
          ...(plan?.techniques ?? []).map((t) => _TechniqueTile(technique: t)),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Active recall deck', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
              Text(
                '${ref.watch(recallCardsProvider).length} cards',
                style: TextStyle(color: Colors.white.withValues(alpha: 0.45), fontSize: 12),
              ),
            ],
          ),
          const SizedBox(height: 10),
          _RecallDeckSection(
            cards: progress.week != null
                ? ContentService.instance.recallsForWeek(progress.week!)
                : ref.watch(recallCardsProvider),
          ),
          const SizedBox(height: 20),
          const Text('12-week roadmap', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
          const SizedBox(height: 10),
          ...(plan?.weeks ?? []).map((w) => _WeekListTile(
                week: w,
                isCurrent: w.week == progress.currentWeek,
                onTap: () => _showWeekDetail(context, w),
              )),
          const SizedBox(height: 20),
          const Text('Topics needing attention', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
          const SizedBox(height: 10),
          reviewAsync.when(
            loading: () => const CircularProgressIndicator(),
            error: (e, _) => Text('Error: $e'),
            data: (topics) {
              if (topics.isEmpty) {
                return const Card(
                  child: Padding(
                    padding: EdgeInsets.all(20),
                    child: Text('All topics look healthy.'),
                  ),
                );
              }
              return Column(
                children: topics.map((topic) {
                  return Card(
                    margin: const EdgeInsets.only(bottom: 10),
                    child: ListTile(
                      title: Text(topic.name),
                      subtitle: Text('Confidence ${topic.confidence}/5'),
                      trailing: Text('${topic.confidence}/5', style: const TextStyle(color: AppTheme.accent)),
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => TopicDetailScreen(topicId: topic.id)),
                      ),
                    ),
                  );
                }).toList(),
              );
            },
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: () async {
              final confirmed = await showDialog<bool>(
                context: context,
                builder: (ctx) => AlertDialog(
                  title: const Text('Restart 90-day plan?'),
                  content: const Text('This resets your plan start date to today. Progress checklist is unchanged.'),
                  actions: [
                    TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
                    FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Restart')),
                  ],
                ),
              );
              if (confirmed == true) {
                await ref.read(repositoryProvider).resetPlanStartDate();
                refreshData(ref);
              }
            },
            icon: const Icon(Icons.restart_alt, size: 18),
            label: const Text('Restart plan from today'),
          ),
        ],
      ),
    );
  }

  void _showWeekDetail(BuildContext context, PlanWeek week) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.surfaceHigh,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.65,
        minChildSize: 0.4,
        maxChildSize: 0.9,
        builder: (_, controller) => ListView(
          controller: controller,
          padding: const EdgeInsets.all(20),
          children: [
            Text('Week ${week.week} · Month ${week.month}', style: const TextStyle(color: AppTheme.accent)),
            const SizedBox(height: 8),
            Text(week.title, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700)),
            const SizedBox(height: 16),
            _DetailBlock('Targets', week.targets),
            _DetailBlock('Retention drill', week.retention),
            _DetailBlock('Exit criteria', week.exit),
            const SizedBox(height: 12),
            const Text('Topics this week', style: TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: week.topics.map((id) {
                return ActionChip(
                  label: Text(ContentService.instance.topicDisplayName(id)),
                  onPressed: () {
                    Navigator.pop(ctx);
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => TopicDetailScreen(topicId: id)),
                    );
                  },
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProgressCard extends StatelessWidget {
  const _ProgressCard({required this.progress});

  final PlanProgress progress;

  @override
  Widget build(BuildContext context) {
    final pct = progress.currentDay / 90.0;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Day ${progress.currentDay} of 90', style: const TextStyle(fontWeight: FontWeight.w600)),
                Text('Week ${progress.currentWeek}/12', style: const TextStyle(color: AppTheme.accent)),
              ],
            ),
            const SizedBox(height: 10),
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: LinearProgressIndicator(value: pct.clamp(0, 1), minHeight: 8, backgroundColor: Colors.white10),
            ),
          ],
        ),
      ),
    );
  }
}

class _WeekCard extends StatelessWidget {
  const _WeekCard({required this.week, required this.day});

  final PlanWeek week;
  final int day;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppTheme.accent.withValues(alpha: 0.35)),
        ),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('THIS WEEK · Week ${week.week}', style: const TextStyle(color: AppTheme.accent, fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 1)),
            const SizedBox(height: 8),
            Text(week.title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            Text(week.targets, style: TextStyle(color: Colors.white.withValues(alpha: 0.6), height: 1.4)),
            const SizedBox(height: 10),
            Text('Exit: ${week.exit}', style: const TextStyle(color: AppTheme.accentSecondary, fontSize: 12)),
          ],
        ),
      ),
    );
  }
}

class _RhythmCard extends StatelessWidget {
  const _RhythmCard({required this.rhythm});

  final DailyRhythm rhythm;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            const Icon(Icons.schedule, color: AppTheme.accentSecondary, size: 22),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Today · ${rhythm.day}', style: TextStyle(color: Colors.white.withValues(alpha: 0.5), fontSize: 12)),
                  Text(rhythm.primary, style: const TextStyle(fontWeight: FontWeight.w600)),
                  Text(rhythm.secondary, style: TextStyle(color: Colors.white.withValues(alpha: 0.45), fontSize: 12)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TechniqueTile extends StatelessWidget {
  const _TechniqueTile({required this.technique});

  final RetentionTechnique technique;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        dense: true,
        title: Text(technique.name, style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 14)),
        subtitle: Text('${technique.use} · ${technique.how}', style: const TextStyle(fontSize: 12)),
      ),
    );
  }
}

class _WeekListTile extends StatelessWidget {
  const _WeekListTile({required this.week, required this.isCurrent, required this.onTap});

  final PlanWeek week;
  final bool isCurrent;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: isCurrent ? AppTheme.accent.withValues(alpha: 0.5) : Colors.transparent,
        ),
      ),
      child: ListTile(
        onTap: onTap,
        leading: CircleAvatar(
          backgroundColor: isCurrent ? AppTheme.accent.withValues(alpha: 0.2) : Colors.white10,
          child: Text('${week.week}', style: TextStyle(color: isCurrent ? AppTheme.accent : Colors.white54, fontSize: 13)),
        ),
        title: Text(week.title, style: TextStyle(fontWeight: isCurrent ? FontWeight.w600 : FontWeight.w400)),
        subtitle: Text('Month ${week.month}', style: const TextStyle(fontSize: 11)),
        trailing: const Icon(Icons.chevron_right, color: Colors.white38),
      ),
    );
  }
}

class _DetailBlock extends StatelessWidget {
  const _DetailBlock(this.label, this.text);

  final String label;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
          const SizedBox(height: 4),
          Text(text, style: TextStyle(color: Colors.white.withValues(alpha: 0.65), height: 1.4)),
        ],
      ),
    );
  }
}

class _RecallDeckSection extends StatefulWidget {
  const _RecallDeckSection({required this.cards});

  final List<RecallCard> cards;

  @override
  State<_RecallDeckSection> createState() => _RecallDeckSectionState();
}

class _RecallDeckSectionState extends State<_RecallDeckSection> {
  int _index = 0;
  bool _revealed = false;

  @override
  Widget build(BuildContext context) {
    if (widget.cards.isEmpty) {
      return const Card(
        child: Padding(padding: EdgeInsets.all(16), child: Text('No recall cards for this week yet.')),
      );
    }
    final card = widget.cards[_index % widget.cards.length];
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(card.technique, style: const TextStyle(fontSize: 10, color: AppTheme.accentSecondary)),
                ),
                const Spacer(),
                Text('${_index % widget.cards.length + 1}/${widget.cards.length}', style: TextStyle(color: Colors.white.withValues(alpha: 0.4), fontSize: 12)),
              ],
            ),
            const SizedBox(height: 12),
            Text(card.question, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, height: 1.35)),
            if (_revealed) ...[
              const SizedBox(height: 14),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppTheme.accent.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppTheme.accent.withValues(alpha: 0.2)),
                ),
                child: Text(card.answer, style: TextStyle(color: Colors.white.withValues(alpha: 0.85), height: 1.45)),
              ),
            ],
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => setState(() => _revealed = !_revealed),
                    child: Text(_revealed ? 'Hide answer' : 'Reveal answer'),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  onPressed: () => setState(() {
                    _index = (_index + 1) % widget.cards.length;
                    _revealed = false;
                  }),
                  icon: const Icon(Icons.navigate_next),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
