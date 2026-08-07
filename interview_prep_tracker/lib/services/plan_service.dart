import '../data/database_helper.dart';
import '../models/plan_models.dart';
import 'content_service.dart';

class PlanService {
  PlanService(this._db);

  final DatabaseHelper _db;

  Future<DateTime> getPlanStartDate() async {
    final saved = await _db.getSetting('plan_start_date');
    if (saved != null) {
      final parsed = DateTime.tryParse(saved);
      if (parsed != null) return DateTime(parsed.year, parsed.month, parsed.day);
    }
    final today = DateTime.now();
    final start = DateTime(today.year, today.month, today.day);
    await _db.setSetting('plan_start_date', start.toIso8601String());
    return start;
  }

  Future<void> resetPlanStartDate() async {
    final today = DateTime.now();
    final start = DateTime(today.year, today.month, today.day);
    await _db.setSetting('plan_start_date', start.toIso8601String());
  }

  Future<PlanProgress> getProgress() async {
    final plan = ContentService.instance.plan;
    final start = await getPlanStartDate();
    final today = DateTime.now();
    final startDay = DateTime(start.year, start.month, start.day);
    final todayDay = DateTime(today.year, today.month, today.day);
    final dayIndex = todayDay.difference(startDay).inDays + 1;
    final clampedDay = dayIndex.clamp(1, plan?.totalDays ?? 90);
    final weekNumber = ((clampedDay - 1) ~/ 7) + 1;
    final week = plan?.weekForNumber(weekNumber.clamp(1, 12));
    final rhythm = _rhythmForWeekday(today.weekday, plan);
    return PlanProgress(
      startDate: startDay,
      currentDay: clampedDay,
      currentWeek: weekNumber.clamp(1, 12),
      week: week,
      todayRhythm: rhythm,
      dayInWeek: today.weekday,
    );
  }

  DailyRhythm? _rhythmForWeekday(int weekday, StudyPlan? plan) {
    if (plan == null || plan.dailyRhythm.isEmpty) return null;
    const names = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
    final name = names[(weekday - 1).clamp(0, 6)];
    for (final r in plan.dailyRhythm) {
      if (r.day == name) return r;
    }
    return plan.dailyRhythm.first;
  }
}
