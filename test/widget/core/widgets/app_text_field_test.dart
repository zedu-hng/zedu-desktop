import 'package:zedu/core/core.dart';
import '../../../helpers/helpers.dart';

Widget buildPasswordFieldUnderTest(TextEditingController controller) {
  return buildTestMaterialApp(
    Scaffold(
      body: AppTextField(
        controller: controller,
        hint: 'Password',
        isPassword: true,
      ),
    ),
  );
}

void main() {
  group('AppTextField password visibility toggle', () {
    late TextEditingController controller;

    setUp(() {
      controller = TextEditingController();
    });

    tearDown(() {
      controller.dispose();
    });

    testWidgets('is labelled "Show password" while the text is obscured', (
      tester,
    ) async {
      await tester.pumpWidget(buildPasswordFieldUnderTest(controller));

      expect(find.bySemanticsLabel('Show password'), findsOneWidget);
      expect(find.byTooltip('Show password'), findsOneWidget);
      expect(find.bySemanticsLabel('Hide password'), findsNothing);
    });

    testWidgets('flips to "Hide password" after the toggle is tapped', (
      tester,
    ) async {
      await tester.pumpWidget(buildPasswordFieldUnderTest(controller));

      await tester.tap(find.byType(IconButton));
      await tester.pump();

      expect(find.bySemanticsLabel('Hide password'), findsOneWidget);
      expect(find.byTooltip('Hide password'), findsOneWidget);
      expect(find.bySemanticsLabel('Show password'), findsNothing);

      await tester.tap(find.byType(IconButton));
      await tester.pump();

      expect(find.bySemanticsLabel('Show password'), findsOneWidget);
    });

    testWidgets('still toggles obscureText on the underlying field', (
      tester,
    ) async {
      await tester.pumpWidget(buildPasswordFieldUnderTest(controller));

      EditableText editable() => tester.widget(find.byType(EditableText));
      expect(editable().obscureText, isTrue);

      await tester.tap(find.byType(IconButton));
      await tester.pump();

      expect(editable().obscureText, isFalse);
    });

    testWidgets('a non-password field has no toggle', (tester) async {
      await tester.pumpWidget(
        buildTestMaterialApp(
          Scaffold(
            body: AppTextField(controller: controller, hint: 'Email'),
          ),
        ),
      );

      expect(find.byType(IconButton), findsNothing);
      expect(find.bySemanticsLabel('Show password'), findsNothing);
    });
  });
}
