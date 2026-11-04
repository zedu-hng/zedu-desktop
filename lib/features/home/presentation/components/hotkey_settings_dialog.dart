import 'dart:async';

import 'package:zedu/core/core.dart';

class HotkeySettingsDialog extends StatefulWidget {
  const HotkeySettingsDialog({super.key});

  @override
  State<HotkeySettingsDialog> createState() => _HotkeySettingsDialogState();
}

class _HotkeySettingsDialogState extends State<HotkeySettingsDialog> {
  final GlobalHotkeyService _service = locator<GlobalHotkeyService>();
  final FocusNode _captureFocus = FocusNode(debugLabel: 'hotkey-capture');

  AppHotkey? _candidate;
  String? _error;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    unawaited(_service.pause());
  }

  @override
  void dispose() {
    _captureFocus.dispose();
    unawaited(_service.resume());
    super.dispose();
  }

  void _capture(KeyEvent event) {
    if (event is! KeyDownEvent) return;
    final logicalKey = event.logicalKey;

    if (logicalKey == LogicalKeyboardKey.escape) {
      setState(() {
        _candidate = null;
        _error = null;
      });
      return;
    }

    final key = _keyChar(logicalKey);
    if (key == null) return;

    final keyboard = HardwareKeyboard.instance;
    final modifiers = <HotKeyModifier>{
      if (keyboard.isControlPressed) HotKeyModifier.control,
      if (keyboard.isAltPressed) HotKeyModifier.alt,
      if (keyboard.isShiftPressed) HotKeyModifier.shift,
      if (keyboard.isMetaPressed) HotKeyModifier.meta,
    };

    setState(() {
      _candidate = modifiers.isEmpty
          ? null
          : AppHotkey(key: key, modifiers: modifiers);
      _error = modifiers.isEmpty
          ? 'Hold Ctrl, Alt, Shift or Cmd while pressing the key.'
          : null;
    });
  }

  static String? _keyChar(LogicalKeyboardKey key) {
    if (key == LogicalKeyboardKey.space) return ' ';
    final label = key.keyLabel.toLowerCase();
    if (label.length == 1 && RegExp(r'[a-z0-9]').hasMatch(label)) return label;
    return null;
  }

  Future<void> _save() async {
    final candidate = _candidate;
    if (candidate == null || _saving) return;

    final messenger = ScaffoldMessenger.maybeOf(context);
    setState(() => _saving = true);
    final saved = await _service.setHotkey(candidate);
    if (!mounted) return;
    setState(() => _saving = false);

    if (saved) {
      Navigator.of(context).pop();
      messenger
        ?..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: Text('Press ${candidate.label} to show or hide Zedu.'),
          ),
        );
    } else {
      setState(() {
        _error =
            'That combination is already used by another app. Try a different one.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final displayed = _candidate ?? _service.current;

    return Dialog(
      backgroundColor: colors.background,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: SizedBox(
        width: 480,
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Keyboard shortcut',
                      style: context.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: colors.textPrimary,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.close, color: colors.textHint, size: 20),
                    splashRadius: 18,
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                'Show or hide Zedu from anywhere on your computer.',
                style: context.textTheme.bodyMedium?.copyWith(
                  color: colors.textSecondary,
                ),
              ),
              const SizedBox(height: 20),
              Focus(
                focusNode: _captureFocus,
                autofocus: true,
                onKeyEvent: (node, event) {
                  _capture(event);
                  return KeyEventResult.handled;
                },
                child: GestureDetector(
                  onTap: _captureFocus.requestFocus,
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 20),
                    decoration: BoxDecoration(
                      color: colors.primaryBg,
                      border: Border.all(
                        color: _error == null ? colors.primary : colors.error,
                      ),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      children: [
                        Text(
                          displayed.label,
                          style: context.textTheme.titleMedium?.copyWith(
                            color: colors.textPrimary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _candidate == null
                              ? 'Press a new combination'
                              : 'Press another combination to change it',
                          style: context.textTheme.bodySmall?.copyWith(
                            color: colors.textHint,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                _error ??
                    'Use at least one modifier with a letter, digit or Space.',
                style: context.textTheme.bodySmall?.copyWith(
                  color: _error == null ? colors.textHint : colors.error,
                ),
              ),
              const SizedBox(height: 12),
              TextButton(
                onPressed: _saving
                    ? null
                    : () => setState(() {
                        _candidate = AppHotkey.defaults;
                        _error = null;
                      }),
                style: TextButton.styleFrom(
                  foregroundColor: colors.primary,
                  padding: EdgeInsets.zero,
                  alignment: Alignment.centerLeft,
                ),
                child: const Text('Reset to default'),
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  OutlinedButton(
                    onPressed: _saving
                        ? null
                        : () => Navigator.of(context).pop(),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: colors.textPrimary,
                      side: BorderSide(color: colors.borderOutline),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 12,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text('Cancel'),
                  ),
                  const SizedBox(width: 12),
                  FilledButton(
                    onPressed: _candidate == null || _saving ? null : _save,
                    style: FilledButton.styleFrom(
                      backgroundColor: colors.primary,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 28,
                        vertical: 12,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: _saving
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Text(
                            'Save',
                            style: TextStyle(fontWeight: FontWeight.w600),
                          ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
