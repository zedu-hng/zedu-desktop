import 'dart:async';

import 'package:zedu/core/core.dart';
import 'package:zedu/features/features.dart';

enum CallStatus { none, calling, incoming, active }

class ActiveCallState {
  final CallStatus status;
  final String? buzzId;
  final String? channelId;
  final String? remoteUserName;
  final String? remoteUserId;
  final String? remoteAvatarUrl;
  final String? token;
  final bool isFullPage;
  final bool isMiniWindow;
  final bool isMuted;
  final bool isVideoOff;
  final bool isHandRaised;
  final DateTime? lastCallAt;

  const ActiveCallState({
    this.status = CallStatus.none,
    this.buzzId,
    this.channelId,
    this.remoteUserName,
    this.remoteUserId,
    this.remoteAvatarUrl,
    this.token,
    this.isFullPage = false,
    this.isMiniWindow = false,
    this.isMuted = false,
    this.isVideoOff = false,
    this.isHandRaised = false,
    this.lastCallAt,
  });

  ActiveCallState copyWith({
    CallStatus? status,
    String? buzzId,
    String? channelId,
    String? remoteUserName,
    String? remoteUserId,
    String? remoteAvatarUrl,
    String? token,
    bool? isFullPage,
    bool? isMiniWindow,
    bool? isMuted,
    bool? isVideoOff,
    bool? isHandRaised,
    DateTime? lastCallAt,
  }) {
    return ActiveCallState(
      status: status ?? this.status,
      buzzId: buzzId ?? this.buzzId,
      channelId: channelId ?? this.channelId,
      remoteUserName: remoteUserName ?? this.remoteUserName,
      remoteUserId: remoteUserId ?? this.remoteUserId,
      remoteAvatarUrl: remoteAvatarUrl ?? this.remoteAvatarUrl,
      token: token ?? this.token,
      isFullPage: isFullPage ?? this.isFullPage,
      isMiniWindow: isMiniWindow ?? this.isMiniWindow,
      isMuted: isMuted ?? this.isMuted,
      isVideoOff: isVideoOff ?? this.isVideoOff,
      isHandRaised: isHandRaised ?? this.isHandRaised,
      lastCallAt: lastCallAt ?? this.lastCallAt,
    );
  }
}

class ActiveCallNotifier extends ChangeNotifier {
  final Ref _ref;
  ActiveCallState _state = const ActiveCallState();

  ActiveCallNotifier(this._ref);

  ActiveCallState get state => _state;

  void setFullPage(bool isFullPage) {
    _state = _state.copyWith(
      isFullPage: isFullPage,
      isMiniWindow: isFullPage ? false : _state.isMiniWindow,
    );
    notifyListeners();
    unawaited(_applyAlwaysOnTop());
  }

  /// Shows the compact call card and pins the app window above other apps, so
  /// the call stays visible while the user works somewhere else.
  void setMiniWindow(bool isMiniWindow) {
    _state = _state.copyWith(
      isMiniWindow: isMiniWindow,
      isFullPage: isMiniWindow ? false : _state.isFullPage,
    );
    notifyListeners();
    unawaited(_applyAlwaysOnTop());
  }

  Future<void> setMuted(bool muted) async {
    if (_state.isMuted == muted) return;
    _state = _state.copyWith(isMuted: muted);
    notifyListeners();
    try {
      await _ref.read(buzzEngineProvider).toggleMic(muted);
    } catch (error) {
      debugPrint('Could not change microphone state: $error');
    }
  }

  Future<void> setVideoOff(bool videoOff) async {
    if (_state.isVideoOff == videoOff) return;
    _state = _state.copyWith(isVideoOff: videoOff);
    notifyListeners();
    try {
      await _ref.read(buzzEngineProvider).toggleVideo(videoOff);
    } catch (error) {
      debugPrint('Could not change camera state: $error');
    }
  }

  void setHandRaised(bool raised) {
    if (_state.isHandRaised == raised) return;
    _state = _state.copyWith(isHandRaised: raised);
    notifyListeners();
  }

  Future<void> _applyAlwaysOnTop() async {
    await _ref
        .read(callWindowServiceProvider)
        .setAlwaysOnTop(_state.isMiniWindow);
  }

  Future<void> initiateCall({
    required String remoteUserId,
    required String remoteUserName,
    required String channelId,
    String? remoteAvatarUrl,
  }) async {
    _state = ActiveCallState(
      status: CallStatus.calling,
      channelId: channelId,
      remoteUserId: remoteUserId,
      remoteUserName: remoteUserName,
      remoteAvatarUrl: remoteAvatarUrl,
      lastCallAt: DateTime.now(),
    );
    notifyListeners();

    try {
      final repo = _ref.read(buzzRepositoryProvider);
      final res = await repo.initiateDirectCall(remoteUserId);
      final buzzId = res['buzzId'] as String?;
      final token = res['token'] as String?;

      _state = _state.copyWith(buzzId: buzzId, token: token);
      notifyListeners();

      Future<void>.delayed(const Duration(seconds: 3), () {
        if (_state.status == CallStatus.calling && _state.buzzId == buzzId) {
          _state = _state.copyWith(status: CallStatus.active);
          notifyListeners();
        }
      });
    } catch (e) {
      endCall();
    }
  }

  void receiveIncomingCall({
    required String buzzId,
    required String remoteUserId,
    required String remoteUserName,
    required String channelId,
    String? remoteAvatarUrl,
  }) {
    if (_state.status != CallStatus.none) {
      _ref.read(buzzRepositoryProvider).respondToInvitation(buzzId, false);
      return;
    }

    _state = ActiveCallState(
      status: CallStatus.incoming,
      buzzId: buzzId,
      channelId: channelId,
      remoteUserId: remoteUserId,
      remoteUserName: remoteUserName,
      remoteAvatarUrl: remoteAvatarUrl,
      isFullPage: false,
      lastCallAt: DateTime.now(),
    );
    notifyListeners();
  }

  Future<void> acceptCall() async {
    if (_state.status != CallStatus.incoming) return;

    if (_state.buzzId != null) {
      await _ref
          .read(buzzRepositoryProvider)
          .respondToInvitation(_state.buzzId!, true);
      _state = _state.copyWith(
        status: CallStatus.active,
        token: 'mock-agora-token',
      );
      notifyListeners();
    }
  }

  Future<void> declineCall() async {
    if (_state.status != CallStatus.incoming) return;

    if (_state.buzzId != null) {
      await _ref
          .read(buzzRepositoryProvider)
          .respondToInvitation(_state.buzzId!, false);
    }
    endCall();
  }

  Future<void> cancelCall() async {
    if (_state.status != CallStatus.calling) return;

    if (_state.buzzId != null) {
      await _ref
          .read(buzzRepositoryProvider)
          .respondToDirectCall(_state.buzzId!, false);
    }
    endCall();
  }

  void endCall() {
    _state = ActiveCallState(lastCallAt: _state.lastCallAt);
    notifyListeners();
    unawaited(_applyAlwaysOnTop());
  }
}

final activeCallProvider = ChangeNotifierProvider<ActiveCallNotifier>((ref) {
  return ActiveCallNotifier(ref);
});
