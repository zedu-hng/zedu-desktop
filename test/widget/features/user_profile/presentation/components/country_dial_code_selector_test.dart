import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zedu/features/features.dart';

import '../../../../../helpers/test_material_app.dart';

void main() {
  Future<void> openEditDialog(
    WidgetTester tester,
    ProfileAccount account,
  ) async {
    await tester.pumpWidget(
      buildTestMaterialApp(
        Builder(
          builder: (context) => Scaffold(
            body: Center(
              child: ElevatedButton(
                onPressed: () =>
                    showEditProfileDialog(context, account, (_) {}),
                child: const Text('open'),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
  }

  testWidgets('selecting a country writes its dial code into the phone field', (
    tester,
  ) async {
    await openEditDialog(tester, ProfileAccount.empty());

    expect(find.text('NG +234'), findsOneWidget);

    await tester.ensureVisible(find.byType(CountryDialCodeSelector));
    await tester.pump();

    await tester.tap(find.text('NG +234'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    await tester.tap(find.text('Nigeria'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    expect(find.text('+234 '), findsOneWidget);
  });

  testWidgets('existing phone value is left unchanged', (tester) async {
    const account = ProfileAccount(
      name: 'Test User',
      email: 'test@example.com',
      timezone: 'Africa/Lagos',
      phoneNumber: '+1 234 5678',
    );

    await openEditDialog(tester, account);

    expect(find.text('+1 234 5678'), findsOneWidget);
  });
}
