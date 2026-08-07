class RecallCard {
  const RecallCard({
    required this.id,
    required this.topicId,
    required this.question,
    required this.answer,
    required this.technique,
  });

  final String id;
  final String topicId;
  final String question;
  final String answer;
  final String technique;

  factory RecallCard.fromJson(Map<String, dynamic> json) {
    return RecallCard(
      id: json['id'] as String,
      topicId: json['topicId'] as String? ?? '',
      question: json['question'] as String,
      answer: json['answer'] as String,
      technique: json['technique'] as String? ?? 'active_recall',
    );
  }
}

class PlanWeek {
  const PlanWeek({
    required this.week,
    required this.month,
    required this.title,
    required this.topics,
    required this.targets,
    required this.retention,
    required this.exit,
  });

  final int week;
  final int month;
  final String title;
  final List<String> topics;
  final String targets;
  final String retention;
  final String exit;

  factory PlanWeek.fromJson(Map<String, dynamic> json) {
    return PlanWeek(
      week: json['week'] as int,
      month: json['month'] as int,
      title: json['title'] as String,
      topics: (json['topics'] as List<dynamic>? ?? []).map((e) => e as String).toList(),
      targets: json['targets'] as String? ?? '',
      retention: json['retention'] as String? ?? '',
      exit: json['exit'] as String? ?? '',
    );
  }
}

class DailyRhythm {
  const DailyRhythm({
    required this.day,
    required this.primary,
    required this.secondary,
  });

  final String day;
  final String primary;
  final String secondary;

  factory DailyRhythm.fromJson(Map<String, dynamic> json) {
    return DailyRhythm(
      day: json['day'] as String,
      primary: json['primary'] as String,
      secondary: json['secondary'] as String,
    );
  }
}

class RetentionTechnique {
  const RetentionTechnique({
    required this.id,
    required this.name,
    required this.use,
    required this.how,
  });

  final String id;
  final String name;
  final String use;
  final String how;

  factory RetentionTechnique.fromJson(Map<String, dynamic> json) {
    return RetentionTechnique(
      id: json['id'] as String,
      name: json['name'] as String,
      use: json['use'] as String,
      how: json['how'] as String,
    );
  }
}

class StudyPlan {
  const StudyPlan({
    required this.title,
    required this.profile,
    required this.totalDays,
    required this.weeks,
    required this.dailyRhythm,
    required this.techniques,
    required this.sessionTemplate,
    required this.mockScorecard,
  });

  final String title;
  final String profile;
  final int totalDays;
  final List<PlanWeek> weeks;
  final List<DailyRhythm> dailyRhythm;
  final List<RetentionTechnique> techniques;
  final List<String> sessionTemplate;
  final List<String> mockScorecard;

  factory StudyPlan.fromJson(Map<String, dynamic> json) {
    return StudyPlan(
      title: json['title'] as String? ?? '90-Day Plan',
      profile: json['profile'] as String? ?? '',
      totalDays: json['totalDays'] as int? ?? 90,
      weeks: (json['weeks'] as List<dynamic>? ?? [])
          .map((w) => PlanWeek.fromJson(w as Map<String, dynamic>))
          .toList(),
      dailyRhythm: (json['dailyRhythm'] as List<dynamic>? ?? [])
          .map((d) => DailyRhythm.fromJson(d as Map<String, dynamic>))
          .toList(),
      techniques: (json['techniques'] as List<dynamic>? ?? [])
          .map((t) => RetentionTechnique.fromJson(t as Map<String, dynamic>))
          .toList(),
      sessionTemplate: (json['sessionTemplate'] as List<dynamic>? ?? [])
          .map((e) => e as String)
          .toList(),
      mockScorecard: (json['mockScorecard'] as List<dynamic>? ?? [])
          .map((e) => e as String)
          .toList(),
    );
  }

  PlanWeek? weekForNumber(int weekNumber) {
    for (final w in weeks) {
      if (w.week == weekNumber) return w;
    }
    return null;
  }
}

class PlanProgress {
  const PlanProgress({
    required this.startDate,
    required this.currentDay,
    required this.currentWeek,
    required this.week,
    required this.todayRhythm,
    required this.dayInWeek,
  });

  final DateTime startDate;
  final int currentDay;
  final int currentWeek;
  final PlanWeek? week;
  final DailyRhythm? todayRhythm;
  final int dayInWeek;
}
