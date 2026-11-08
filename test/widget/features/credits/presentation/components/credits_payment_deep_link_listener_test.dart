import 'dart:async';

import 'package:app_links/app_links.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:zedu/features/features.dart';

class MockAppLinks extends Mock implements AppLinks {}

class FakeCreditsNotifier extends CreditsNotifier {
  FakeCreditsNotifier({this.onVerifyPayment});

  final void Function(String sessionId, String orgId)? onVerifyPayment;

  @override
  CreditsState build() => const CreditsState();

  @override
  Future<bool> verifyPayment({
    required String sessionId,
    required String orgId,
  }) async {
    onVerifyPayment?.call(sessionId, orgId);
    return true;
  }
}

class FakeAuthNotifier extends AuthNotifier {
  @override
  AuthState build() => AuthState(
    status: AuthStatus.authenticated,
    user: User(
      id: 'u1',
      firstName: 'Test',
      lastName: 'User',
      email: 'test@example.com',
      phone: '1234567890',
      username: 'testuser',
      isVerified: true,
      isOnboarded: true,
      createdAt: DateTime(2026),
      currentOrg: 'org_123',
      currentOrganisationSlug: 'test-org',
      avatarUrl: '',
      defaultAvatarUrl: '',
    ),
  );
}

void main() {
  group('CreditsPaymentDeepLinkListener', () {
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

    testWidgets(
      'rejects untrusted host and does not trigger payment verification',
      (tester) async {
        String? verifiedSessionId;

        when(() => mockAppLinks.getInitialLink()).thenAnswer(
          (_) async => Uri.parse(
            'https://attacker.com/credits/payment-success?session_id=cs_evil_123',
          ),
        );

        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              authNotifierProvider.overrideWith(() => FakeAuthNotifier()),
              creditsNotifierProvider.overrideWith(
                () => FakeCreditsNotifier(
                  onVerifyPayment: (session, org) =>
                      verifiedSessionId = session,
                ),
              ),
            ],
            child: MaterialApp(
              home: CreditsPaymentDeepLinkListener(
                appLinks: mockAppLinks,
                child: const SizedBox.shrink(),
              ),
            ),
          ),
        );
        await tester.pump();

        expect(verifiedSessionId, isNull);
      },
    );

    testWidgets('accepts trusted host and triggers payment verification', (
      tester,
    ) async {
      String? verifiedSessionId;

      when(() => mockAppLinks.getInitialLink()).thenAnswer(
        (_) async => Uri.parse(
          'https://staging.zedu.chat/credits/payment-success?session_id=cs_valid_456',
        ),
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authNotifierProvider.overrideWith(() => FakeAuthNotifier()),
            creditsNotifierProvider.overrideWith(
              () => FakeCreditsNotifier(
                onVerifyPayment: (session, org) => verifiedSessionId = session,
              ),
            ),
          ],
          child: MaterialApp(
            home: CreditsPaymentDeepLinkListener(
              appLinks: mockAppLinks,
              child: const SizedBox.shrink(),
            ),
          ),
        ),
      );
      await tester.pump();
      expect(verifiedSessionId, 'cs_valid_456');

      // Allow toast timer to complete
      await tester.pump(const Duration(seconds: 5));
    });
  });
}
