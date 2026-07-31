import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/providers.dart';
import '../services/notification_service.dart';
import '../theme/app_theme.dart';
import 'topic_detail_screen.dart';

class ReviewScreen extends ConsumerWidget {
  const ReviewScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final reviewAsync = ref.watch(topicsNeedingReviewProvider);
    final reminderAsync = ref.watch(reminderHourProvider);

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
      children: [
        Text(
          'Weekly Review',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w700,
              ),
        ),
        const SizedBox(height: 6),
        Text(
          'Rate confidence and revisit weak areas',
          style: TextStyle(color: Colors.white.withValues(alpha: 0.5)),
        ),
        const SizedBox(height: 20),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(Icons.notifications_active, color: AppTheme.accentSecondary, size: 20),
                    SizedBox(width: 8),
                    Text('Daily reminder', style: TextStyle(fontWeight: FontWeight.w600)),
                  ],
                ),
                const SizedBox(height: 8),
                reminderAsync.when(
                  loading: () => const CircularProgressIndicator(),
                  error: (_, __) => const Text('Could not load reminder'),
                  data: (hour) => Text(
                    'Scheduled for $hour:00 daily',
                    style: TextStyle(color: Colors.white.withValues(alpha: 0.55)),
                  ),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  children: [20, 21, 22].map((h) {
                    return ActionChip(
                      label: Text('${h}:00'),
                      onPressed: () async {
                        await ref.read(repositoryProvider).setReminderHour(h);
                        await NotificationService.instance.scheduleDailyReminder(
                          hour: h,
                          minute: 0,
                          body: 'Time for your daily interview prep!',
                        );
                        refreshData(ref);
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Reminder set for $h:00')),
                          );
                        }
                      },
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 20),
        const Text('Topics needing attention', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
        const SizedBox(height: 10),
        reviewAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Text('Error: $e'),
          data: (topics) {
            if (topics.isEmpty) {
              return const Card(
                child: Padding(
                  padding: EdgeInsets.all(20),
                  child: Text('All topics look healthy. Great job!'),
                ),
              );
            }
            return Column(
              children: topics.map((topic) {
                return Card(
                  margin: const EdgeInsets.only(bottom: 10),
                  child: ListTile(
                    title: Text(topic.name),
                    subtitle: Text('Confidence ${topic.confidence}/5'),
                    trailing: ConfidenceStars(confidence: topic.confidence),
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => TopicDetailScreen(topicId: topic.id),
                      ),
                    ),
                  ),
                );
              }).toList(),
            );
          },
        ),
      ],
    );
  }
}

class ConfidenceStars extends StatelessWidget {
  const ConfidenceStars({super.key, required this.confidence});

  final int confidence;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(5, (i) {
        return Icon(
          i < confidence ? Icons.star : Icons.star_border,
          size: 16,
          color: i < confidence ? AppTheme.accentSecondary : Colors.white24,
        );
      }),
    );
  }
}
