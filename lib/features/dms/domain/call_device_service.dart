import 'package:zedu/core/core.dart';
import 'buzz_engine_service.dart';

enum CallDeviceKind {
  microphone('Microphone'),
  camera('Camera'),
  speaker('Speaker');

  const CallDeviceKind(this.label);

  final String label;
}

const String systemDefaultDeviceId = 'system-default';

class CallDevice {
  final String id;
  final String label;
  final CallDeviceKind kind;

  const CallDevice({required this.id, required this.label, required this.kind});

  bool get isSystemDefault => id == systemDefaultDeviceId;

  @override
  bool operator ==(Object other) =>
      other is CallDevice && other.kind == kind && other.id == id;

  @override
  int get hashCode => Object.hash(kind, id);

  @override
  String toString() => 'CallDevice(${kind.name}, $id)';
}

CallDevice systemDefaultDevice(CallDeviceKind kind) =>
    CallDevice(id: systemDefaultDeviceId, label: 'System default', kind: kind);

final callDeviceServiceProvider = Provider<CallDeviceService>((ref) {
  return CallDeviceService(ref.watch(buzzEngineProvider));
});

/// Lists the devices a call can use and switches the RTC engine to them.
class CallDeviceService {
  CallDeviceService(
    this._engine, {
    Future<List<CallEngineDevice>> Function()? microphoneFallback,
  }) : _microphoneFallback = microphoneFallback;

  final BuzzEngineService _engine;
  final Future<List<CallEngineDevice>> Function()? _microphoneFallback;

  Future<List<CallDevice>> listDevices(CallDeviceKind kind) async {
    final devices = switch (kind) {
      CallDeviceKind.microphone => await _microphones(),
      CallDeviceKind.camera => _toCallDevices(
        await _engine.enumerateCameras(),
        kind,
      ),
      CallDeviceKind.speaker => _toCallDevices(
        await _engine.enumerateSpeakers(),
        kind,
      ),
    };
    return [systemDefaultDevice(kind), ...devices];
  }

  Future<void> apply({
    CallDevice? microphone,
    CallDevice? camera,
    CallDevice? speaker,
  }) async {
    if (microphone != null && !microphone.isSystemDefault) {
      await _guard(() => _engine.selectMicrophone(microphone.id));
    }
    if (camera != null && !camera.isSystemDefault) {
      await _guard(() => _engine.selectCamera(camera.id));
    }
    if (speaker != null && !speaker.isSystemDefault) {
      await _guard(() => _engine.selectSpeaker(speaker.id));
    }
  }

  Future<List<CallDevice>> _microphones() async {
    final engineDevices = await _engine.enumerateMicrophones();
    if (engineDevices.isNotEmpty) {
      return _toCallDevices(engineDevices, CallDeviceKind.microphone);
    }
    // The RTC engine is not initialized until a call joins, so fall back to
    // the platform recorder for the pre-join list.
    return _toCallDevices(
      await (_microphoneFallback ?? _recorderMicrophones)(),
      CallDeviceKind.microphone,
    );
  }

  Future<List<CallEngineDevice>> _recorderMicrophones() async {
    final recorder = AudioRecorder();
    try {
      final inputs = await recorder.listInputDevices();
      return [
        for (final input in inputs)
          if (input.id.isNotEmpty && input.id != systemDefaultDeviceId)
            CallEngineDevice(
              id: input.id,
              label: input.label.isEmpty ? input.id : input.label,
            ),
      ];
    } catch (error) {
      debugPrint('Could not list microphones: $error');
      return const [];
    } finally {
      try {
        await recorder.dispose();
      } catch (error) {
        debugPrint('Could not release the microphone lister: $error');
      }
    }
  }

  List<CallDevice> _toCallDevices(
    List<CallEngineDevice> devices,
    CallDeviceKind kind,
  ) {
    final seen = <String>{};
    return [
      for (final device in devices)
        if (device.id != systemDefaultDeviceId && seen.add(device.id))
          CallDevice(id: device.id, label: device.label, kind: kind),
    ];
  }

  Future<void> _guard(Future<void> Function() action) async {
    try {
      await action();
    } catch (error) {
      debugPrint('Could not switch call device: $error');
    }
  }
}
