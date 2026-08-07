import 'dart:convert';

import 'package:flutter/services.dart';

import '../models/plan_models.dart';
import '../models/study_models.dart';

class ContentService {
  ContentService._();
  static final ContentService instance = ContentService._();

  Map<String, TopicStudyContent>? _topics;
  List<MicroLesson>? _microLessons;
  StudyPlan? _plan;
  List<RecallCard>? _recallCards;

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

    final planStr = await rootBundle.loadString('assets/content/study_plan.json');
    _plan = StudyPlan.fromJson(json.decode(planStr) as Map<String, dynamic>);

    final recallStr = await rootBundle.loadString('assets/content/recall_cards.json');
    final recallData = json.decode(recallStr) as Map<String, dynamic>;
    _recallCards = (recallData['cards'] as List<dynamic>? ?? [])
        .map((c) => RecallCard.fromJson(c as Map<String, dynamic>))
        .toList();
  }

  TopicStudyContent? getTopicContent(String topicId) => _topics?[topicId];

  List<TopicStudyContent> get allTopics => _topics?.values.toList() ?? const [];

  List<MicroLesson> get microLessons => _microLessons ?? const [];

  StudyPlan? get plan => _plan;

  List<RecallCard> get recallCards => _recallCards ?? const [];

  List<RecallCard> recallsForTopic(String topicId) =>
      recallCards.where((c) => c.topicId == topicId).toList();

  List<RecallCard> recallsForWeek(PlanWeek week) {
    final ids = week.topics.toSet();
    return recallCards.where((c) => ids.contains(c.topicId)).toList();
  }

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

  String topicDisplayName(String topicId) {
    const names = {
      'arrays_strings': 'Arrays & Strings',
      'trees_graphs': 'Trees & Graphs',
      'dp': 'Dynamic Programming',
      'heaps': 'Heaps',
      'bit_manipulation': 'Bit Manipulation',
      'design_patterns': 'Design Patterns',
      'oop_solid': 'OOP & SOLID',
      'classic_lld': 'Classic LLD',
      'concurrency_lld': 'Concurrency LLD',
      'fundamentals': 'SD Fundamentals',
      'messaging': 'Messaging & Kafka',
      'classic_hld': 'Classic HLD',
      'scalability': 'Scalability',
      'jvm': 'JVM Internals',
      'spring': 'Spring Ecosystem',
      'distributed': 'Distributed Systems',
      'aws_platform': 'AWS Platform',
      'star_stories': 'STAR Stories',
      'principal_topics': 'Principal Topics',
      'company_research': 'Company Research',
    };
    return names[topicId] ?? topicId;
  }
}
