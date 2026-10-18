import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:zedu/core/core.dart';

void main() {
  group('DesktopManager tray configuration', () {
    test('defaultTrayIconPath returns appropriate icon per platform', () {
      final path = DesktopManager.defaultTrayIconPath;

      if (Platform.isWindows) {
        expect(path, equals('app_icon.ico'));
      } else {
        expect(path, equals('assets/pngs/zedu_logo.png'));
      }
    });

    testWidgets('DesktopManager renders child widget without crashing', (
      tester,
    ) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: DesktopManager(
              child: Scaffold(body: Text('Zedu Desktop Content')),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Zedu Desktop Content'), findsOneWidget);
    });
  });
}
