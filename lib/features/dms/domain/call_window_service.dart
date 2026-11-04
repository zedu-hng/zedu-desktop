import 'package:zedu/core/core.dart';

final callWindowServiceProvider = Provider<CallWindowService>((ref) {
  return CallWindowService();
});

/// Keeps the app window above other apps while the mini call window is open.
class CallWindowService {
  Future<void> setAlwaysOnTop(bool value) async {
    try {
      await windowManager.setAlwaysOnTop(value);
    } catch (error) {
      debugPrint('Could not change always-on-top: $error');
    }
  }
}
