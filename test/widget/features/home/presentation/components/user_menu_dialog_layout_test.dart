import 'package:zedu/core/core.dart';
import 'package:zedu/features/features.dart';

import '../../../../../helpers/helpers.dart';

/// The card only reads the auth state for its header, so a signed-out state is
/// enough to lay it out without touching the locator.
class _FakeAuthNotifier extends AuthNotifier {
  @override
  AuthState build() => const AuthState();
}

Widget _buildHost() {
  return ProviderScope(
    overrides: [
      authNotifierProvider.overrideWith(_FakeAuthNotifier.new),
      orgCreditBalanceProvider.overrideWithValue(0),
    ],
    child: buildTestMaterialApp(
      Scaffold(
        body: Builder(
          builder: (context) => Center(
            child: FilledButton(
              onPressed: () => showDialog<void>(
                context: context,
                builder: (_) => const UserMenuDialog(),
              ),
              child: const Text('open menu'),
            ),
          ),
        ),
      ),
    ),
  );
}

Future<void> _pumpOpenMenu(WidgetTester tester, Size size) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(_buildHost());
  await tester.pump();
  await tester.tap(find.text('open menu'));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('keeps a bounded card width beside the rail', (tester) async {
    await _pumpOpenMenu(tester, const Size(1280, 720));

    final card = tester.getRect(find.byKey(const ValueKey('user_menu_card')));
    expect(card.width, lessThanOrEqualTo(288));
    expect(card.width, greaterThanOrEqualTo(240));
    expect(card.left, AppSidebarRail.width + 8);
    expect(card.right, lessThan(1280));
    expect(card.bottom, lessThanOrEqualTo(720 - 24));
  });

  testWidgets('shrinks the card instead of overhanging a narrow window', (
    tester,
  ) async {
    await _pumpOpenMenu(tester, const Size(320, 720));

    final card = tester.getRect(find.byKey(const ValueKey('user_menu_card')));
    expect(card.width, 320 - AppSidebarRail.width - 8 - 16);
    expect(card.right, lessThanOrEqualTo(320 - 16));
  });
}
