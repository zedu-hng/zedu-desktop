// Widget tests for the Zedu desktop application.
// Run with: flutter test

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('Credit formatting logic test', () {
    // Test your logic directly or via your component helper
    num credits = 1000000;
    final formatted = credits >= 1000000 ? '${(credits / 1000000).toStringAsFixed(0)}M' : credits.toString();

    print('TEST RESULT: 1000000 formatted as -> $formatted');
    expect(formatted, '1M');
  });
}
