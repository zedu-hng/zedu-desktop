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
    testWidgets('shows a coming soon state with the title and balance', (
      tester,
    ) async {
      await tester.binding.setSurfaceSize(const Size(1440, 1024));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(buildReferralViewUnderTest());
      await tester.pump();

      expect(find.text('Referrals & Rewards'), findsOneWidget);
      expect(find.text('0 Credits'), findsOneWidget);
      expect(find.text('Referrals are coming soon'), findsOneWidget);
      expect(find.textContaining('invite teammates to Zedu'), findsOneWidget);
    });

    testWidgets('offers no referral link or credit promise', (tester) async {
      await tester.binding.setSurfaceSize(const Size(1440, 1024));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(buildReferralViewUnderTest());
      await tester.pump();

      expect(find.text('Copy Link'), findsNothing);
      expect(find.textContaining('zedu.chat/join'), findsNothing);
      expect(find.textContaining('50 Credits'), findsNothing);
      expect(find.textContaining('earn'), findsNothing);
      expect(find.text('Total Invited'), findsNothing);
    });

    testWidgets('fits a small window without overflowing', (tester) async {
      await tester.binding.setSurfaceSize(const Size(640, 480));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(buildReferralViewUnderTest());
      await tester.pump();

      expect(tester.takeException(), isNull);
      expect(find.text('Referrals are coming soon'), findsOneWidget);
    });
  });
}
