import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:zedu/core/core.dart';

void main() {
  group('AppHotkey', () {
    test('defaults to Ctrl + Shift + Z', () {
      expect(AppHotkey.defaults.key, 'z');
      expect(AppHotkey.defaults.modifiers, {
        HotKeyModifier.control,
        HotKeyModifier.shift,
      });
    });

    test('round-trips through encode and tryParse', () {
      const hotkey = AppHotkey(
        key: 'k',
        modifiers: {HotKeyModifier.control, HotKeyModifier.alt},
      );

      final parsed = AppHotkey.tryParse(hotkey.encode());

      expect(parsed, isNotNull);
      expect(parsed!.key, 'k');
      expect(parsed.modifiers, {HotKeyModifier.control, HotKeyModifier.alt});
    });

    test('rejects malformed or unusable shortcuts', () {
      expect(AppHotkey.tryParse(null), isNull);
      expect(AppHotkey.tryParse(''), isNull);
      expect(AppHotkey.tryParse('not json'), isNull);
      expect(
        AppHotkey.tryParse('{"key":"z","modifiers":[]}'),
        isNull,
        reason: 'a shortcut needs at least one modifier',
      );
      expect(
        AppHotkey.tryParse('{"key":"escape","modifiers":["control"]}'),
        isNull,
        reason: 'only letters, digits and space are supported',
      );
      expect(AppHotkey.tryParse('{"key":"z","modifiers":["hyper"]}'), isNull);
    });

    test('accepts letters, digits and space only', () {
      expect(AppHotkey.isSupportedKey('a'), isTrue);
      expect(AppHotkey.isSupportedKey('7'), isTrue);
      expect(AppHotkey.isSupportedKey(' '), isTrue);
      expect(AppHotkey.isSupportedKey('escape'), isFalse);
      expect(AppHotkey.isSupportedKey('ab'), isFalse);
    });

    test('formats a readable label', () {
      const hotkey = AppHotkey(
        key: ' ',
        modifiers: {HotKeyModifier.control, HotKeyModifier.shift},
      );

      expect(hotkey.label, 'Ctrl + Shift + Space');
    });

    test('maps the key to the code each desktop platform expects', () {
      const hotkey = AppHotkey(key: 'z', modifiers: {HotKeyModifier.control});

      if (Platform.isMacOS) {
        expect(hotkey.platformKeyCode, 0x06);
      } else if (Platform.isWindows) {
        expect(hotkey.platformKeyCode, 'Z'.codeUnitAt(0));
      } else {
        expect(hotkey.platformKeyCode, 'z'.codeUnitAt(0));
      }
    });

    test('builds a system-scoped HotKey with a stable identifier', () {
      final hotKey = AppHotkey.defaults.toHotKey();

      expect(hotKey.identifier, 'zedu-toggle-window');
      expect(hotKey.scope, HotKeyScope.system);
      expect(hotKey.modifiers, [HotKeyModifier.control, HotKeyModifier.shift]);
      expect(hotKey.key, isA<PhysicalKeyboardKey>());
    });
  });
}
