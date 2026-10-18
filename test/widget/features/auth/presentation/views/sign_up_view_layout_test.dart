import 'dart:io';

import 'package:flutter/rendering.dart';

import 'package:zedu/core/core.dart';
import 'package:zedu/features/features.dart';
import '../../../../../helpers/helpers.dart';

// Fake notifier that avoids GetIt/locator setup while remaining type-compatible
// with authNotifierProvider (which is NotifierProvider<AuthNotifier, AuthState>).
class FakeAuthNotifier extends AuthNotifier {
  @override
  AuthState build() => const AuthState(status: AuthStatus.unauthenticated);
}

// The default test font has different metrics, so load the app's real fonts.
Future<void> loadAppFonts() async {
  for (final family in ['Lato', 'Roboto']) {
    final loader = FontLoader(family);
    for (final weight in ['Regular', 'Bold']) {
      final bytes = File('assets/fonts/$family/$family-$weight.ttf');
      loader.addFont(
        Future.value(ByteData.sublistView(bytes.readAsBytesSync())),
      );
    }
    await loader.load();
  }
}

Future<void> pumpSignUpAt(WidgetTester tester, Size size) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);

  await tester.pumpWidget(
    ProviderScope(
      overrides: [authNotifierProvider.overrideWith(() => FakeAuthNotifier())],
      child: MaterialApp(theme: AppTheme.light, home: const SignUpView()),
    ),
  );
  await tester.pump();
}

ScrollPosition signUpScrollPosition(WidgetTester tester) =>
    tester.state<ScrollableState>(find.byType(Scrollable).first).position;

// A desktop app: Linux gives compact VisualDensity, which shortens fields and
// buttons. The default test platform (Android) lays the column out taller.
final linuxOnly = TargetPlatformVariant.only(TargetPlatform.linux);

Finder get termsText => find.textContaining('By Signing up');

void main() {
  setUpAll(loadAppFonts);

  group('SignUpView layout', () {
    testWidgets('Tab moves directly between registration fields', (
      tester,
    ) async {
      await pumpSignUpAt(tester, const Size(1280, 720));

      await tester.tap(find.byType(TextFormField).at(0));
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pump();

      final emailField = tester.widget<EditableText>(
        find.descendant(
          of: find.byType(TextFormField).at(1),
          matching: find.byType(EditableText),
        ),
      );
      expect(emailField.focusNode.hasFocus, isTrue);

      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pump();

      final passwordField = tester.widget<EditableText>(
        find.descendant(
          of: find.byType(TextFormField).at(2),
          matching: find.byType(EditableText),
        ),
      );
      expect(passwordField.focusNode.hasFocus, isTrue);
    });

    testWidgets('fits a 1280x720 surface without scrolling', (tester) async {
      await pumpSignUpAt(tester, const Size(1280, 720));

      expect(signUpScrollPosition(tester).maxScrollExtent, 0);
      final terms = tester.getRect(termsText);
      expect(terms.top, greaterThanOrEqualTo(0));
      expect(terms.bottom, lessThanOrEqualTo(720));
      expect(tester.takeException(), isNull);
    }, variant: linuxOnly);

    testWidgets('shows the terms text at 1280x672 (default window)', (
      tester,
    ) async {
      await pumpSignUpAt(tester, const Size(1280, 672));

      expect(tester.getRect(termsText).bottom, lessThanOrEqualTo(672));
      expect(tester.takeException(), isNull);
    }, variant: linuxOnly);

    testWidgets('puts Google and Apple side by side on single lines', (
      tester,
    ) async {
      await pumpSignUpAt(tester, const Size(1280, 720));

      final google = tester.getRect(find.text('Sign up with Google'));
      final apple = tester.getRect(find.text('Sign up with Apple'));
      expect(google.center.dy, closeTo(apple.center.dy, 0.5));
      expect(google.right, lessThan(apple.left));

      for (final label in ['Sign up with Google', 'Sign up with Apple']) {
        final paragraph = tester.renderObject<RenderParagraph>(
          find.text(label),
        );
        // One line is about 1.5x the font size; a wrapped label is 2x or more.
        final fontSize = paragraph.text.style!.fontSize!;
        expect(paragraph.size.height, lessThan(fontSize * 2), reason: label);
        expect(paragraph.didExceedMaxLines, isFalse, reason: label);
      }
    }, variant: linuxOnly);

    testWidgets('scrolls to the terms text in a 1000x600 window', (
      tester,
    ) async {
      await pumpSignUpAt(tester, const Size(1000, 600));

      final position = signUpScrollPosition(tester);
      expect(position.maxScrollExtent, greaterThan(0));

      position.jumpTo(position.maxScrollExtent);
      await tester.pump();

      final terms = tester.getRect(termsText);
      expect(terms.top, greaterThanOrEqualTo(80)); // below the app bar
      expect(terms.bottom, lessThanOrEqualTo(600));
      expect(tester.takeException(), isNull);
    }, variant: linuxOnly);
  });
}
