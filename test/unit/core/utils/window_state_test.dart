import 'package:flutter_test/flutter_test.dart';
import 'package:zedu/core/core.dart';

const _display = Rect.fromLTWH(0, 0, 2560, 1440);

String _encoded({
  double left = 120,
  double top = 80,
  double width = 1280,
  double height = 800,
  bool maximized = false,
}) => WindowState(
  bounds: Rect.fromLTWH(left, top, width, height),
  isMaximized: maximized,
  displayId: 'display-1',
).encode();

void main() {
  group('WindowState', () {
    test('round-trips bounds, monitor and the maximized flag', () {
      final parsed = WindowState.tryParse(_encoded(maximized: true));

      expect(parsed, isNotNull);
      expect(parsed!.bounds, const Rect.fromLTWH(120, 80, 1280, 800));
      expect(parsed.isMaximized, isTrue);
      expect(parsed.displayId, 'display-1');
    });

    test('treats a missing maximized flag as not maximized', () {
      final parsed = WindowState.tryParse(
        '{"left":0,"top":0,"width":800,"height":600,"displayId":"d"}',
      );

      expect(parsed, isNotNull);
      expect(parsed!.isMaximized, isFalse);
    });

    test('rejects missing, empty and malformed values', () {
      expect(WindowState.tryParse(null), isNull);
      expect(WindowState.tryParse(''), isNull);
      expect(WindowState.tryParse('not json'), isNull);
      expect(WindowState.tryParse('[]'), isNull);
      expect(
        WindowState.tryParse('{"left":0,"top":0,"width":800,"height":600}'),
        isNull,
      );
      expect(
        WindowState.tryParse(
          '{"left":0,"top":0,"width":800,"height":600,"displayId":""}',
        ),
        isNull,
      );
    });

    test('rejects bounds that are too small to use', () {
      expect(WindowState.tryParse(_encoded(width: 320, height: 200)), isNull);
    });

    test('rejects implausible coordinates', () {
      expect(WindowState.tryParse(_encoded(left: 100000)), isNull);
    });
  });

  group('clampBoundsToDisplay', () {
    test('keeps a window that already fits unchanged', () {
      const bounds = Rect.fromLTWH(200, 100, 1000, 700);

      expect(clampBoundsToDisplay(bounds, _display), bounds);
    });

    test('pulls an off-screen window back onto the monitor', () {
      const bounds = Rect.fromLTWH(5000, 4000, 1000, 700);

      final clamped = clampBoundsToDisplay(bounds, _display);

      expect(clamped.right, lessThanOrEqualTo(_display.right));
      expect(clamped.bottom, lessThanOrEqualTo(_display.bottom));
      expect(clamped.left, greaterThanOrEqualTo(_display.left));
      expect(clamped.top, greaterThanOrEqualTo(_display.top));
      expect(clamped.size, bounds.size);
    });

    test('shrinks a window that is larger than the monitor', () {
      const bounds = Rect.fromLTWH(0, 0, 3000, 2000);

      final clamped = clampBoundsToDisplay(bounds, _display);

      expect(clamped.width, _display.width);
      expect(clamped.height, _display.height);
    });
  });
}
