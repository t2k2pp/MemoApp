// This is a basic Flutter widget test.

import 'package:flutter_test/flutter_test.dart';
import 'package:memo_app/main.dart';

void main() {
  testWidgets('App launches test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const MemoApp());

    // Verify that the app title is displayed
    expect(find.text('メモ'), findsOneWidget);
  });
}
