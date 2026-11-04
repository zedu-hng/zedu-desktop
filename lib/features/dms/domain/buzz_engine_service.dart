import 'package:zedu/core/core.dart';

final buzzEngineProvider = Provider<BuzzEngineService>((ref) {
  return BuzzEngineService();
});

/// A capture or playback device reported by the RTC engine.
class CallEngineDevice {
  final String id;
  final String label;

  const CallEngineDevice({required this.id, required this.label});
}

class BuzzEngineService {
  late RtcEngine _engine;
  bool _isEngineInit = false;

  bool get isInitialized => _isEngineInit;

  Future<void> initEngine(String appId) async {
    if (_isEngineInit) return;
    _engine = createAgoraRtcEngine();
    await _engine.initialize(
      RtcEngineContext(
        appId: appId,
        channelProfile: ChannelProfileType.channelProfileCommunication,
      ),
    );
    _isEngineInit = true;
  }

  Future<void> joinChannel(String token, String channelName, int uid) async {
    if (!_isEngineInit) return;
    await _engine.enableVideo();
    await _engine.startPreview();
    await _engine.joinChannel(
      token: token,
      channelId: channelName,
      uid: uid,
      options: const ChannelMediaOptions(
        clientRoleType: ClientRoleType.clientRoleBroadcaster,
      ),
    );
  }

  Future<void> leaveChannel() async {
    if (!_isEngineInit) return;
    await _engine.leaveChannel();
  }

  Future<void> toggleMic(bool mute) async {
    if (!_isEngineInit) return;
    await _engine.muteLocalAudioStream(mute);
  }

  Future<void> toggleVideo(bool mute) async {
    if (!_isEngineInit) return;
    await _engine.muteLocalVideoStream(mute);
  }

  Future<List<CallEngineDevice>> enumerateMicrophones() async {
    if (!_isEngineInit) return const [];
    try {
      final devices = await _engine
          .getAudioDeviceManager()
          .enumerateRecordingDevices();
      return [
        for (final device in devices)
          if (device.deviceId != null && device.deviceId!.isNotEmpty)
            CallEngineDevice(
              id: device.deviceId!,
              label: device.deviceName ?? device.deviceId!,
            ),
      ];
    } catch (error) {
      debugPrint('Could not list microphones: $error');
      return const [];
    }
  }

  Future<List<CallEngineDevice>> enumerateSpeakers() async {
    if (!_isEngineInit) return const [];
    try {
      final devices = await _engine
          .getAudioDeviceManager()
          .enumeratePlaybackDevices();
      return [
        for (final device in devices)
          if (device.deviceId != null && device.deviceId!.isNotEmpty)
            CallEngineDevice(
              id: device.deviceId!,
              label: device.deviceName ?? device.deviceId!,
            ),
      ];
    } catch (error) {
      debugPrint('Could not list speakers: $error');
      return const [];
    }
  }

  Future<List<CallEngineDevice>> enumerateCameras() async {
    if (!_isEngineInit) return const [];
    try {
      final devices = await _engine
          .getVideoDeviceManager()
          .enumerateVideoDevices();
      return [
        for (final device in devices)
          if (device.deviceId != null && device.deviceId!.isNotEmpty)
            CallEngineDevice(
              id: device.deviceId!,
              label: device.deviceName ?? device.deviceId!,
            ),
      ];
    } catch (error) {
      debugPrint('Could not list cameras: $error');
      return const [];
    }
  }

  Future<void> selectMicrophone(String deviceId) async {
    if (!_isEngineInit) return;
    await _engine.getAudioDeviceManager().setRecordingDevice(deviceId);
  }

  Future<void> selectSpeaker(String deviceId) async {
    if (!_isEngineInit) return;
    await _engine.getAudioDeviceManager().setPlaybackDevice(deviceId);
  }

  Future<void> selectCamera(String deviceId) async {
    if (!_isEngineInit) return;
    await _engine.getVideoDeviceManager().setDevice(deviceId);
  }

  void registerEventHandler(RtcEngineEventHandler handler) {
    if (!_isEngineInit) return;
    _engine.registerEventHandler(handler);
  }

  void unregisterEventHandler(RtcEngineEventHandler handler) {
    if (!_isEngineInit) return;
    _engine.unregisterEventHandler(handler);
  }

  Future<void> dispose() async {
    if (_isEngineInit) {
      await _engine.release();
      _isEngineInit = false;
    }
  }
}
