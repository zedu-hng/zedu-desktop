import 'dart:async';

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
  List<RouteBase> additionalRoutes = const [],
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
      ...additionalRoutes,
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

    testWidgets('request page navigates to signup when Sign up is tapped', (
      tester,
    ) async {
      await tester.binding.setSurfaceSize(const Size(1440, 1024));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      var navigatedToSignup = false;
      await tester.pumpWidget(
        buildMagicLinkRouterUnderTest(
          additionalRoutes: [
            GoRoute(
              path: AppRouter.signup,
              builder: (context, state) {
                navigatedToSignup = true;
                return const SizedBox();
              },
            ),
          ],
        ),
      );
      await tester.pumpAndSettle();

      final textFinder = find.textContaining("Don't have an account?");
      expect(textFinder, findsOneWidget);

      final textWidget = tester.widget<Text>(textFinder);
      final textSpan = textWidget.textSpan as TextSpan?;
      expect(textSpan, isNotNull);

      final signUpSpan = textSpan!.children!.first as TextSpan;
      expect(signUpSpan.text, 'Sign up');
      expect(signUpSpan.recognizer, isA<TapGestureRecognizer>());

      (signUpSpan.recognizer as TapGestureRecognizer).onTap!();
      await tester.pumpAndSettle();

      expect(navigatedToSignup, isTrue);
    });
  });
}
