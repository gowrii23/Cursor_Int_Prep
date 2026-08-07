import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../models/models.dart';
import '../models/study_models.dart';
import '../providers/providers.dart';
import '../theme/app_theme.dart';
import '../widgets/focus_and_status.dart';
import '../widgets/study_widgets.dart';

class TopicDetailScreen extends ConsumerStatefulWidget {
  const TopicDetailScreen({
    super.key,
    required this.topicId,
    this.initialTab = 0,
    this.highlightItemId,
  });

  final String topicId;
  final int initialTab;
  final int? highlightItemId;

  @override
  ConsumerState<TopicDetailScreen> createState() => _TopicDetailScreenState();
}

class _TopicDetailScreenState extends ConsumerState<TopicDetailScreen>
    with SingleTickerProviderStateMixin {
  Topic? _topic;
  List<ChecklistItem> _items = [];
  bool _loading = true;
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: 3,
      vsync: this,
      initialIndex: widget.initialTab.clamp(0, 2),
    );
    _load();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final repo = ref.read(repositoryProvider);
    final topic = await repo.getTopic(widget.topicId);
    final items = await repo.getItemsForTopic(widget.topicId);
    if (mounted) {
      setState(() {
        _topic = topic;
        _items = items;
        _loading = false;
      });
    }
  }

  Future<void> _setStatus(ChecklistItem item, ItemStatus status) async {
    await ref.read(repositoryProvider).updateItemStatus(item.id, status);
    refreshData(ref);
    await _load();
    if (status == ItemStatus.done && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.celebration, color: AppTheme.accentSecondary),
              const SizedBox(width: 10),
              Expanded(child: Text('Nice! "${item.title}" completed')),
            ],
          ),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading || _topic == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final topic = _topic!;
    final studyContent = ref.watch(studyContentProvider(topic.id));
    final completed = _items.where((i) => i.status == ItemStatus.done).length;

    return Scaffold(
      appBar: AppBar(
        title: Text(topic.name),
        actions: [
          if (topic.isCritical)
            const Padding(
              padding: EdgeInsets.only(right: 16),
              child: Icon(Icons.priority_high, color: AppTheme.critical),
            ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Learn', icon: Icon(Icons.menu_book_outlined, size: 20)),
            Tab(text: 'Practice', icon: Icon(Icons.fitness_center_outlined, size: 20)),
            Tab(text: 'Track', icon: Icon(Icons.insights_outlined, size: 20)),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _LearnTab(
            topic: topic,
            content: studyContent,
            onStudied: () async {
              await ref.read(repositoryProvider).markStudiedToday();
              refreshData(ref);
            },
          ),
          _PracticeTab(
            items: _items,
            highlightItemId: widget.highlightItemId,
            studyContent: studyContent,
            onStatusChanged: _setStatus,
            onIncrementPractice: (id) async {
              await ref.read(repositoryProvider).incrementPractice(id);
              refreshData(ref);
              await _load();
            },
            onNotesChanged: (id, notes) async {
              await ref.read(repositoryProvider).updateNotes(id, notes);
              await _load();
            },
          ),
          _TrackTab(
            topic: topic,
            items: _items,
            completed: completed,
            onConfidenceChanged: (v) async {
              await ref.read(repositoryProvider).updateTopicConfidence(topic.id, v);
              refreshData(ref);
              await _load();
            },
          ),
        ],
      ),
    );
  }
}

class _LearnTab extends StatelessWidget {
  const _LearnTab({
    required this.topic,
    required this.content,
    required this.onStudied,
  });

  final Topic topic;
  final TopicStudyContent? content;
  final VoidCallback onStudied;

  @override
  Widget build(BuildContext context) {
    if (content == null || content!.cards.isEmpty) {
      return ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const Icon(Icons.menu_book_outlined, size: 48, color: Colors.white24),
          const SizedBox(height: 16),
          const Text(
            'Study content coming soon for this topic.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.white54),
          ),
        ],
      );
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              content!.overview,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.75),
                height: 1.5,
                fontSize: 14,
              ),
            ),
          ),
        ),
        const SizedBox(height: 16),
        Text(
          '${content!.cards.length} study cards',
          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
        ),
        const SizedBox(height: 10),
        ...content!.cards.asMap().entries.map((entry) {
          final card = entry.value;
          return StudyCardTile(
            card: card,
            onTap: () async {
              onStudied();
              await Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => StudyCardReader(card: card)),
              );
            },
          ).animate(delay: (entry.key * 40).ms).fadeIn().slideX(begin: 0.03, end: 0);
        }),
      ],
    );
  }
}

class _PracticeTab extends StatelessWidget {
  const _PracticeTab({
    required this.items,
    required this.highlightItemId,
    required this.studyContent,
    required this.onStatusChanged,
    required this.onIncrementPractice,
    required this.onNotesChanged,
  });

  final List<ChecklistItem> items;
  final int? highlightItemId;
  final TopicStudyContent? studyContent;
  final Future<void> Function(ChecklistItem, ItemStatus) onStatusChanged;
  final Future<void> Function(int) onIncrementPractice;
  final Future<void> Function(int, String) onNotesChanged;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
      children: [
        Text(
          'Checklist (${items.length})',
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 4),
        Text(
          'Log practice reps and mark status. Tap a card for study notes.',
          style: TextStyle(color: Colors.white.withValues(alpha: 0.45), fontSize: 12),
        ),
        const SizedBox(height: 12),
        ...items.asMap().entries.map((entry) {
          final item = entry.value;
          final linkedCards = studyContent?.cardsForItem(item.title) ?? [];
          return _PracticeItemTile(
            item: item,
            highlighted: item.id == highlightItemId,
            linkedCard: linkedCards.isNotEmpty ? linkedCards.first : null,
            onStatusChanged: (s) => onStatusChanged(item, s),
            onIncrementPractice: () => onIncrementPractice(item.id),
            onNotesChanged: (notes) => onNotesChanged(item.id, notes),
          ).animate(delay: (entry.key * 40).ms).fadeIn().slideX(begin: 0.03, end: 0);
        }),
      ],
    );
  }
}

class _TrackTab extends StatelessWidget {
  const _TrackTab({
    required this.topic,
    required this.items,
    required this.completed,
    required this.onConfidenceChanged,
  });

  final Topic topic;
  final List<ChecklistItem> items;
  final int completed;
  final ValueChanged<int> onConfidenceChanged;

  @override
  Widget build(BuildContext context) {
    final progress = items.isEmpty ? 0.0 : completed / items.length;

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Progress', style: TextStyle(fontWeight: FontWeight.w600)),
                    Text(
                      '$completed / ${items.length} done',
                      style: const TextStyle(color: AppTheme.accent),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: LinearProgressIndicator(
                    value: progress,
                    minHeight: 8,
                    backgroundColor: Colors.white10,
                    color: AppTheme.accent,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'Weight ${topic.weight} · ${topic.isCritical ? "Critical" : "Standard"}',
                  style: TextStyle(color: Colors.white.withValues(alpha: 0.5), fontSize: 13),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: ConfidenceSlider(
              value: topic.confidence,
              onChanged: onConfidenceChanged,
            ),
          ),
        ),
        const SizedBox(height: 16),
        if (topic.lastActivityAt != null)
          Text(
            'Last activity: ${_formatDate(topic.lastActivityAt!)}',
            style: TextStyle(color: Colors.white.withValues(alpha: 0.4), fontSize: 12),
          ),
      ],
    );
  }

  String _formatDate(DateTime dt) {
    return '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}';
  }
}

class _PracticeItemTile extends StatefulWidget {
  const _PracticeItemTile({
    required this.item,
    required this.highlighted,
    required this.linkedCard,
    required this.onStatusChanged,
    required this.onIncrementPractice,
    required this.onNotesChanged,
  });

  final ChecklistItem item;
  final bool highlighted;
  final StudyCard? linkedCard;
  final ValueChanged<ItemStatus> onStatusChanged;
  final VoidCallback onIncrementPractice;
  final ValueChanged<String> onNotesChanged;

  @override
  State<_PracticeItemTile> createState() => _PracticeItemTileState();
}

class _PracticeItemTileState extends State<_PracticeItemTile> {
  bool _expanded = false;
  late TextEditingController _notesController;

  @override
  void initState() {
    super.initState();
    _notesController = TextEditingController(text: widget.item.notes ?? '');
    if (widget.highlighted) _expanded = true;
  }

  @override
  void didUpdateWidget(covariant _PracticeItemTile oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.item.notes != widget.item.notes) {
      _notesController.text = widget.item.notes ?? '';
    }
  }

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final item = widget.item;
    final borderColor = widget.highlighted ? AppTheme.accent : Colors.transparent;

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: borderColor.withValues(alpha: 0.5), width: 1.5),
      ),
      child: Column(
        children: [
          InkWell(
            onTap: () => setState(() => _expanded = !_expanded),
            borderRadius: BorderRadius.circular(16),
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _StatusButton(status: item.status, onTap: () => _showStatusPicker(context)),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.title,
                          style: TextStyle(
                            fontWeight: FontWeight.w500,
                            decoration: item.status == ItemStatus.done
                                ? TextDecoration.lineThrough
                                : null,
                            color: item.status == ItemStatus.done ? Colors.white38 : Colors.white,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            StatusChip(status: item.status, compact: true),
                            const SizedBox(width: 8),
                            Text(
                              '${item.practiceDone}/${item.practiceTarget} practice',
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.45),
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  Icon(_expanded ? Icons.expand_less : Icons.expand_more, color: Colors.white38),
                ],
              ),
            ),
          ),
          if (_expanded)
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (widget.linkedCard != null)
                    OutlinedButton.icon(
                      onPressed: () => Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => StudyCardReader(card: widget.linkedCard!),
                        ),
                      ),
                      icon: const Icon(Icons.menu_book_outlined, size: 18),
                      label: Text('Study: ${widget.linkedCard!.title}'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppTheme.accentSecondary,
                        side: BorderSide(color: AppTheme.accentSecondary.withValues(alpha: 0.4)),
                      ),
                    ),
                  if (widget.linkedCard != null) const SizedBox(height: 10),
                  OutlinedButton.icon(
                    onPressed: widget.onIncrementPractice,
                    icon: const Icon(Icons.add, size: 18),
                    label: const Text('Log practice'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppTheme.accent,
                      side: BorderSide(color: AppTheme.accent.withValues(alpha: 0.4)),
                    ),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: _notesController,
                    maxLines: 3,
                    decoration: const InputDecoration(
                      hintText: 'Notes, links, code snippets...',
                      hintStyle: TextStyle(color: Colors.white30),
                    ),
                    onSubmitted: widget.onNotesChanged,
                    onTapOutside: (_) {
                      widget.onNotesChanged(_notesController.text);
                      FocusScope.of(context).unfocus();
                    },
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  void _showStatusPicker(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.surfaceHigh,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: ItemStatus.values.map((status) {
            return ListTile(
              leading: Icon(_iconFor(status), color: AppTheme.statusColor(status.value)),
              title: Text(status.label),
              selected: status == widget.item.status,
              onTap: () {
                Navigator.pop(ctx);
                widget.onStatusChanged(status);
              },
            );
          }).toList(),
        ),
      ),
    );
  }

  IconData _iconFor(ItemStatus status) {
    switch (status) {
      case ItemStatus.notStarted:
        return Icons.radio_button_unchecked;
      case ItemStatus.inProgress:
        return Icons.timelapse;
      case ItemStatus.done:
        return Icons.check_circle;
      case ItemStatus.needsRevision:
        return Icons.refresh;
    }
  }
}

class _StatusButton extends StatelessWidget {
  const _StatusButton({required this.status, required this.onTap});

  final ItemStatus status;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = AppTheme.statusColor(status.value);
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 28,
        height: 28,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: color, width: 2),
          color: status == ItemStatus.done ? color.withValues(alpha: 0.2) : null,
        ),
        child: status == ItemStatus.done
            ? Icon(Icons.check, size: 16, color: color)
            : null,
      ),
    );
  }
}
