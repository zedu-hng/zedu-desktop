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
    _state = _state.copyWith(isFullPage: isFullPage);
    notifyListeners();
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
  }
}

final activeCallProvider = ChangeNotifierProvider<ActiveCallNotifier>((ref) {
  final notifier = ActiveCallNotifier(ref);
  // Nothing called receiveIncomingCall, so the incoming-call modal could never
  // show (Ziki #2917). Turn an `incoming` event from the repository's call
  // events into the incoming-call state, and stop when the provider goes away.
  final subscription = ref.read(buzzRepositoryProvider).callEvents.listen((
    event,
  ) {
    if (event['type'] != 'incoming') return;
    notifier.receiveIncomingCall(
      buzzId: '${event['buzzId'] ?? ''}',
      remoteUserId: '${event['remoteUserId'] ?? ''}',
      remoteUserName: '${event['remoteUserName'] ?? ''}',
      channelId: '${event['channelId'] ?? ''}',
      remoteAvatarUrl: event['remoteAvatarUrl'] as String?,
    );
  });
  ref.onDispose(subscription.cancel);
  return notifier;
});
