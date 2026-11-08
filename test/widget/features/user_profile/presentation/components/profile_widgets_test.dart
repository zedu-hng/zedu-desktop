import 'package:flutter_test/flutter_test.dart';
import 'package:zedu/core/core.dart';
import 'package:zedu/features/user_profile/presentation/components/profile_widgets.dart';

void main() {
  group('ProfileWidgets', () {
    testWidgets('ProfileFieldLabel renders text with theme token', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          home: const Scaffold(body: ProfileFieldLabel('Email address')),
        ),
      );

      final labelFinder = find.text('Email address');
      expect(labelFinder, findsOneWidget);
      final textWidget = tester.widget<Text>(labelFinder);
      expect(textWidget.style?.color, AppPalette.light.textSecondary);
    });

    testWidgets('SquareIconButton renders border and icon with theme tokens', (
      tester,
    ) async {
      var tapped = false;
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          home: Scaffold(
            body: SquareIconButton(
              icon: Icons.edit,
              onTap: () => tapped = true,
            ),
          ),
        ),
      );

      final iconFinder = find.byIcon(Icons.edit);
      expect(iconFinder, findsOneWidget);
      final iconWidget = tester.widget<Icon>(iconFinder);
      expect(iconWidget.color, AppPalette.light.textPrimary);

      await tester.tap(iconFinder);
      expect(tapped, isTrue);
    });

    testWidgets('ProfileStatusPill renders active status with success tokens', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          home: const Scaffold(body: ProfileStatusPill(status: 'active')),
        ),
      );

      expect(find.text('Active'), findsOneWidget);
      final containerFinder = find.byType(Container).first;
      final container = tester.widget<Container>(containerFinder);
      final decoration = container.decoration as BoxDecoration?;
      expect(decoration?.color, AppPalette.light.successBg);
    });

    testWidgets('ProfileStatusPill renders inactive status with error tokens', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          home: const Scaffold(body: ProfileStatusPill(status: 'inactive')),
        ),
      );

      expect(find.text('Inactive'), findsOneWidget);
      final containerFinder = find.byType(Container).first;
      final container = tester.widget<Container>(containerFinder);
      final decoration = container.decoration as BoxDecoration?;
      expect(decoration?.color, AppPalette.light.errorBg);
    });
  });
}
