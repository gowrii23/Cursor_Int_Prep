import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:interview_prep_tracker/main.dart';

void main() {
  testWidgets('App loads initialization screen', (WidgetTester tester) async {
    await tester.pumpWidget(const ProviderScope(child: PrepTrackerApp()));
    await tester.pump();

    expect(find.text('Loading your prep plan...'), findsOneWidget);
  });
}
