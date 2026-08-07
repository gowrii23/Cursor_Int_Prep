import 'dart:convert';

import 'package:flutter/services.dart';

import '../models/study_models.dart';

class ContentService {
  ContentService._();
  static final ContentService instance = ContentService._();

  Map<String, TopicStudyContent>? _topics;
  List<MicroLesson>? _microLessons;

  Future<void> load() async {
    if (_topics != null) return;
    final jsonStr = await rootBundle.loadString('assets/content/study_content.json');
    final data = json.decode(jsonStr) as Map<String, dynamic>;
    _topics = {};
    final topicsJson = data['topics'] as Map<String, dynamic>? ?? {};
    for (final entry in topicsJson.entries) {
      _topics![entry.key] = TopicStudyContent.fromJson(
        entry.key,
        entry.value as Map<String, dynamic>,
      );
    }
    _microLessons = (data['microLessons'] as List<dynamic>? ?? [])
        .map((m) => MicroLesson.fromJson(m as Map<String, dynamic>))
        .toList();
  }

  TopicStudyContent? getTopicContent(String topicId) => _topics?[topicId];

  List<TopicStudyContent> get allTopics =>
      _topics?.values.toList() ?? const [];

  List<MicroLesson> get microLessons => _microLessons ?? const [];

  MicroLesson? microLessonById(String id) {
    for (final m in microLessons) {
      if (m.id == id) return m;
    }
    return null;
  }

  StudyCard? findCard(String cardId) {
    for (final topic in allTopics) {
      for (final card in topic.cards) {
        if (card.id == cardId) return card;
      }
    }
    return null;
  }

  StudyCard? firstCardForTopic(String topicId) {
    final content = getTopicContent(topicId);
    if (content == null || content.cards.isEmpty) return null;
    return content.cards.first;
  }
}
