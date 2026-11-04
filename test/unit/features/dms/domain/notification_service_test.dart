import 'package:flutter_test/flutter_test.dart';
import 'package:zedu/features/features.dart';

void main() {
  group('truncateNotificationPreview', () {
    test('leaves short previews untouched', () {
      expect(truncateNotificationPreview('short message'), 'short message');
    });

    test('leaves a preview of exactly 80 characters untouched', () {
      final text = 'a'.padRight(80, 'a');
      expect(truncateNotificationPreview(text), text);
    });

    test('cuts a long ASCII preview to 77 characters plus an ellipsis', () {
      final result = truncateNotificationPreview('a'.padRight(100, 'a'));
      expect(result, '${'a'.padRight(77, 'a')}...');
      expect(result.length, 80);
    });

    test('never splits a surrogate pair at the cut', () {
      final text = '${'a'.padRight(76, 'a')}\u{1F600}${'b'.padRight(10, 'b')}';
      final result = truncateNotificationPreview(text);
      expect(result, '${'a'.padRight(76, 'a')}...');
      final unpaired = result.codeUnits.any(
        (unit) => unit >= 0xD800 && unit <= 0xDBFF,
      );
      expect(unpaired, isFalse);
    });

    test('the old slice split a surrogate pair, which is why this exists', () {
      final text = '${'a'.padRight(76, 'a')}\u{1F600}${'b'.padRight(10, 'b')}';
      final naive = text.substring(0, 77);
      expect(naive.codeUnits.last, inInclusiveRange(0xD800, 0xDBFF));
    });
  });
}
