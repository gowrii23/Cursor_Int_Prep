import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../providers/providers.dart';
import '../theme/app_theme.dart';
import '../widgets/phase_card.dart';
import '../widgets/focus_and_status.dart';
import '../widgets/study_widgets.dart';
import 'topic_detail_screen.dart';

class TodayScreen extends ConsumerWidget {
  const TodayScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final progressAsync = ref.watch(overallProgressProvider);
    final streakAsync = ref.watch(streakProvider);
    final focusAsync = ref.watch(todayFocusProvider);
    final revisionAsync = ref.watch(todayRevisionProvider);
    final microLesson = ref.watch(microLessonProvider);
    final planAsync = ref.watch(planProgressProvider);

    return progressAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Error: $e')),
      data: (progress) => streakAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (streak) => RefreshIndicator(
          onRefresh: () async => refreshData(ref),
          color: Theme.of(context).colorScheme.primary,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
            children: [
              Text(
                'Good ${_greeting()}',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
              ),
              const SizedBox(height: 4),
              Text(
                'Prep Learner · study, practice, revise',
                style: TextStyle(color: Colors.white.withValues(alpha: 0.5)),
              ),
              const SizedBox(height: 20),
              OverallProgressHeader(progress: progress, streak: streak),
              const SizedBox(height: 16),
              planAsync.when(
                loading: () => const SizedBox.shrink(),
                error: (_, __) => const SizedBox.shrink(),
                data: (planProgress) {
                  if (planProgress.week == null) return const SizedBox.shrink();
                  return Card(
                    child: InkWell(
                      onTap: () {},
                      borderRadius: BorderRadius.circular(16),
                      child: Padding(
                        padding: const EdgeInsets.all(14),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.06),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                'W${planProgress.currentWeek}',
                                style: const TextStyle(fontWeight: FontWeight.w700, color: AppTheme.accent),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    planProgress.week!.title,
                                    style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                                  ),
                                  if (planProgress.todayRhythm != null)
                                    Text(
                                      '${planProgress.todayRhythm!.primary} · ${planProgress.todayRhythm!.secondary}',
                                      style: TextStyle(color: Colors.white.withValues(alpha: 0.45), fontSize: 11),
                                    ),
                                ],
                              ),
                            ),
                            Text(
                              'Day ${planProgress.currentDay}/90',
                              style: TextStyle(color: Colors.white.withValues(alpha: 0.4), fontSize: 11),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(height: 12),
              focusAsync.when(
                loading: () => const SizedBox.shrink(),
                error: (_, __) => const SizedBox.shrink(),
                data: (focus) {
                  if (focus == null) {
                    return const Card(
                      child: Padding(
                        padding: EdgeInsets.all(20),
                        child: Text('All items complete! Time to review.'),
                      ),
                    );
                  }
                  return TodayFocusCard(
                    focus: focus,
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => TopicDetailScreen(
                          topicId: focus.topic.id,
                          initialTab: 0,
                          highlightItemId: focus.item.id,
                        ),
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(height: 16),
              revisionAsync.when(
                loading: () => const SizedBox.shrink(),
                error: (_, __) => const SizedBox.shrink(),
                data: (revision) {
                  if (revision == null) {
                    return Card(
                      child: Padding(
                        padding: const EdgeInsets.all(18),
                        child: Text(
                          'No revision due yet — keep learning!',
                          style: TextStyle(color: Colors.white.withValues(alpha: 0.55)),
                        ),
                      ),
                    );
                  }
                  return TodayRevisionCard(
                    revision: revision,
                    onShuffle: () async {
                      await ref.read(repositoryProvider).getTodayRevision(shuffle: true);
                      refreshData(ref);
                    },
                    onOpenTopic: () => Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => TopicDetailScreen(
                          topicId: revision.topic.id,
                          initialTab: revision.studyCard != null ? 0 : 1,
                          highlightItemId: revision.item?.id,
                        ),
                      ),
                    ),
                    onStudy: () async {
                      if (revision.studyCard == null) return;
                      await ref.read(repositoryProvider).markStudiedToday();
                      refreshData(ref);
                      if (!context.mounted) return;
                      await Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => StudyCardReader(card: revision.studyCard!),
                        ),
                      );
                    },
                  ).animate().fadeIn(delay: 100.ms).slideY(begin: 0.05, end: 0);
                },
              ),
              if (microLesson != null) ...[
                const SizedBox(height: 16),
                MicroLessonCard(
                  lesson: microLesson,
                  onTap: () async {
                    await ref.read(repositoryProvider).markStudiedToday();
                    refreshData(ref);
                    if (!context.mounted) return;
                    await Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => MicroLessonReader(lesson: microLesson),
                      ),
                    );
                  },
                ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.05, end: 0),
              ],
            ],
          ),
        ),
      ),
    );
  }

  String _greeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'morning';
    if (hour < 17) return 'afternoon';
    return 'evening';
  }
}
