import 'models.dart';

enum StudyCardType {
  framework('framework'),
  concept('concept'),
  pattern('pattern'),
  problem('problem'),
  quiz('quiz'),
  cheat('cheat'),
  karat('karat');

  const StudyCardType(this.value);
  final String value;

  static StudyCardType fromValue(String value) {
    return StudyCardType.values.firstWhere(
      (t) => t.value == value,
      orElse: () => StudyCardType.concept,
    );
  }

  String get label {
    switch (this) {
      case StudyCardType.framework:
        return 'Framework';
      case StudyCardType.concept:
        return 'Concept';
      case StudyCardType.pattern:
        return 'Pattern';
      case StudyCardType.problem:
        return 'Problem';
      case StudyCardType.quiz:
        return 'Quiz';
      case StudyCardType.cheat:
        return 'Cheat Sheet';
      case StudyCardType.karat:
        return 'Karat Tip';
    }
  }
}

class StudyCard {
  const StudyCard({
    required this.id,
    required this.type,
    required this.title,
    required this.body,
    this.linkedItems = const [],
    this.readMinutes = 3,
  });

  final String id;
  final StudyCardType type;
  final String title;
  final String body;
  final List<String> linkedItems;
  final int readMinutes;

  factory StudyCard.fromJson(Map<String, dynamic> json) {
    return StudyCard(
      id: json['id'] as String,
      type: StudyCardType.fromValue(json['type'] as String? ?? 'concept'),
      title: json['title'] as String,
      body: json['body'] as String,
      linkedItems: (json['linkedItems'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          const [],
      readMinutes: json['readMinutes'] as int? ?? 3,
    );
  }
}

class TopicStudyContent {
  const TopicStudyContent({
    required this.topicId,
    required this.overview,
    required this.cards,
  });

  final String topicId;
  final String overview;
  final List<StudyCard> cards;

  factory TopicStudyContent.fromJson(String topicId, Map<String, dynamic> json) {
    final cards = (json['cards'] as List<dynamic>? ?? [])
        .map((c) => StudyCard.fromJson(c as Map<String, dynamic>))
        .toList();
    return TopicStudyContent(
      topicId: topicId,
      overview: json['overview'] as String? ?? '',
      cards: cards,
    );
  }

  List<StudyCard> cardsForItem(String itemTitle) {
    final linked = cards
        .where((c) => c.linkedItems.any((l) => itemTitle.contains(l) || l == itemTitle))
        .toList();
    return linked.isNotEmpty ? linked : cards;
  }
}

class MicroLesson {
  const MicroLesson({
    required this.id,
    required this.title,
    required this.body,
    required this.tag,
    this.readMinutes = 3,
  });

  final String id;
  final String title;
  final String body;
  final String tag;
  final int readMinutes;

  factory MicroLesson.fromJson(Map<String, dynamic> json) {
    return MicroLesson(
      id: json['id'] as String,
      title: json['title'] as String,
      body: json['body'] as String,
      tag: json['tag'] as String? ?? 'Tip',
      readMinutes: json['readMinutes'] as int? ?? 3,
    );
  }
}

class TodayRevision {
  const TodayRevision({
    required this.topic,
    required this.phase,
    required this.item,
    required this.reason,
    this.studyCard,
  });

  final Topic topic;
  final Phase phase;
  final ChecklistItem? item;
  final String reason;
  final StudyCard? studyCard;
}
