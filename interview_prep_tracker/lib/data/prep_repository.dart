import '../data/database_helper.dart';
import '../models/models.dart';
import '../services/progress_calculator.dart';

class PrepRepository {
  PrepRepository(this._db);

  final DatabaseHelper _db;

  Future<void> initialize() async {
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

  Future<TodayFocus?> getTodayFocus() async {
    final phases = await _db.getPhases();
    final itemsByTopic = await getItemsGroupedByTopic();
    TodayFocus? best;

    for (final phase in phases) {
      final topics = await _db.getTopicsForPhase(phase.id);
      for (final topic in topics) {
        final items = itemsByTopic[topic.id] ?? [];
        for (final item in items) {
          if (item.status == ItemStatus.done) continue;

          final priority = _focusPriority(item, topic);
          if (best == null || priority > _focusPriority(best.item, best.topic)) {
            best = TodayFocus(
              item: item,
              topic: topic,
              phase: phase,
              reason: _focusReason(item, topic),
            );
          }
        }
      }
    }
    return best;
  }

  double _focusPriority(ChecklistItem item, Topic topic) {
    final statusBoost = item.status == ItemStatus.needsRevision
        ? 3.0
        : item.status == ItemStatus.inProgress
            ? 2.0
            : 1.0;
    final criticalBoost = topic.isCritical ? 2.0 : 1.0;
    final confidencePenalty = (6 - topic.confidence) / 5.0;
    return topic.weight * statusBoost * criticalBoost * confidencePenalty;
  }

  String _focusReason(ChecklistItem item, Topic topic) {
    if (item.status == ItemStatus.needsRevision) {
      return 'Needs revision — confidence may be fading';
    }
    if (topic.isCritical) {
      return 'Critical for Principal role';
    }
    if (topic.confidence <= 2) {
      return 'Low confidence — prioritize practice';
    }
    if (item.status == ItemStatus.inProgress) {
      return 'Already in progress — finish strong';
    }
    return 'Next high-priority item';
  }

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
