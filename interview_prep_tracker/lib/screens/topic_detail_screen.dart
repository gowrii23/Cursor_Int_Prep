import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../models/models.dart';
import '../providers/providers.dart';
import '../theme/app_theme.dart';
import '../widgets/focus_and_status.dart';

class TopicDetailScreen extends ConsumerStatefulWidget {
  const TopicDetailScreen({super.key, required this.topicId});

  final String topicId;

  @override
  ConsumerState<TopicDetailScreen> createState() => _TopicDetailScreenState();
}

class _TopicDetailScreenState extends ConsumerState<TopicDetailScreen> {
  Topic? _topic;
  List<ChecklistItem> _items = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
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
    HapticFeedback.mediumImpact();
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
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: ConfidenceSlider(
                value: topic.confidence,
                onChanged: (v) async {
                  await ref.read(repositoryProvider).updateTopicConfidence(topic.id, v);
                  refreshData(ref);
                  await _load();
                },
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Checklist (${_items.length})',
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 10),
          ..._items.asMap().entries.map((entry) {
            final item = entry.value;
            return _ItemTile(
              item: item,
              onStatusChanged: (s) => _setStatus(item, s),
              onIncrementPractice: () async {
                await ref.read(repositoryProvider).incrementPractice(item.id);
                refreshData(ref);
                await _load();
              },
              onNotesChanged: (notes) async {
                await ref.read(repositoryProvider).updateNotes(item.id, notes);
                await _load();
              },
            ).animate(delay: (entry.key * 40).ms).fadeIn().slideX(begin: 0.03, end: 0);
          }),
        ],
      ),
    );
  }
}

class _ItemTile extends StatefulWidget {
  const _ItemTile({
    required this.item,
    required this.onStatusChanged,
    required this.onIncrementPractice,
    required this.onNotesChanged,
  });

  final ChecklistItem item;
  final ValueChanged<ItemStatus> onStatusChanged;
  final VoidCallback onIncrementPractice;
  final ValueChanged<String> onNotesChanged;

  @override
  State<_ItemTile> createState() => _ItemTileState();
}

class _ItemTileState extends State<_ItemTile> {
  bool _expanded = false;
  late TextEditingController _notesController;

  @override
  void initState() {
    super.initState();
    _notesController = TextEditingController(text: widget.item.notes ?? '');
  }

  @override
  void didUpdateWidget(covariant _ItemTile oldWidget) {
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

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
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
                  _StatusButton(
                    status: item.status,
                    onTap: () => _showStatusPicker(context),
                  ),
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
                            color: item.status == ItemStatus.done
                                ? Colors.white38
                                : Colors.white,
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
                  Icon(
                    _expanded ? Icons.expand_less : Icons.expand_more,
                    color: Colors.white38,
                  ),
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
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: widget.onIncrementPractice,
                          icon: const Icon(Icons.add, size: 18),
                          label: const Text('Log practice'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppTheme.accent,
                            side: BorderSide(color: AppTheme.accent.withValues(alpha: 0.4)),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: _notesController,
                    maxLines: 3,
                    decoration: const InputDecoration(
                      hintText: 'Notes, links to guides, code snippets...',
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
              leading: Icon(
                _iconFor(status),
                color: AppTheme.statusColor(status.value),
              ),
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
