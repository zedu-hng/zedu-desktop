import 'package:zedu/core/core.dart';
import 'package:zedu/features/features.dart';

class CallDevicesState {
  final bool isLoading;
  final Map<CallDeviceKind, List<CallDevice>> devices;
  final Map<CallDeviceKind, CallDevice> selected;
  final String? error;

  const CallDevicesState({
    this.isLoading = false,
    this.devices = const {},
    this.selected = const {},
    this.error,
  });

  CallDevicesState copyWith({
    bool? isLoading,
    Map<CallDeviceKind, List<CallDevice>>? devices,
    Map<CallDeviceKind, CallDevice>? selected,
    String? error,
  }) {
    return CallDevicesState(
      isLoading: isLoading ?? this.isLoading,
      devices: devices ?? this.devices,
      selected: selected ?? this.selected,
      error: error ?? this.error,
    );
  }
}

class CallDevicesNotifier extends ChangeNotifier {
  final Ref _ref;
  CallDevicesState _state = const CallDevicesState();

  CallDevicesNotifier(this._ref);

  CallDevicesState get state => _state;

  CallDevice selectedFor(CallDeviceKind kind) =>
      _state.selected[kind] ?? systemDefaultDevice(kind);

  Future<void> load() async {
    if (_state.isLoading) return;
    _state = _state.copyWith(isLoading: true, error: null);
    notifyListeners();

    final service = _ref.read(callDeviceServiceProvider);
    final devices = <CallDeviceKind, List<CallDevice>>{};
    try {
      for (final kind in CallDeviceKind.values) {
        devices[kind] = await service.listDevices(kind);
      }
      final selected = <CallDeviceKind, CallDevice>{};
      for (final kind in CallDeviceKind.values) {
        final previous = _state.selected[kind];
        final available = devices[kind]!;
        selected[kind] = available.firstWhere(
          (device) => device == previous,
          orElse: () => available.first,
        );
      }
      _state = CallDevicesState(devices: devices, selected: selected);
    } catch (error) {
      _state = _state.copyWith(isLoading: false, error: '$error');
    }
    notifyListeners();
  }

  Future<void> select(CallDeviceKind kind, CallDevice device) async {
    if (device.kind != kind) return;
    _state = CallDevicesState(
      isLoading: _state.isLoading,
      devices: _state.devices,
      selected: {..._state.selected, kind: device},
    );
    notifyListeners();
    await applyToEngine();
  }

  /// Pushes the current selection to the RTC engine before a call joins.
  Future<void> applyToEngine() async {
    await _ref
        .read(callDeviceServiceProvider)
        .apply(
          microphone: selectedFor(CallDeviceKind.microphone),
          camera: selectedFor(CallDeviceKind.camera),
          speaker: selectedFor(CallDeviceKind.speaker),
        );
  }
}

final callDevicesProvider = ChangeNotifierProvider<CallDevicesNotifier>((ref) {
  return CallDevicesNotifier(ref);
});
