import 'package:flutter_test/flutter_test.dart';
import 'package:zedu/core/core.dart';

void main() {
  group('formatAiCredits', () {
    test('uses the singular for exactly one credit', () {
      expect(formatAiCredits(1), '1 AI credit');
    });

    test('uses the plural for zero and more than one', () {
      expect(formatAiCredits(0), '0 AI credits');
      expect(formatAiCredits(2), '2 AI credits');
    });

    test('adds thousands separators', () {
      expect(formatAiCredits(999), '999 AI credits');
      expect(formatAiCredits(1000), '1,000 AI credits');
      expect(formatAiCredits(1250000), '1,250,000 AI credits');
    });

    test('keeps the sign for a negative balance', () {
      expect(formatAiCredits(-1), '-1 AI credit');
      expect(formatAiCredits(-1500), '-1,500 AI credits');
    });
  });
}
