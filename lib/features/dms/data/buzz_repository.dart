import 'dart:async';

import 'package:zedu/core/core.dart';

final buzzRepositoryProvider = Provider<BuzzRepository>((ref) {
  final repository = BuzzRepository();
  ref.onDispose(repository.dispose);
  return repository;
});

class BuzzRepository {
  final _callEvents = StreamController<Map<String, dynamic>>.broadcast();

  /// Inbound call events. An event is `{ 'type': 'incoming', 'buzzId',
  /// 'remoteUserId', 'remoteUserName', 'channelId', 'remoteAvatarUrl' }`.
  ///
  /// The transport that receives these is still to be wired, so nothing emits
  /// yet; `activeCallProvider` subscribes here so an incoming call is handled
  /// the moment it does (Ziki #2917).
  Stream<Map<String, dynamic>> get callEvents => _callEvents.stream;

  void emitCallEvent(Map<String, dynamic> event) {
    if (!_callEvents.isClosed) {
      _callEvents.add(event);
    }
  }

  void dispose() {
    _callEvents.close();
  }

  Future<Map<String, dynamic>> initiateDirectCall(String participantId) async {
    await Future<void>.delayed(const Duration(milliseconds: 600));
    return {
      'success': true,
      'buzzId': 'mock-buzz-id-${DateTime.now().millisecondsSinceEpoch}',
      'token': 'mock-agora-token',
      'channelName': 'mock-channel-$participantId',
    };
  }

  Future<bool> respondToInvitation(String buzzId, bool accept) async {
    await Future<void>.delayed(const Duration(milliseconds: 500));
    return true;
  }

  Future<bool> respondToDirectCall(String buzzId, bool accept) async {
    await Future<void>.delayed(const Duration(milliseconds: 500));
    return true;
  }
}

