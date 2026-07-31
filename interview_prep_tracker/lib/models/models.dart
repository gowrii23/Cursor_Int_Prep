enum ItemStatus {
  notStarted('not_started'),
  inProgress('in_progress'),
  done('done'),
  needsRevision('needs_revision');

  const ItemStatus(this.value);
  final String value;

  static ItemStatus fromValue(String value) {
    return ItemStatus.values.firstWhere(
      (s) => s.value == value,
      orElse: () => ItemStatus.notStarted,
    );
  }

  String get label {
    switch (this) {
      case ItemStatus.notStarted:
        return 'Not Started';
      case ItemStatus.inProgress:
        return 'In Progress';
      case ItemStatus.done:
        return 'Done';
      case ItemStatus.needsRevision:
        return 'Needs Revision';
    }
  }
}

class Phase {
  const Phase({
    required this.id,
    required this.name,
    required this.icon,
    required this.sortOrder,
  });

  final String id;
  final String name;
  final String icon;
  final int sortOrder;

  factory Phase.fromMap(Map<String, dynamic> map) {
    return Phase(
      id: map['id'] as String,
      name: map['name'] as String,
      icon: map['icon'] as String? ?? 'school',
      sortOrder: map['sort_order'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toMap() => {
        'id': id,
        'name': name,
        'icon': icon,
        'sort_order': sortOrder,
      };
}

class Topic {
  const Topic({
    required this.id,
    required this.phaseId,
    required this.name,
    required this.weight,
    required this.isCritical,
    this.confidence = 3,
    this.lastReviewedAt,
    this.lastActivityAt,
  });

  final String id;
  final String phaseId;
  final String name;
  final int weight;
  final bool isCritical;
  final int confidence;
  final DateTime? lastReviewedAt;
  final DateTime? lastActivityAt;

  Topic copyWith({
    int? confidence,
    DateTime? lastReviewedAt,
    DateTime? lastActivityAt,
  }) {
    return Topic(
      id: id,
      phaseId: phaseId,
      name: name,
      weight: weight,
      isCritical: isCritical,
      confidence: confidence ?? this.confidence,
      lastReviewedAt: lastReviewedAt ?? this.lastReviewedAt,
      lastActivityAt: lastActivityAt ?? this.lastActivityAt,
    );
  }

  factory Topic.fromMap(Map<String, dynamic> map) {
    return Topic(
      id: map['id'] as String,
      phaseId: map['phase_id'] as String,
      name: map['name'] as String,
      weight: map['weight'] as int? ?? 5,
      isCritical: (map['is_critical'] as int? ?? 0) == 1,
      confidence: map['confidence'] as int? ?? 3,
      lastReviewedAt: map['last_reviewed_at'] != null
          ? DateTime.parse(map['last_reviewed_at'] as String)
          : null,
      lastActivityAt: map['last_activity_at'] != null
          ? DateTime.parse(map['last_activity_at'] as String)
          : null,
    );
  }

  Map<String, dynamic> toMap() => {
        'id': id,
        'phase_id': phaseId,
        'name': name,
        'weight': weight,
        'is_critical': isCritical ? 1 : 0,
        'confidence': confidence,
        'last_reviewed_at': lastReviewedAt?.toIso8601String(),
        'last_activity_at': lastActivityAt?.toIso8601String(),
      };
}

class ChecklistItem {
  const ChecklistItem({
    required this.id,
    required this.topicId,
    required this.title,
    required this.status,
    required this.practiceTarget,
    required this.practiceDone,
    this.notes,
    this.nextReviewAt,
    this.completedAt,
    this.sortOrder = 0,
  });

  final int id;
  final String topicId;
  final String title;
  final ItemStatus status;
  final int practiceTarget;
  final int practiceDone;
  final String? notes;
  final DateTime? nextReviewAt;
  final DateTime? completedAt;
  final int sortOrder;

  ChecklistItem copyWith({
    ItemStatus? status,
    int? practiceDone,
    String? notes,
    DateTime? nextReviewAt,
    DateTime? completedAt,
    bool clearNotes = false,
  }) {
    return ChecklistItem(
      id: id,
      topicId: topicId,
      title: title,
      status: status ?? this.status,
      practiceTarget: practiceTarget,
      practiceDone: practiceDone ?? this.practiceDone,
      notes: clearNotes ? null : (notes ?? this.notes),
      nextReviewAt: nextReviewAt ?? this.nextReviewAt,
      completedAt: completedAt ?? this.completedAt,
      sortOrder: sortOrder,
    );
  }

  factory ChecklistItem.fromMap(Map<String, dynamic> map) {
    return ChecklistItem(
      id: map['id'] as int,
      topicId: map['topic_id'] as String,
      title: map['title'] as String,
      status: ItemStatus.fromValue(map['status'] as String? ?? 'not_started'),
      practiceTarget: map['practice_target'] as int? ?? 1,
      practiceDone: map['practice_done'] as int? ?? 0,
      notes: map['notes'] as String?,
      nextReviewAt: map['next_review_at'] != null
          ? DateTime.parse(map['next_review_at'] as String)
          : null,
      completedAt: map['completed_at'] != null
          ? DateTime.parse(map['completed_at'] as String)
          : null,
      sortOrder: map['sort_order'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toMap() => {
        'id': id,
        'topic_id': topicId,
        'title': title,
        'status': status.value,
        'practice_target': practiceTarget,
        'practice_done': practiceDone,
        'notes': notes,
        'next_review_at': nextReviewAt?.toIso8601String(),
        'completed_at': completedAt?.toIso8601String(),
        'sort_order': sortOrder,
      };
}

class PhaseProgress {
  const PhaseProgress({
    required this.phase,
    required this.progress,
    required this.topicCount,
    required this.completedItems,
    required this.totalItems,
  });

  final Phase phase;
  final double progress;
  final int topicCount;
  final int completedItems;
  final int totalItems;
}

class TodayFocus {
  const TodayFocus({
    required this.item,
    required this.topic,
    required this.phase,
    required this.reason,
  });

  final ChecklistItem item;
  final Topic topic;
  final Phase phase;
  final String reason;
}

class StreakInfo {
  const StreakInfo({
    required this.currentStreak,
    required this.longestStreak,
    required this.activeDates,
    required this.practicedToday,
  });

  final int currentStreak;
  final int longestStreak;
  final Set<String> activeDates;
  final bool practicedToday;
}
