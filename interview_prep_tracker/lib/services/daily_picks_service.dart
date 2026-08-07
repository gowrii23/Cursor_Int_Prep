import 'dart:math';

import '../data/database_helper.dart';
import '../models/models.dart';
import '../models/study_models.dart';
import 'content_service.dart';

class DailyPicksService {
  DailyPicksService(this._db);

  final DatabaseHelper _db;

  String _dateKey(DateTime dt) =>
      '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}';

  int _daySeed(DateTime dt) => dt.year * 10000 + dt.month * 100 + dt.day;

  Future<TodayFocus?> getDailyFocus(
    Future<List<TodayFocus>> Function() computeCandidates,
  ) async {
    final today = _dateKey(DateTime.now());
    final savedDate = await _db.getSetting('daily_focus_date');
    final savedItemId = await _db.getSetting('daily_focus_item_id');

    if (savedDate == today && savedItemId != null) {
      final itemId = int.tryParse(savedItemId);
      if (itemId != null) {
        final restored = await _restoreFocus(itemId);
        if (restored != null) return restored;
      }
    }

    final candidates = await _rankFocusCandidates(computeCandidates);
    if (candidates.isEmpty) return null;

    final pick = candidates.first;
    await _db.setSetting('daily_focus_date', today);
    await _db.setSetting('daily_focus_item_id', pick.item.id.toString());
    return pick;
  }

  Future<List<TodayFocus>> _rankFocusCandidates(
    Future<List<TodayFocus>> Function() computeAll,
  ) async {
    final all = await computeAll();
    all.sort((a, b) => _focusScore(b).compareTo(_focusScore(a)));
    return all.take(5).toList();
  }

  double _focusScore(TodayFocus f) {
    final statusBoost = f.item.status == ItemStatus.needsRevision
        ? 3.0
        : f.item.status == ItemStatus.inProgress
            ? 2.0
            : 1.0;
    final criticalBoost = f.topic.isCritical ? 2.0 : 1.0;
    final confidencePenalty = (6 - f.topic.confidence) / 5.0;
    return f.topic.weight * statusBoost * criticalBoost * confidencePenalty;
  }

  Future<TodayFocus?> _restoreFocus(int itemId) async {
    final item = await _db.getItem(itemId);
    if (item == null || item.status == ItemStatus.done) return null;
    final topic = await _db.getTopic(item.topicId);
    if (topic == null) return null;
    final phases = await _db.getPhases();
    final phase = phases.where((p) => p.id == topic.phaseId).firstOrNull;
    if (phase == null) return null;
    return TodayFocus(
      item: item,
      topic: topic,
      phase: phase,
      reason: 'Your focus for today — finish strong',
    );
  }

  Future<TodayRevision?> getDailyRevision({bool shuffle = false}) async {
    final today = _dateKey(DateTime.now());
    if (!shuffle) {
      final savedDate = await _db.getSetting('daily_revision_date');
      final savedTopicId = await _db.getSetting('daily_revision_topic_id');
      final savedItemId = await _db.getSetting('daily_revision_item_id');
      if (savedDate == today && savedTopicId != null) {
        final restored = await _restoreRevision(
          savedTopicId,
          int.tryParse(savedItemId ?? ''),
        );
        if (restored != null) return restored;
      }
    }

    final pool = await _buildRevisionPool();
    if (pool.isEmpty) return null;

    final rng = shuffle
        ? Random()
        : Random(_daySeed(DateTime.now()) + 7919);
    final pick = pool[rng.nextInt(pool.length)];

    await _db.setSetting('daily_revision_date', today);
    await _db.setSetting('daily_revision_topic_id', pick.topic.id);
    await _db.setSetting(
      'daily_revision_item_id',
      pick.item?.id.toString() ?? '',
    );
    return pick;
  }

  Future<TodayRevision?> _restoreRevision(String topicId, int? itemId) async {
    final topic = await _db.getTopic(topicId);
    if (topic == null) return null;
    final phases = await _db.getPhases();
    final phase = phases.where((p) => p.id == topic.phaseId).firstOrNull;
    if (phase == null) return null;

    ChecklistItem? item;
    if (itemId != null) {
      item = await _db.getItem(itemId);
    }
    item ??= (await _db.getItemsForTopic(topicId))
        .where((i) => i.status == ItemStatus.done || i.status == ItemStatus.needsRevision)
        .firstOrNull;

    final content = ContentService.instance.getTopicContent(topicId);
    StudyCard? card;
    if (item != null) {
      card = content?.cardsForItem(item.title).firstOrNull;
    }
    card ??= content?.cards.firstOrNull;

    return TodayRevision(
      topic: topic,
      phase: phase,
      item: item,
      reason: 'Scheduled revision for today',
      studyCard: card,
    );
  }

  Future<List<TodayRevision>> _buildRevisionPool() async {
    final pool = <TodayRevision>[];
    final now = DateTime.now();
    final phases = await _db.getPhases();
    final content = ContentService.instance;

    for (final phase in phases) {
      final topics = await _db.getTopicsForPhase(phase.id);
      for (final topic in topics) {
        final items = await _db.getItemsForTopic(topic.id);
        final dueItems = items.where((item) {
          if (item.status == ItemStatus.needsRevision) return true;
          if (item.status == ItemStatus.done) {
            if (item.nextReviewAt != null && !item.nextReviewAt!.isAfter(now)) {
              return true;
            }
            if (item.completedAt != null &&
                now.difference(item.completedAt!).inDays >= 5) {
              return true;
            }
          }
          return false;
        }).toList();

        if (dueItems.isNotEmpty) {
          for (final item in dueItems) {
            pool.add(TodayRevision(
              topic: topic,
              phase: phase,
              item: item,
              reason: item.status == ItemStatus.needsRevision
                  ? 'Marked needs revision'
                  : 'Spaced review due',
              studyCard: content.getTopicContent(topic.id)?.cardsForItem(item.title).firstOrNull,
            ));
          }
          continue;
        }

        if (topic.confidence <= 2 || _isStagnant(topic)) {
          final item = items
              .where((i) => i.status != ItemStatus.notStarted)
              .firstOrNull ??
              items.firstOrNull;
          pool.add(TodayRevision(
            topic: topic,
            phase: phase,
            item: item,
            reason: topic.confidence <= 2
                ? 'Low confidence — quick refresh'
                : 'No activity in 3+ days',
            studyCard: content.getTopicContent(topic.id)?.cards.firstOrNull,
          ));
        }
      }
    }
    return pool;
  }

  bool _isStagnant(Topic topic) {
    if (topic.lastActivityAt == null) return true;
    return DateTime.now().difference(topic.lastActivityAt!).inDays >= 3;
  }

  MicroLesson? getDailyMicroLesson() {
    final lessons = ContentService.instance.microLessons;
    if (lessons.isEmpty) return null;
    final index = _daySeed(DateTime.now()) % lessons.length;
    return lessons[index];
  }

  Future<List<TodayFocus>> computeAllFocusCandidates(
    Future<Map<String, List<ChecklistItem>>> itemsByTopicFuture,
  ) async {
    final phases = await _db.getPhases();
    final itemsByTopic = await itemsByTopicFuture;
    final results = <TodayFocus>[];

    for (final phase in phases) {
      final topics = await _db.getTopicsForPhase(phase.id);
      for (final topic in topics) {
        final items = itemsByTopic[topic.id] ?? [];
        for (final item in items) {
          if (item.status == ItemStatus.done) continue;
          results.add(TodayFocus(
            item: item,
            topic: topic,
            phase: phase,
            reason: _focusReason(item, topic),
          ));
        }
      }
    }
    return results;
  }

  String _focusReason(ChecklistItem item, Topic topic) {
    if (item.status == ItemStatus.needsRevision) {
      return 'Needs revision — confidence may be fading';
    }
    if (topic.isCritical) return 'Critical for Principal role';
    if (topic.confidence <= 2) return 'Low confidence — prioritize practice';
    if (item.status == ItemStatus.inProgress) {
      return 'Already in progress — finish strong';
    }
    return 'Next high-priority item';
  }
}

extension _FirstOrNull<E> on Iterable<E> {
  E? get firstOrNull {
    final it = iterator;
    if (it.moveNext()) return it.current;
    return null;
  }
}
