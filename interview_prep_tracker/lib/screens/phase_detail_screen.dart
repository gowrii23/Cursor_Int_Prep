import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/models.dart';
import '../providers/providers.dart';
import '../services/progress_calculator.dart';
import '../theme/app_theme.dart';
import 'topic_detail_screen.dart';

class PhaseDetailScreen extends ConsumerWidget {
  const PhaseDetailScreen({super.key, required this.phaseId});

  final String phaseId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return FutureBuilder(
      future: _load(ref),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }
        final data = snapshot.data!;
        final phase = data.$1;
        final topics = data.$2;
        final itemsByTopic = data.$3;

        return Scaffold(
          appBar: AppBar(title: Text(phase.name)),
          body: ListView.separated(
            padding: const EdgeInsets.all(20),
            itemCount: topics.length,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (context, index) {
              final topic = topics[index];
              final items = itemsByTopic[topic.id] ?? [];
              final score = ProgressCalculator.topicScore(items, topic.confidence);
              final completed = ProgressCalculator.countCompleted(items);

              return Card(
                child: InkWell(
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => TopicDetailScreen(topicId: topic.id),
                    ),
                  ),
                  borderRadius: BorderRadius.circular(16),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                topic.name,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                            if (topic.isCritical)
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(
                                  color: AppTheme.critical.withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Text(
                                  'CRITICAL',
                                  style: TextStyle(
                                    color: AppTheme.critical,
                                    fontSize: 10,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(
                          '$completed/${items.length} done · Weight ${topic.weight} · Confidence ${topic.confidence}/5',
                          style: TextStyle(color: Colors.white.withValues(alpha: 0.5), fontSize: 12),
                        ),
                        const SizedBox(height: 10),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: LinearProgressIndicator(
                            value: score,
                            minHeight: 4,
                            backgroundColor: Colors.white12,
                            color: AppTheme.accent,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }

  Future<(Phase, List<Topic>, Map<String, List<ChecklistItem>>)> _load(WidgetRef ref) async {
    final repo = ref.read(repositoryProvider);
    final phases = await repo.getPhases();
    final phase = phases.firstWhere((p) => p.id == phaseId);
    final topics = await repo.getTopicsForPhase(phaseId);
    final itemsByTopic = await repo.getItemsGroupedByTopic();
    return (phase, topics, itemsByTopic);
  }
}
