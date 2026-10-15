import 'dart:async';

import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zedu/core/core.dart';
import 'package:zedu/features/features.dart';

class FakeMagicLinkNotifier extends MagicLinkNotifier {
  FakeMagicLinkNotifier({this.sendResult = true, this.onSend});

  final bool sendResult;
  final void Function(String email)? onSend;

  @override
  FutureOr<void> build() {}

  @override
  Future<bool> send(String email) async {
    onSend?.call(email);
    return sendResult;
  }
}

Widget buildMagicLinkRouterUnderTest({
  FakeMagicLinkNotifier? magicLinkNotifier,
}) {
  final router = GoRouter(
    initialLocation: AppRouter.magicLinkRequest,
    routes: [
      GoRoute(
        path: AppRouter.magicLinkRequest,
        builder: (context, state) => const MagicLinkRequestView(),
      ),
      GoRoute(
        path: AppRouter.magicLinkSent,
        builder: (context, state) =>
            MagicLinkSentView(email: state.extra! as String),
      ),
      GoRoute(
        path: AppRouter.signup,
        builder: (context, state) =>
            const Scaffold(body: Center(child: Text('Sign up screen'))),
      ),
    ],
  );

  return ProviderScope(
    overrides: [
      magicLinkNotifierProvider.overrideWith(
        () => magicLinkNotifier ?? FakeMagicLinkNotifier(),
      ),
    ],
    child: MaterialApp.router(routerConfig: router),
  );
}

void main() {
  group('Magic link views', () {
    testWidgets('request page renders form and shared header icon', (
      tester,
    ) async {
      await tester.binding.setSurfaceSize(const Size(1440, 1024));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(buildMagicLinkRouterUnderTest());
      await tester.pumpAndSettle();

      expect(find.text('Login with email link'), findsOneWidget);
      expect(find.text('Email address'), findsOneWidget);
      expect(find.text('Generate magic link'), findsOneWidget);
      expect(find.byType(AuthHeaderStrip), findsOneWidget);
      expect(find.byType(Image), findsWidgets);
    });

    testWidgets('request page validates empty email', (tester) async {
      await tester.binding.setSurfaceSize(const Size(1440, 1024));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(buildMagicLinkRouterUnderTest());
      await tester.pumpAndSettle();

      await tester.tap(find.text('Generate magic link'));
      await tester.pumpAndSettle();

      expect(find.text('Email is required'), findsOneWidget);
    });

    testWidgets('successful send navigates to sent page with email', (
      tester,
    ) async {
      await tester.binding.setSurfaceSize(const Size(1440, 1024));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      String? capturedEmail;
      await tester.pumpWidget(
        buildMagicLinkRouterUnderTest(
          magicLinkNotifier: FakeMagicLinkNotifier(
            sendResult: true,
            onSend: (email) => capturedEmail = email,
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.enterText(
        find.byType(TextFormField),
        'anonymoususer@gmail.com',
      );
      await tester.tap(find.text('Generate magic link'));
      await tester.pumpAndSettle();

      expect(capturedEmail, 'anonymoususer@gmail.com');
      expect(find.text('Awesome! mail sent.'), findsOneWidget);
      expect(find.textContaining('anonymoususer@gmail.com'), findsOneWidget);
      expect(find.byType(AuthHeaderStrip), findsOneWidget);
    });

    testWidgets('sign up link navigates to the signup screen', (tester) async {
      await tester.binding.setSurfaceSize(const Size(1440, 1024));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(buildMagicLinkRouterUnderTest());
      await tester.pumpAndSettle();

      const linkText = 'Sign up';
      final paragraphFinder = find.textContaining(linkText, findRichText: true);
      final paragraph =
          paragraphFinder.evaluate().single.renderObject as RenderParagraph;
      final plainText = paragraph.text.toPlainText();
      final startOffset = plainText.indexOf(linkText);
      final box = paragraph
          .getBoxesForSelection(
            TextSelection(
              baseOffset: startOffset,
              extentOffset: startOffset + linkText.length,
            ),
          )
          .single
          .toRect();

      await tester.tapAt(
        tester.getTopLeft(paragraphFinder) +
            Offset(box.left + box.width / 2, box.top + box.height / 2),
      );
      await tester.pumpAndSettle();

      expect(find.text('Sign up screen'), findsOneWidget);
    });
  });
}
