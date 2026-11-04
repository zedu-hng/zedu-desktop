import 'dart:convert';
import 'dart:io';

import 'package:zedu/core/core.dart';

/// A window show/hide shortcut the user can change in Settings.
///
/// Only letters, digits and space are supported: every desktop platform wants
/// its own numeric code for a key, and those three groups are the ones the OS
/// hotkey APIs accept everywhere.
class AppHotkey {
  final String key;
  final Set<HotKeyModifier> modifiers;

  const AppHotkey({required this.key, required this.modifiers});

  static const AppHotkey defaults = AppHotkey(
    key: 'z',
    modifiers: {HotKeyModifier.control, HotKeyModifier.shift},
  );

  // Carbon virtual key codes used by macOS.
  static const Map<String, int> _carbonCodes = {
    'a': 0x00,
    's': 0x01,
    'd': 0x02,
    'f': 0x03,
    'h': 0x04,
    'g': 0x05,
    'z': 0x06,
    'x': 0x07,
    'c': 0x08,
    'v': 0x09,
    'b': 0x0B,
    'q': 0x0C,
    'w': 0x0D,
    'e': 0x0E,
    'r': 0x0F,
    'y': 0x10,
    't': 0x11,
    '1': 0x12,
    '2': 0x13,
    '3': 0x14,
    '4': 0x15,
    '6': 0x16,
    '5': 0x17,
    '9': 0x19,
    '7': 0x1A,
    '8': 0x1C,
    '0': 0x1D,
    'o': 0x1F,
    'u': 0x20,
    'i': 0x22,
    'p': 0x23,
    'l': 0x25,
    'j': 0x26,
    'k': 0x28,
    'n': 0x2D,
    'm': 0x2E,
    ' ': 0x31,
  };

  static bool isSupportedKey(String key) {
    if (key == ' ') return true;
    return key.length == 1 && RegExp(r'[a-z0-9]').hasMatch(key);
  }

  /// The numeric key code the OS wants, or null when the key has no mapping.
  int? get platformKeyCode {
    if (!isSupportedKey(key)) return null;
    if (Platform.isMacOS) return _carbonCodes[key];
    if (Platform.isWindows) return key.toUpperCase().codeUnitAt(0);
    // GTK accelerators take the logical keyval, which is the character's code.
    return key.codeUnitAt(0);
  }

  String get label {
    final parts = <String>[];
    for (final modifier in const [
      HotKeyModifier.control,
      HotKeyModifier.alt,
      HotKeyModifier.shift,
      HotKeyModifier.meta,
    ]) {
      if (modifiers.contains(modifier)) parts.add(_modifierLabel(modifier));
    }
    parts.add(key == ' ' ? 'Space' : key.toUpperCase());
    return parts.join(' + ');
  }

  static String _modifierLabel(HotKeyModifier modifier) {
    return switch (modifier) {
      HotKeyModifier.control => 'Ctrl',
      HotKeyModifier.alt => Platform.isMacOS ? 'Option' : 'Alt',
      HotKeyModifier.shift => 'Shift',
      HotKeyModifier.meta => Platform.isMacOS ? 'Cmd' : 'Win',
      _ => modifier.name,
    };
  }

  Map<String, dynamic> toJson() => {
    'key': key,
    'modifiers': modifiers.map((modifier) => modifier.name).toList(),
  };

  String encode() => jsonEncode(toJson());

  static AppHotkey? tryParse(String? raw) {
    if (raw == null || raw.isEmpty) return null;
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map<String, dynamic>) return null;
      final key = (decoded['key'] as String?)?.toLowerCase();
      if (key == null || !isSupportedKey(key)) return null;

      final modifiers = <HotKeyModifier>{};
      for (final name in decoded['modifiers'] as List<dynamic>? ?? const []) {
        HotKeyModifier? parsed;
        for (final modifier in HotKeyModifier.values) {
          if (modifier.name == name.toString()) parsed = modifier;
        }
        if (parsed == null) return null;
        modifiers.add(parsed);
      }
      if (modifiers.isEmpty) return null;
      return AppHotkey(key: key, modifiers: modifiers);
    } catch (_) {
      return null;
    }
  }

  HotKey toHotKey({String identifier = 'zedu-toggle-window'}) {
    final code = platformKeyCode;
    if (code == null) {
      throw UnsupportedError('No platform key code for "$key".');
    }
    return HotKey(
      identifier: identifier,
      key: PhysicalKeyboardKey(code),
      modifiers: modifiers.toList(),
      scope: HotKeyScope.system,
    );
  }
}

/// Registers the window shortcut with the OS and persists the user's choice.
class GlobalHotkeyService {
  GlobalHotkeyService(this._storage);

  static const String storageKey = 'desktop_global_hotkey';

  final SecureStorageService _storage;
  AppHotkey _current = AppHotkey.defaults;
  HotKey? _registered;
  bool _initialized = false;

  AppHotkey get current => _current;

  /// Whether the shortcut is actually registered with the OS.
  bool get isRegistered => _registered != null;

  Future<void> init() async {
    if (_initialized) return;
    _initialized = true;
    try {
      _current =
          AppHotkey.tryParse(await _storage.readData(storageKey)) ??
          AppHotkey.defaults;
    } catch (_) {
      _current = AppHotkey.defaults;
    }
    await _apply();
  }

  /// Registers [hotkey], replacing the previous one. Returns false when the
  /// OS refuses it (usually because another app already owns the combination).
  Future<bool> setHotkey(AppHotkey hotkey) async {
    final previous = _current;
    _current = hotkey;
    if (await _apply()) {
      try {
        await _storage.writeData(storageKey, hotkey.encode());
      } catch (_) {
        // The shortcut still works this session; it just won't be remembered.
      }
      return true;
    }
    _current = previous;
    await _apply();
    return false;
  }

  Future<void> resetToDefaults() => setHotkey(AppHotkey.defaults);

  Future<bool> _apply() async {
    await _unregister();
    try {
      final hotkey = _current.toHotKey();
      await hotKeyManager.register(
        hotkey,
        keyDownHandler: (_) => _toggleWindow(),
      );
      _registered = hotkey;
      return true;
    } catch (error, stackTrace) {
      AppLogger.w(
        'Could not register the window shortcut',
        tag: 'GlobalHotkeyService',
        error: error,
        stackTrace: stackTrace,
      );
      return false;
    }
  }

  /// Stops listening while the user is picking a new combination, so pressing
  /// the current one does not hide the settings window.
  Future<void> pause() => _unregister();

  Future<void> resume() async {
    if (!_initialized || _registered != null) return;
    await _apply();
  }

  Future<void> _unregister() async {
    final registered = _registered;
    if (registered == null) return;
    _registered = null;
    try {
      await hotKeyManager.unregister(registered);
    } catch (_) {
      // The OS may already have dropped it (for example after an app restart).
    }
  }

  Future<void> _toggleWindow() async {
    try {
      if (await windowManager.isVisible()) {
        await windowManager.hide();
      } else {
        await windowManager.show();
        await windowManager.focus();
      }
    } catch (error, stackTrace) {
      AppLogger.w(
        'Could not toggle the window from the shortcut',
        tag: 'GlobalHotkeyService',
        error: error,
        stackTrace: stackTrace,
      );
    }
  }

  Future<void> dispose() => _unregister();
}
