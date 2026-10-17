import 'package:zedu/core/core.dart';
import 'package:zedu/features/features.dart';

import '../../../../../helpers/helpers.dart';

class FakeSecureStorageService extends Fake implements SecureStorageService {
  final _values = <String, String>{};

  @override
  Future<String?> readData(String key) async => _values[key];

  @override
  Future<void> writeData(String key, String value) async =>
      _values[key] = value;

  @override
  Future<void> deleteValue(String key) async => _values.remove(key);
}

Future<TextField> pumpComposer(WidgetTester tester) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        dmDraftStoreProvider.overrideWith(
          (ref) => DmDraftStore(
            FakeSecureStorageService(),
            userId: 'user-1',
            orgId: 'org-1',
          ),
        ),
      ],
      child: buildTestMaterialApp(
        const Scaffold(
          body: DmMessageComposer(recipientName: 'Ada', channelId: 'dm-1'),
        ),
      ),
    ),
  );
  return tester.widget<TextField>(find.byType(TextField));
}

Future<void> typeAndPlaceCursorAtEnd(
  WidgetTester tester,
  TextField field,
  String text,
) async {
  await tester.enterText(find.byType(TextField), text);
  field.controller!.selection = TextSelection.collapsed(offset: text.length);
  await tester.pump();
}

/// Runs [body] against the composer, then empties it so the composer's
/// draft flush in `dispose` has nothing to save when the test unmounts it.
void composerTest(
  String description,
  Future<void> Function(WidgetTester tester, TextField field) body,
) {
  testWidgets(description, (tester) async {
    final field = await pumpComposer(tester);
    await body(tester, field);
    field.controller!.clear();
    await tester.pump(const Duration(milliseconds: 300));
  });
}

Future<void> tapDivider(WidgetTester tester) async {
  await tester.tap(find.byTooltip('Divider'));
  // Let the composer's debounced draft save run.
  await tester.pump(const Duration(milliseconds: 300));
}

void main() {
  group('DmMessageComposer Divider button', () {
    composerTest('inserts a divider into an empty composer', (
      tester,
      field,
    ) async {
      await tapDivider(tester);

      expect(field.controller!.text, '---\n');
      expect(
        field.controller!.selection,
        const TextSelection.collapsed(offset: 4),
      );
    });

    composerTest(
      'puts a blank line before the divider so it is not read as a heading',
      (tester, field) async {
        await typeAndPlaceCursorAtEnd(tester, field, 'hello');

        await tapDivider(tester);

        expect(field.controller!.text, 'hello\n\n---\n');
        expect(
          field.controller!.selection,
          const TextSelection.collapsed(offset: 'hello\n\n---\n'.length),
        );
      },
    );

    composerTest('adds only one newline when the text already ends with one', (
      tester,
      field,
    ) async {
      await typeAndPlaceCursorAtEnd(tester, field, 'hello\n');

      await tapDivider(tester);

      expect(field.controller!.text, 'hello\n\n---\n');
    });

    composerTest('inserts after the selection without removing it', (
      tester,
      field,
    ) async {
      await tester.enterText(find.byType(TextField), 'hello world');
      field.controller!.selection = const TextSelection(
        baseOffset: 0,
        extentOffset: 5,
      );
      await tester.pump();

      await tapDivider(tester);

      expect(field.controller!.text, 'hello\n\n---\n world');
      expect(
        field.controller!.selection,
        const TextSelection.collapsed(offset: 'hello\n\n---\n'.length),
      );
    });
  });
}
