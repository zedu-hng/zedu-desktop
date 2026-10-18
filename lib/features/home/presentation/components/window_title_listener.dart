import 'package:zedu/core/core.dart';
import 'package:zedu/features/features.dart';

/// Keeps the desktop window title in sync with the unread count.
class WindowTitleListener extends ConsumerStatefulWidget {
  const WindowTitleListener({super.key, required this.child});

  final Widget child;

  @override
  ConsumerState<WindowTitleListener> createState() =>
      _WindowTitleListenerState();
}

class _WindowTitleListenerState extends ConsumerState<WindowTitleListener> {
  @override
  void initState() {
    super.initState();
    ref.listenManual<String>(
      windowTitleProvider,
      (previous, next) => _applyTitle(next),
      fireImmediately: true,
    );
  }

  Future<void> _applyTitle(String title) async {
    try {
      await windowManager.setTitle(title);
    } catch (e) {
      AppLogger.w('Failed to set window title: $e', tag: 'WindowTitleListener');
    }
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
