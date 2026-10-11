import 'package:zedu/core/core.dart';
import 'package:zedu/features/features.dart';
import '../../../../../helpers/helpers.dart';

class _ResetAuthNotifier extends AuthNotifier {
  String? submittedToken;

  @override
  AuthState build() => const AuthState(status: AuthStatus.unauthenticated);

  @override
  Future<bool> resetPassword({
    required String email,
    required String token,
    required String newPassword,
  }) async {
    submittedToken = token;
    return false;
  }
}

void main() {
  late _ResetAuthNotifier notifier;

  Future<void> showPage(WidgetTester tester) async {
    tester.view.physicalSize = const Size(1280, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    notifier = _ResetAuthNotifier();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [authNotifierProvider.overrideWith(() => notifier)],
        child: const MaterialApp(
          home: ResetPasswordView(email: 'sample@example.com'),
        ),
      ),
    );
    await tester.pump();
    addTearDown(() async {
      await tester.pumpWidget(const SizedBox.shrink());
    });
  }

  List<TextFormField> fields(WidgetTester tester) =>
      tester.widgetList<TextFormField>(find.byType(TextFormField)).toList();

  List<EditableText> editableFields(WidgetTester tester) =>
      tester.widgetList<EditableText>(find.byType(EditableText)).toList();

  List<String> code(WidgetTester tester) =>
      fields(tester).take(6).map((field) => field.controller!.text).toList();

  Future<void> paste(WidgetTester tester, String text, {int index = 0}) async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(SystemChannels.platform, (call) async {
          if (call.method == 'Clipboard.getData') return {'text': text};
          return null;
        });
    addTearDown(() {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(SystemChannels.platform, null);
    });
    await tester.tap(find.byType(TextFormField).at(index));
    await tester.pump();
    final editable = tester.state<EditableTextState>(
      find.byType(EditableText).at(index),
    );
    await editable.pasteText(SelectionChangedCause.toolbar);
    await tester.pump();
  }

  testWidgets('pasted code fills all boxes and submits the displayed code', (
    tester,
  ) async {
    await showPage(tester);
    await paste(tester, '123456');
    expect(code(tester), ['1', '2', '3', '4', '5', '6']);
    expect(editableFields(tester)[5].focusNode.hasFocus, isTrue);
    await tester.enterText(find.byType(TextFormField).at(6), 'ExamplePass123');
    await tester.enterText(find.byType(TextFormField).at(7), 'ExamplePass123');
    await tester.tap(find.widgetWithText(ElevatedButton, 'Reset Password'));
    await tester.pump();
    expect(notifier.submittedToken, '123456');
  });

  testWidgets('typing and deleting retain automatic focus movement', (
    tester,
  ) async {
    await showPage(tester);
    for (var index = 0; index < 6; index++) {
      await tester.enterText(
        find.byType(TextFormField).at(index),
        '${index + 1}',
      );
      await tester.pump();
      expect(
        editableFields(tester)[index < 5 ? index + 1 : 5].focusNode.hasFocus,
        isTrue,
      );
    }
    expect(code(tester), ['1', '2', '3', '4', '5', '6']);
    await tester.enterText(find.byType(TextFormField).at(5), '');
    await tester.pump();
    expect(code(tester), ['1', '2', '3', '4', '5', '']);
    expect(editableFields(tester)[4].focusNode.hasFocus, isTrue);
  });

  testWidgets(
    'pasting again replaces a populated code without keeping the old digit',
    (tester) async {
      await showPage(tester);
      await paste(tester, '123456');
      await paste(tester, '654321');
      expect(code(tester), ['6', '5', '4', '3', '2', '1']);
    },
  );

  testWidgets('paste filters non-digits and limits input to six boxes', (
    tester,
  ) async {
    await showPage(tester);
    await paste(tester, '12a 34-56789');
    expect(code(tester), ['1', '2', '3', '4', '5', '6']);
  });

  testWidgets(
    'partial paste fills remaining boxes without overwriting earlier digits',
    (tester) async {
      await showPage(tester);
      await tester.enterText(find.byType(TextFormField).at(0), '1');
      await tester.enterText(find.byType(TextFormField).at(1), '2');
      await paste(tester, '345678', index: 2);
      expect(code(tester), ['1', '2', '3', '4', '5', '6']);
      expect(editableFields(tester)[5].focusNode.hasFocus, isTrue);
    },
  );
}
