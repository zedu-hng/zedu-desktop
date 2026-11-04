import 'dart:async';

import 'package:app_links/app_links.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:zedu/features/features.dart';

class MockAppLinks extends Mock implements AppLinks {}

class FakeDeepLinkAuthNotifier extends AuthNotifier {
  FakeDeepLinkAuthNotifier({this.onVerify});

  final void Function(String token)? onVerify;

  @override
  AuthState build() => const AuthState(status: AuthStatus.unauthenticated);

  @override
  Future<void> verifyMagicLink({required String token}) async {
    onVerify?.call(token);
    state = const AuthState(status: AuthStatus.unauthenticated);
  }
}

void main() {
  group('AuthDeepLinkListener', () {
    late MockAppLinks mockAppLinks;
    late StreamController<Uri> linkController;

    setUp(() {
      mockAppLinks = MockAppLinks();
      linkController = StreamController<Uri>.broadcast();

      when(
        () => mockAppLinks.uriLinkStream,
      ).thenAnswer((_) => linkController.stream);
    });

    tearDown(() async {
      await linkController.close();
    });

    testWidgets('ignores link when token query param is missing', (
      tester,
    ) async {
      String? capturedToken;

      when(
        () => mockAppLinks.getInitialLink(),
      ).thenAnswer((_) async => Uri.parse('zedu://auth/magick-link/verify'));

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authNotifierProvider.overrideWith(
              () => FakeDeepLinkAuthNotifier(
                onVerify: (token) => capturedToken = token,
              ),
            ),
          ],
          child: MaterialApp(
            home: AuthDeepLinkListener(
              appLinks: mockAppLinks,
              child: const SizedBox.shrink(),
            ),
          ),
        ),
      );
      await tester.pump();

      expect(capturedToken, isNull);
    });

    testWidgets('passes token to verifyMagicLink for valid initial link', (
      tester,
    ) async {
      String? capturedToken;

      when(() => mockAppLinks.getInitialLink()).thenAnswer(
        (_) async => Uri.parse('zedu://auth/magick-link/verify?token=t-123'),
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authNotifierProvider.overrideWith(
              () => FakeDeepLinkAuthNotifier(
                onVerify: (token) => capturedToken = token,
              ),
            ),
          ],
          child: MaterialApp(
            home: AuthDeepLinkListener(
              appLinks: mockAppLinks,
              child: const SizedBox.shrink(),
            ),
          ),
        ),
      );
      await tester.pump();

      expect(capturedToken, 't-123');
    });

    testWidgets('does not subscribe when disposed during the initial link', (
      tester,
    ) async {
      final initialLink = Completer<Uri?>();
      when(
        () => mockAppLinks.getInitialLink(),
      ).thenAnswer((_) => initialLink.future);

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: AuthDeepLinkListener(
              appLinks: mockAppLinks,
              child: const SizedBox.shrink(),
            ),
          ),
        ),
      );

      // Dispose while the initial link is still loading.
      await tester.pumpWidget(const SizedBox.shrink());
      initialLink.complete(null);
      await tester.pump();

      verifyNever(() => mockAppLinks.uriLinkStream);
    });
  });
}
