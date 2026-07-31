import '../models/models.dart';

class ProgressCalculator {
  static double itemScore(ChecklistItem item, int topicConfidence) {
    final statusScore = switch (item.status) {
      ItemStatus.done => 1.0,
      ItemStatus.inProgress => 0.5,
      ItemStatus.needsRevision => 0.35,
      ItemStatus.notStarted => 0.0,
    };

    final practiceRatio = item.practiceTarget > 0
        ? (item.practiceDone / item.practiceTarget).clamp(0.0, 1.0)
        : 1.0;

    final confidenceFactor = topicConfidence / 5.0;

    return (statusScore * 0.5) + (practiceRatio * 0.3) + (confidenceFactor * 0.2);
  }

  static double topicScore(List<ChecklistItem> items, int confidence) {
    if (items.isEmpty) return 0;
    final total = items.fold<double>(
      0,
      (sum, item) => sum + itemScore(item, confidence),
    );
    return total / items.length;
  }

  static double phaseProgress(
    List<Topic> topics,
    Map<String, List<ChecklistItem>> itemsByTopic,
  ) {
    if (topics.isEmpty) return 0;

    var weightedSum = 0.0;
    var totalWeight = 0.0;

    for (final topic in topics) {
      final items = itemsByTopic[topic.id] ?? [];
      final weight = topic.weight.toDouble();
      weightedSum += topicScore(items, topic.confidence) * weight;
      totalWeight += weight;
    }

    return totalWeight > 0 ? weightedSum / totalWeight : 0;
  }

  static double overallProgress(
    List<Topic> allTopics,
    Map<String, List<ChecklistItem>> itemsByTopic,
  ) {
    return phaseProgress(allTopics, itemsByTopic);
  }

  static int countCompleted(List<ChecklistItem> items) {
    return items.where((i) => i.status == ItemStatus.done).length;
  }
}
