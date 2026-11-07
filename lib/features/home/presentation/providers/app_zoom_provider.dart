import 'package:zedu/core/core.dart';

/// Zoom levels the app steps through with Ctrl/Cmd + and -.
const appZoomLevels = [0.8, 0.9, 1.0, 1.1, 1.25, 1.5];

/// The next zoom level [direction] steps (+1 in, -1 out) from [current],
/// staying within [appZoomLevels].
double stepAppZoom(double current, int direction) {
  var index = appZoomLevels.indexWhere((z) => (z - current).abs() < 0.001);
  if (index == -1) index = appZoomLevels.indexOf(1.0);
  final next = (index + direction).clamp(0, appZoomLevels.length - 1);
  return appZoomLevels[next];
}

class AppZoomNotifier extends Notifier<double> {
  static const storageKey = 'app_zoom_level';

  @override
  double build() {
    _restore();
    return 1.0;
  }

  Future<void> _restore() async {
    final raw = await locator<SecureStorageService>().readData(storageKey);
    final saved = double.tryParse(raw ?? '');
    if (saved != null && appZoomLevels.contains(saved)) state = saved;
  }

  Future<void> zoomIn() => _set(stepAppZoom(state, 1));

  Future<void> zoomOut() => _set(stepAppZoom(state, -1));

  Future<void> reset() => _set(1.0);

  Future<void> _set(double zoom) async {
    state = zoom;
    await locator<SecureStorageService>().writeData(
      storageKey,
      zoom.toString(),
    );
  }
}

final appZoomProvider = NotifierProvider<AppZoomNotifier, double>(
  AppZoomNotifier.new,
);
