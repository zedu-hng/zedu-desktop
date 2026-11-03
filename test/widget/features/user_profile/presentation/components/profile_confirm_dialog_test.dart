import 'package:zedu/core/core.dart';
import 'package:zedu/features/features.dart';

import '../../../../../helpers/helpers.dart';

Future<ButtonStyle?> openDialogAndReadConfirmStyle(
  WidgetTester tester, {
  required bool destructive,
}) async {
  await tester.pumpWidget(
    buildTestMaterialApp(
      Scaffold(
        body: Builder(
          builder: (context) => TextButton(
            onPressed: () => showProfileConfirmDialog(
              context,
              title: 'Remove member',
              message: 'Are you sure?',
              confirmLabel: 'Remove',
              destructive: destructive,
              onConfirm: () async {},
            ),
            child: const Text('open'),
          ),
        ),
      ),
    ),
  );
  await tester.tap(find.text('open'));
  await tester.pumpAndSettle();

  final confirm = find.ancestor(
    of: find.text('Remove'),
    matching: find.byType(ElevatedButton),
  );
  return tester.widget<ElevatedButton>(confirm).style;
}

void main() {
  group('showProfileConfirmDialog', () {
    testWidgets('destructive confirm button uses the palette error colour', (
      tester,
    ) async {
      final style = await openDialogAndReadConfirmStyle(
        tester,
        destructive: true,
      );
      final error = tester.element(find.text('Remove')).colors.error;

      expect(style?.backgroundColor?.resolve(<WidgetState>{}), error);
    });

    testWidgets('non-destructive confirm button keeps the default colour', (
      tester,
    ) async {
      final style = await openDialogAndReadConfirmStyle(
        tester,
        destructive: false,
      );

      expect(style?.backgroundColor?.resolve(<WidgetState>{}), isNull);
    });
  });
}
