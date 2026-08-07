import '../data/database_helper.dart';
import '../models/models.dart';
import '../models/plan_models.dart';
import '../models/study_models.dart';
import '../services/content_service.dart';
import '../services/daily_picks_service.dart';
import '../services/plan_service.dart';
import '../services/progress_calculator.dart';

class PrepRepository {
  PrepRepository(this._db)
      : _dailyPicks = DailyPicksService(_db),
        _planService = PlanService(_db);

  final DatabaseHelper _db;
  final DailyPicksService _dailyPicks;
  final PlanService _planService;

  Future<void> initialize() async {
    await ContentService.instance.load();
    await _db.seedFromAssets();
  }

  Future<List<Phase>> getPhases() => _db.getPhases();

  Future<List<Topic>> getTopicsForPhase(String phaseId) =>
      _db.getTopicsForPhase(phaseId);

  Future<Topic?> getTopic(String topicId) => _db.getTopic(topicId);

  Future<List<ChecklistItem>> getItemsForTopic(String topicId) =>
      _db.getItemsForTopic(topicId);

  Future<List<ChecklistItem>> getAllItems() => _db.getAllItems();

  Future<List<Topic>> getAllTopics() => _db.getAllTopics();

  TopicStudyContent? getStudyContent(String topicId) =>
      ContentService.instance.getTopicContent(topicId);

  Future<Map<String, List<ChecklistItem>>> getItemsGroupedByTopic() async {
    final items = await _db.getAllItems();
    final map = <String, List<ChecklistItem>>{};
    for (final item in items) {
      map.putIfAbsent(item.topicId, () => []).add(item);
    }
    return map;
  }

  Future<List<PhaseProgress>> getPhaseProgressList() async {
    final phases = await _db.getPhases();
    final itemsByTopic = await getItemsGroupedByTopic();
    final results = <PhaseProgress>[];

    for (final phase in phases) {
      final topics = await _db.getTopicsForPhase(phase.id);
      final progress = ProgressCalculator.phaseProgress(topics, itemsByTopic);
      final allItems = topics
          .expand<ChecklistItem>((t) => itemsByTopic[t.id] ?? const <ChecklistItem>[])
          .toList();
      results.add(PhaseProgress(
        phase: phase,
        progress: progress,
        topicCount: topics.length,
        completedItems: ProgressCalculator.countCompleted(allItems),
        totalItems: allItems.length,
      ));
    }
    return results;
  }

  Future<double> getOverallProgress() async {
    final topics = await _db.getAllTopics();
    final itemsByTopic = await getItemsGroupedByTopic();
    return ProgressCalculator.overallProgress(topics, itemsByTopic);
  }

  Future<StreakInfo> getStreakInfo() => _db.getStreakInfo();

  Future<void> markPracticedToday() => _db.recordStreakDay();

  Future<void> markStudiedToday() => _db.recordStreakDay();

  Future<TodayFocus?> getTodayFocus() {
    return _dailyPicks.getDailyFocus(() async {
      final candidates = await _dailyPicks.computeAllFocusCandidates(getItemsGroupedByTopic());
      return candidates;
    });
  }

  Future<TodayRevision?> getTodayRevision({bool shuffle = false}) =>
      _dailyPicks.getDailyRevision(shuffle: shuffle);

  MicroLesson? getMicroLesson() => _dailyPicks.getDailyMicroLesson();

  StudyPlan? getStudyPlan() => ContentService.instance.plan;

  List<RecallCard> getRecallCards() => ContentService.instance.recallCards;

  Future<PlanProgress> getPlanProgress() => _planService.getProgress();

  Future<void> resetPlanStartDate() => _planService.resetPlanStartDate();

  Future<void> updateItemStatus(int itemId, ItemStatus status) async {
    final item = await _db.getItem(itemId);
    if (item == null) return;

    DateTime? completedAt;
    DateTime? nextReview;

    if (status == ItemStatus.done) {
      completedAt = DateTime.now();
      nextReview = DateTime.now().add(const Duration(days: 5));
      await _db.recordStreakDay();
    } else if (status == ItemStatus.needsRevision) {
      nextReview = DateTime.now().add(const Duration(days: 2));
    }

    await _db.updateItem(item.copyWith(
      status: status,
      completedAt: completedAt,
      nextReviewAt: nextReview,
      practiceDone: status == ItemStatus.done
          ? item.practiceTarget.clamp(item.practiceDone, item.practiceTarget)
          : item.practiceDone,
    ));
  }

  Future<void> incrementPractice(int itemId) async {
    final item = await _db.getItem(itemId);
    if (item == null) return;
    final newDone = (item.practiceDone + 1).clamp(0, item.practiceTarget + 10);
    var status = item.status;
    if (status == ItemStatus.notStarted) status = ItemStatus.inProgress;
    if (newDone >= item.practiceTarget && status != ItemStatus.done) {
      status = ItemStatus.inProgress;
    }
    await _db.updateItem(item.copyWith(practiceDone: newDone, status: status));
    await _db.recordStreakDay();
  }

  Future<void> updateNotes(int itemId, String notes) async {
    final item = await _db.getItem(itemId);
    if (item == null) return;
    await _db.updateItem(
      item.copyWith(notes: notes.isEmpty ? null : notes, clearNotes: notes.isEmpty),
    );
  }

  Future<void> updateTopicConfidence(String topicId, int confidence) async {
    final topic = await _db.getTopic(topicId);
    if (topic == null) return;
    await _db.updateTopic(topic.copyWith(
      confidence: confidence.clamp(1, 5),
      lastReviewedAt: DateTime.now(),
    ));
  }

  Future<List<Topic>> getTopicsNeedingReview() async {
    final topics = await _db.getAllTopics();
    return topics.where((t) => t.confidence <= 2 || _isStagnant(t)).toList()
      ..sort((a, b) => a.confidence.compareTo(b.confidence));
  }

  bool _isStagnant(Topic topic) {
    if (topic.lastActivityAt == null) return true;
    return DateTime.now().difference(topic.lastActivityAt!).inDays >= 3;
  }

  Future<int> getReminderHour() async {
    final value = await _db.getSetting('reminder_hour');
    return int.tryParse(value ?? '') ?? 21;
  }

  Future<void> setReminderHour(int hour) =>
      _db.setSetting('reminder_hour', hour.toString());
}
