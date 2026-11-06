import 'dart:async';
import 'dart:io';

import 'package:zedu/core/core.dart';

enum NetworkStatus { online, offline }

typedef ReachabilityChecker = Future<bool> Function();

/// Provides a reachability check strategy. Defaults to resolving DNS via `InternetAddress.lookup`.
final reachabilityCheckerProvider = Provider<ReachabilityChecker>((ref) {
  return NetworkStatusNotifier.defaultReachabilityChecker;
});

class NetworkStatusNotifier extends Notifier<NetworkStatus> {
  Timer? _checkTimer;

  @override
  NetworkStatus build() {
    final checker = ref.watch(reachabilityCheckerProvider);
    ref.onDispose(() => _checkTimer?.cancel());
    _startMonitoring(checker);
    return NetworkStatus.online;
  }

  static Future<bool> defaultReachabilityChecker() async {
    final addresses = await InternetAddress.lookup('one.one.one.one');
    return addresses.isNotEmpty;
  }

  void _startMonitoring(ReachabilityChecker checker) {
    _checkTimer?.cancel();
    _checkReachability(checker);
    _checkTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      _checkReachability(checker);
    });
  }

  Future<void> checkReachability([ReachabilityChecker? customChecker]) async {
    final ReachabilityChecker checker =
        customChecker ?? ref.read(reachabilityCheckerProvider);
    await _checkReachability(checker);
  }

  Future<void> _checkReachability(ReachabilityChecker checker) async {
    try {
      final isOnline = await checker();
      if (!ref.mounted) return;
      state = isOnline ? NetworkStatus.online : NetworkStatus.offline;
    } catch (_) {
      if (!ref.mounted) return;
      state = NetworkStatus.offline;
    }
  }

  void setOffline() {
    state = NetworkStatus.offline;
  }

  void setOnline() {
    state = NetworkStatus.online;
  }

  void toggle() {
    state = state == NetworkStatus.online ? NetworkStatus.offline : NetworkStatus.online;
  }
}

final networkStatusProvider =
    NotifierProvider<NetworkStatusNotifier, NetworkStatus>(
      NetworkStatusNotifier.new,
    );
