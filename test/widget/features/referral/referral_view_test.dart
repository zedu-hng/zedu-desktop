import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zedu/features/features.dart';

class FakeAuthNotifier extends AuthNotifier {
  FakeAuthNotifier({
    AuthState initial = const AuthState(status: AuthStatus.unauthenticated),
  }) : _initial = initial;

  final AuthState _initial;

  @override
  AuthState build() => _initial;
}

Widget buildReferralViewUnderTest({FakeAuthNotifier? notifier}) {
  return ProviderScope(
    overrides: [
      authNotifierProvider.overrideWith(() => notifier ?? FakeAuthNotifier()),
    ],
    child: const MaterialApp(home: ReferralView()),
  );
}

void main() {
  group('ReferralView', () {
    testWidgets('renders title, hero banner, stats, and how it works', (
      tester,
    ) async {
      await tester.binding.setSurfaceSize(const Size(1440, 1024));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(buildReferralViewUnderTest());
      await tester.pump();

      // Top bar title
      expect(find.text('Referrals & Rewards'), findsOneWidget);

      // Hero banner
      expect(find.text('Invite Friends, Earn 50 Credits'), findsOneWidget);
      expect(find.text('Copy Link'), findsOneWidget);

      // Stats
      expect(find.text('Total Invited'), findsOneWidget);
      expect(find.text('Successful Signups'), findsOneWidget);
      expect(find.text('Credits Earned'), findsOneWidget);

      // How it works
      expect(find.text('How Referrals Work'), findsOneWidget);
      expect(find.text('Share your link'), findsOneWidget);
      expect(find.text('They join Zedu'), findsOneWidget);
      expect(find.text('Get rewarded'), findsOneWidget);

      // Empty state
      expect(find.text('No Referrals Yet'), findsOneWidget);
    });

    testWidgets('tapping copy link triggers toast notification', (
      tester,
    ) async {
      await tester.binding.setSurfaceSize(const Size(1440, 1024));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(buildReferralViewUnderTest());
      await tester.pump();

      final copyButton = find.text('Copy Link');
      expect(copyButton, findsOneWidget);

      await tester.tap(copyButton);
      await tester.pump();

      expect(find.text('Referral link copied to clipboard!'), findsOneWidget);
      await tester.pump(const Duration(seconds: 5));
    });
  });
}
