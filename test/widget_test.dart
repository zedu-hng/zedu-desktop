import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zedu/features/features.dart';

Widget _buildCard(int credits) {
  return MaterialApp(
    home: Scaffold(
      body: Center(
        child: SizedBox(
          width: 400,
          height: 700,
          child: CreditPackageCard(
            package: CreditPackage(
              id: 'test',
              name: 'Test',
              description: 'Test package',
              price: 10,
              credits: credits,
              benefits: const ['Benefit'],
            ),
            accentColor: Colors.blue,
            isCurrentPlan: false,
            onPurchase: () {},
          ),
        ),
      ),
    ),
  );
}

void main() {
  group('CreditPackageCard credit formatting', () {
    testWidgets('shows 1M at exactly 1,000,000', (tester) async {
      await tester.pumpWidget(_buildCard(1000000));
      expect(find.text('1M AI credits included'), findsOneWidget);
    });

    testWidgets('shows 2.5M for 2,500,000', (tester) async {
      await tester.pumpWidget(_buildCard(2500000));
      expect(find.text('2.5M AI credits included'), findsOneWidget);
    });

    testWidgets('still shows 100K for 100,000', (tester) async {
      await tester.pumpWidget(_buildCard(100000));
      expect(find.text('100K AI credits included'), findsOneWidget);
    });
  });
}
