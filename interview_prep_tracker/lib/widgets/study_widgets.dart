import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';

import '../models/study_models.dart';
import '../theme/app_theme.dart';

class StudyCardTile extends StatelessWidget {
  const StudyCardTile({
    super.key,
    required this.card,
    required this.onTap,
  });

  final StudyCard card;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              _TypeIcon(type: card.type),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      card.title,
                      style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${card.type.label} · ${card.readMinutes} min read',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.45),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, color: Colors.white38),
            ],
          ),
        ),
      ),
    );
  }
}

class _TypeIcon extends StatelessWidget {
  const _TypeIcon({required this.type});

  final StudyCardType type;

  @override
  Widget build(BuildContext context) {
    final (icon, color) = switch (type) {
      StudyCardType.framework => (Icons.account_tree, AppTheme.accent),
      StudyCardType.concept => (Icons.lightbulb_outline, AppTheme.accentSecondary),
      StudyCardType.pattern => (Icons.hub_outlined, const Color(0xFF80CBC4)),
      StudyCardType.problem => (Icons.code, const Color(0xFFCE93D8)),
      StudyCardType.quiz => (Icons.quiz_outlined, const Color(0xFFFFAB40)),
      StudyCardType.cheat => (Icons.description_outlined, const Color(0xFF90CAF9)),
      StudyCardType.karat => (Icons.mic_outlined, AppTheme.critical),
    };

    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Icon(icon, color: color, size: 20),
    );
  }
}

class StudyCardReader extends StatelessWidget {
  const StudyCardReader({super.key, required this.card});

  final StudyCard card;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(card.type.label),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
        children: [
          Text(
            card.title,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
          ),
          const SizedBox(height: 6),
          Text(
            '${card.readMinutes} min read',
            style: TextStyle(color: Colors.white.withValues(alpha: 0.45), fontSize: 13),
          ),
          const SizedBox(height: 20),
          MarkdownBody(
            data: card.body,
            styleSheet: MarkdownStyleSheet(
              p: const TextStyle(color: Colors.white, height: 1.55, fontSize: 15),
              strong: const TextStyle(
                color: AppTheme.accentSecondary,
                fontWeight: FontWeight.w700,
              ),
              code: TextStyle(
                color: AppTheme.accent,
                backgroundColor: Colors.white.withValues(alpha: 0.06),
                fontFamily: 'monospace',
                fontSize: 13,
              ),
              codeblockDecoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.white12),
              ),
              codeblockPadding: const EdgeInsets.all(14),
              h3: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w700,
                fontSize: 16,
              ),
              tableHead: const TextStyle(color: AppTheme.accentSecondary, fontWeight: FontWeight.w600),
              tableBody: const TextStyle(color: Colors.white70, fontSize: 13),
              tableBorder: TableBorder.all(color: Colors.white12),
            ),
          ),
        ],
      ),
    );
  }
}

class TodayRevisionCard extends StatelessWidget {
  const TodayRevisionCard({
    super.key,
    required this.revision,
    required this.onStudy,
    required this.onShuffle,
    required this.onOpenTopic,
  });

  final TodayRevision revision;
  final VoidCallback onStudy;
  final VoidCallback onShuffle;
  final VoidCallback onOpenTopic;

  @override
  Widget build(BuildContext context) {
    final title = revision.item?.title ?? revision.topic.name;

    return Card(
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppTheme.accentSecondary.withValues(alpha: 0.3)),
        ),
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppTheme.accentSecondary.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Text(
                    "TODAY'S REVISION",
                    style: TextStyle(
                      color: AppTheme.accentSecondary,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.2,
                    ),
                  ),
                ),
                const Spacer(),
                IconButton(
                  onPressed: onShuffle,
                  icon: const Icon(Icons.shuffle, color: AppTheme.accentSecondary, size: 20),
                  tooltip: 'Shuffle revision',
                  visualDensity: VisualDensity.compact,
                ),
              ],
            ),
            const SizedBox(height: 12),
            InkWell(
              onTap: onOpenTopic,
              borderRadius: BorderRadius.circular(8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600, height: 1.3),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${revision.phase.name} · ${revision.topic.name}',
                    style: TextStyle(color: Colors.white.withValues(alpha: 0.5), fontSize: 13),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    revision.reason,
                    style: const TextStyle(color: AppTheme.accentSecondary, fontSize: 12),
                  ),
                ],
              ),
            ),
            if (revision.studyCard != null) ...[
              const SizedBox(height: 14),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: onStudy,
                  icon: const Icon(Icons.menu_book_outlined, size: 18),
                  label: Text('Study: ${revision.studyCard!.title}'),
                  style: FilledButton.styleFrom(
                    backgroundColor: AppTheme.accentSecondary.withValues(alpha: 0.2),
                    foregroundColor: AppTheme.accentSecondary,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class MicroLessonCard extends StatelessWidget {
  const MicroLessonCard({
    super.key,
    required this.lesson,
    required this.onTap,
  });

  final MicroLesson lesson;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.06),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.auto_stories, color: Colors.white70, size: 22),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Micro-lesson · ${lesson.tag}',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.45),
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      lesson.title,
                      style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
                    ),
                    Text(
                      '${lesson.readMinutes} min',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.4),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, color: Colors.white38),
            ],
          ),
        ),
      ),
    );
  }
}

class MicroLessonReader extends StatelessWidget {
  const MicroLessonReader({super.key, required this.lesson});

  final MicroLesson lesson;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(lesson.tag)),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
        children: [
          Text(
            lesson.title,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 20),
          MarkdownBody(
            data: lesson.body,
            styleSheet: MarkdownStyleSheet(
              p: const TextStyle(color: Colors.white, height: 1.55, fontSize: 15),
              strong: const TextStyle(color: AppTheme.accentSecondary, fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }
}
