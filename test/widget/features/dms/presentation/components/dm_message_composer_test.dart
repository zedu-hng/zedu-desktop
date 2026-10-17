import 'package:zedu/core/core.dart';
import 'package:zedu/features/features.dart';
import '../../../../../helpers/helpers.dart';

class MockDraftStorage extends Mock implements SecureStorageService {}

void main() {
  const cases =
      <
        ({
          String name,
          String text,
          TextSelection selection,
          String expected,
          int caret,
        })
      >[
        (
          name: 'replaces a forward selection',
          text: 'Hello world',
          selection: TextSelection(baseOffset: 6, extentOffset: 11),
          expected: 'Hello 😀',
          caret: 8,
        ),
        (
          name: 'replaces a backward selection',
          text: 'Hello world',
          selection: TextSelection(baseOffset: 11, extentOffset: 6),
          expected: 'Hello 😀',
          caret: 8,
        ),
        (
          name: 'replaces the entire draft',
          text: 'Hello world',
          selection: TextSelection(baseOffset: 0, extentOffset: 11),
          expected: '😀',
          caret: 2,
        ),
        (
          name: 'inserts at a caret without removing adjacent text',
          text: 'Hello world',
          selection: TextSelection.collapsed(offset: 6),
          expected: 'Hello 😀world',
          caret: 8,
        ),
        (
          name: 'inserts at the beginning of a draft',
          text: 'Hello world',
          selection: TextSelection.collapsed(offset: 0),
          expected: '😀Hello world',
          caret: 2,
        ),
        (
          name: 'inserts at the end of a draft',
          text: 'Hello world',
          selection: TextSelection.collapsed(offset: 11),
          expected: 'Hello world😀',
          caret: 13,
        ),
        (
          name: 'inserts into an empty draft',
          text: '',
          selection: TextSelection.collapsed(offset: 0),
          expected: '😀',
          caret: 2,
        ),
        (
          name: 'preserves an emoji before the selected word',
          text: '😀 world',
          selection: TextSelection(baseOffset: 3, extentOffset: 8),
          expected: '😀 😀',
          caret: 5,
        ),
      ];

  for (final scenario in cases) {
    testWidgets('DM emoji picker ${scenario.name}', (tester) async {
      await tester.binding.setSurfaceSize(const Size(1000, 800));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      final storage = MockDraftStorage();
      when(() => storage.readData(any())).thenAnswer((_) async => null);
      when(() => storage.writeData(any(), any())).thenAnswer((_) async {});
      when(() => storage.deleteValue(any())).thenAnswer((_) async {});
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            dmDraftStoreProvider.overrideWith((ref) => DmDraftStore(storage)),
          ],
          child: buildTestMaterialApp(
            const Scaffold(
              body: Align(
                alignment: Alignment.bottomCenter,
                child: DmMessageComposer(
                  recipientName: 'Test recipient',
                  channelId: 'test-channel',
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      final field = find.byType(TextField);
      final controller = tester.widget<TextField>(field).controller!;
      try {
        await tester.enterText(field, scenario.text);
        controller.selection = scenario.selection;
        await tester.pump();
        await tester.tap(find.byTooltip('Emoji'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('😀'));
        await tester.pumpAndSettle();

        expect(controller.text, scenario.expected);
        expect(
          controller.selection,
          TextSelection.collapsed(offset: scenario.caret),
        );
        expect(tester.widget<TextField>(field).focusNode!.hasFocus, isTrue);
      } finally {
        controller.clear();
        await tester.pump(const Duration(milliseconds: 300));
        await tester.pumpWidget(const SizedBox.shrink());
      }
    });
  }
}
