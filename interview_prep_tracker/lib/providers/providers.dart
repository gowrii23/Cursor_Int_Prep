import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/database_helper.dart';
import '../data/prep_repository.dart';
import '../models/models.dart';

final databaseProvider = Provider<DatabaseHelper>((ref) => DatabaseHelper.instance);

final repositoryProvider = Provider<PrepRepository>((ref) {
  return PrepRepository(ref.watch(databaseProvider));
});

final initProvider = FutureProvider<void>((ref) async {
  await ref.watch(repositoryProvider).initialize();
});

final phaseProgressProvider = FutureProvider<List<PhaseProgress>>((ref) async {
  ref.watch(refreshProvider);
  return ref.watch(repositoryProvider).getPhaseProgressList();
});

final overallProgressProvider = FutureProvider<double>((ref) async {
  ref.watch(refreshProvider);
  return ref.watch(repositoryProvider).getOverallProgress();
});

final streakProvider = FutureProvider<StreakInfo>((ref) async {
  ref.watch(refreshProvider);
  return ref.watch(repositoryProvider).getStreakInfo();
});

final todayFocusProvider = FutureProvider<TodayFocus?>((ref) async {
  ref.watch(refreshProvider);
  return ref.watch(repositoryProvider).getTodayFocus();
});

final topicsNeedingReviewProvider = FutureProvider<List<Topic>>((ref) async {
  ref.watch(refreshProvider);
  return ref.watch(repositoryProvider).getTopicsNeedingReview();
});

final refreshProvider = StateProvider<int>((ref) => 0);

void refreshData(WidgetRef ref) {
  ref.read(refreshProvider.notifier).state++;
}

final reminderHourProvider = FutureProvider<int>((ref) async {
  return ref.watch(repositoryProvider).getReminderHour();
});
