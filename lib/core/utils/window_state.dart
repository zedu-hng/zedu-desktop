import 'dart:async';
import 'dart:convert';

import 'package:screen_retriever/screen_retriever.dart';
import 'package:zedu/core/core.dart';

class WindowState {
  const WindowState({
    required this.bounds,
    required this.isMaximized,
    required this.displayId,
  });

  final Rect bounds;
  final bool isMaximized;
  final String displayId;

  static const double minWidth = 400;
  static const double minHeight = 300;
  static const double maxExtent = 20000;

  String encode() => jsonEncode({
    'left': bounds.left,
    'top': bounds.top,
    'width': bounds.width,
    'height': bounds.height,
    'maximized': isMaximized,
    'displayId': displayId,
  });

  static WindowState? tryParse(String? raw) {
    if (raw == null || raw.isEmpty) return null;
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map<String, dynamic>) return null;
      final left = (decoded['left'] as num?)?.toDouble();
      final top = (decoded['top'] as num?)?.toDouble();
      final width = (decoded['width'] as num?)?.toDouble();
      final height = (decoded['height'] as num?)?.toDouble();
      final displayId = decoded['displayId'];
      if (left == null ||
          top == null ||
          width == null ||
          height == null ||
          displayId is! String ||
          displayId.isEmpty) {
        return null;
      }
      final values = [left, top, width, height];
      if (!values.every((value) => value.isFinite)) return null;
      if (width < minWidth ||
          height < minHeight ||
          width > maxExtent ||
          height > maxExtent ||
          left.abs() > maxExtent ||
          top.abs() > maxExtent) {
        return null;
      }
      return WindowState(
        bounds: Rect.fromLTWH(left, top, width, height),
        isMaximized: decoded['maximized'] == true,
        displayId: displayId,
      );
    } on FormatException {
      return null;
    }
  }
}

Rect clampBoundsToDisplay(Rect bounds, Rect display) {
  final maxWidth = display.width < WindowState.maxExtent
      ? display.width
      : WindowState.maxExtent;
  final maxHeight = display.height < WindowState.maxExtent
      ? display.height
      : WindowState.maxExtent;
  final width = bounds.width.clamp(WindowState.minWidth, maxWidth).toDouble();
  final height = bounds.height
      .clamp(WindowState.minHeight, maxHeight)
      .toDouble();
  final left = bounds.left
      .clamp(display.left, display.right - width)
      .toDouble();
  final top = bounds.top.clamp(display.top, display.bottom - height).toDouble();
  return Rect.fromLTWH(left, top, width, height);
}

class WindowStateStore {
  WindowStateStore(this._storage);

  final SecureStorageService _storage;

  static const _storageKeyPrefix = 'desktop_window_state.';
  static const _lastDisplayKey = 'desktop_window_state.last_display';

  Future<void> restore() async {
    try {
      final displays = await screenRetriever.getAllDisplays();
      if (displays.isEmpty) return;

      final lastDisplayId = await _storage.readData(_lastDisplayKey);
      if (lastDisplayId == null || lastDisplayId.isEmpty) return;

      final state = WindowState.tryParse(
        await _storage.readData('$_storageKeyPrefix$lastDisplayId'),
      );
      if (state == null) return;

      final display = _displayMatching(state, displays) ?? displays.first;
      final area = _visibleArea(display);
      if (state.isMaximized) {
        await windowManager.maximize();
      } else {
        await windowManager.setBounds(clampBoundsToDisplay(state.bounds, area));
      }
    } catch (error, stackTrace) {
      AppLogger.w(
        'Failed to restore window state',
        tag: 'WindowStateStore',
        error: error,
        stackTrace: stackTrace,
      );
    }
  }

  Future<void> save() async {
    try {
      final displays = await screenRetriever.getAllDisplays();
      if (displays.isEmpty) return;

      final bounds = await windowManager.getBounds();
      final display = _displayForBounds(bounds, displays);
      final isMaximized = await windowManager.isMaximized();
      final state = WindowState(
        bounds: bounds,
        isMaximized: isMaximized,
        displayId: display.id,
      );
      await _storage.writeData(
        '$_storageKeyPrefix${display.id}',
        state.encode(),
      );
      await _storage.writeData(_lastDisplayKey, display.id);
    } catch (error, stackTrace) {
      AppLogger.w(
        'Failed to save window state',
        tag: 'WindowStateStore',
        error: error,
        stackTrace: stackTrace,
      );
    }
  }

  static Display? _displayMatching(WindowState state, List<Display> displays) {
    for (final display in displays) {
      if (display.id == state.displayId) return display;
    }
    return null;
  }

  static Display _displayForBounds(Rect bounds, List<Display> displays) {
    Display best = displays.first;
    var bestOverlap = -1.0;
    for (final display in displays) {
      final overlap = bounds.intersect(_visibleArea(display));
      final area = overlap.width * overlap.height;
      if (area > bestOverlap) {
        bestOverlap = area;
        best = display;
      }
    }
    return best;
  }

  static Rect _visibleArea(Display display) {
    final position = display.visiblePosition ?? Offset.zero;
    final size = display.visibleSize ?? display.size;
    return position & size;
  }
}

class WindowStateTracker with WindowListener {
  WindowStateTracker(this._store);

  final WindowStateStore _store;
  Timer? _saveTimer;

  void attach() => windowManager.addListener(this);

  void detach() {
    _saveTimer?.cancel();
    windowManager.removeListener(this);
  }

  void _scheduleSave() {
    _saveTimer?.cancel();
    _saveTimer = Timer(const Duration(milliseconds: 500), _store.save);
  }

  @override
  void onWindowResize() => _scheduleSave();

  @override
  void onWindowResized() => _scheduleSave();

  @override
  void onWindowMove() => _scheduleSave();

  @override
  void onWindowMoved() => _scheduleSave();

  @override
  void onWindowMaximize() => _scheduleSave();

  @override
  void onWindowUnmaximize() => _scheduleSave();
}
