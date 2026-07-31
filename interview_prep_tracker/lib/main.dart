import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'providers/providers.dart';
import 'screens/home_shell.dart';
import 'theme/app_theme.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      systemNavigationBarColor: AppTheme.surface,
      systemNavigationBarIconBrightness: Brightness.light,
    ),
  );
  runApp(const ProviderScope(child: PrepTrackerApp()));
}

class PrepTrackerApp extends ConsumerWidget {
  const PrepTrackerApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final init = ref.watch(initProvider);

    return MaterialApp(
      title: 'Prep Tracker',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.dark(),
      home: init.when(
        loading: () => const Scaffold(
          body: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 16),
                Text('Loading your prep plan...'),
              ],
            ),
          ),
        ),
        error: (e, _) => Scaffold(
          body: Center(child: Text('Failed to initialize: $e')),
        ),
        data: (_) => const HomeShell(),
      ),
    );
  }
}
