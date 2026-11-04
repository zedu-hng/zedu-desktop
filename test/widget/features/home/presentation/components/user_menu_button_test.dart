import 'package:zedu/core/core.dart';
import 'package:zedu/features/features.dart';

import '../../../../../helpers/helpers.dart';

void main() {
  testWidgets('user menu button shows a click cursor', (tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(
          home: Scaffold(body: Center(child: UserMenuButton())),
        ),
      ),
    );

    final cursor = tester
        .widget<MouseRegion>(
          find.descendant(
            of: find.byType(UserMenuButton),
            matching: find.byType(MouseRegion),
          ),
        )
        .cursor;

    expect(cursor, SystemMouseCursors.click);
  });
}
