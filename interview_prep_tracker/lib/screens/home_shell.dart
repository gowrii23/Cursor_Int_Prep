import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/providers.dart';
import '../services/notification_service.dart';
import 'phases_screen.dart';
import 'progress_screen.dart';
import 'review_screen.dart';
import 'today_screen.dart';

class HomeShell extends ConsumerStatefulWidget {
  const HomeShell({super.key});

  @override
  ConsumerState<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends ConsumerState<HomeShell> {
  int _index = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _setupNotifications());
  }

  Future<void> _setupNotifications() async {
    await NotificationService.instance.initialize();
    final repo = ref.read(repositoryProvider);
    final hour = await repo.getReminderHour();
    final focus = await repo.getTodayFocus();
    final body = focus != null
        ? "Today's focus: ${focus.item.title}"
        : 'Time for your daily interview prep session!';
    await NotificationService.instance.scheduleDailyReminder(
      hour: hour,
      minute: 0,
      body: body,
    );
  }

  @override
  Widget build(BuildContext context) {
    final pages = [
      const TodayScreen(),
      const PhasesScreen(),
      const ProgressScreen(),
      const ReviewScreen(),
    ];

    return Scaffold(
      body: SafeArea(child: pages[_index]),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (i) => setState(() => _index = i),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.today_outlined),
            selectedIcon: Icon(Icons.today),
            label: 'Today',
          ),
          NavigationDestination(
            icon: Icon(Icons.account_tree_outlined),
            selectedIcon: Icon(Icons.account_tree),
            label: 'Phases',
          ),
          NavigationDestination(
            icon: Icon(Icons.insights_outlined),
            selectedIcon: Icon(Icons.insights),
            label: 'Progress',
          ),
          NavigationDestination(
            icon: Icon(Icons.rate_review_outlined),
            selectedIcon: Icon(Icons.rate_review),
            label: 'Review',
          ),
        ],
      ),
    );
  }
}
