import 'package:zedu/core/core.dart';
import 'package:zedu/features/features.dart';

final notificationServiceProvider = Provider<NotificationService>((ref) {
  return NotificationService(ref);
});

class NotificationService {
  final Ref _ref;
  final Map<String, DateTime> _lastNotificationTimes = {};

  NotificationService(this._ref);

  Future<void> init() async {
    await localNotifier.setup(
      appName: 'Zedu',
      shortcutPolicy: ShortcutPolicy.requireCreate,
    );
  }

  /// Handles an incoming message and shows a desktop notification.
  ///
  /// When [forceShow] is `true` the focus-check and per-sender throttle are
  /// skipped so that test / manual notifications always fire.
  Future<void> handleIncomingMessage(
    Map<String, dynamic> message,
    String channelId,
    String senderName, {
    bool forceShow = false,
  }) async {
    final settings = _ref.read(notificationSettingsProvider);
    final authState = _ref.read(authNotifierProvider);
    final currentUserId = authState.user?.id ?? '';

    final senderId = (message['user_id'] ?? message['userId']).toString();

    // Never notify about our own messages (unless forced for testing).
    if (!forceShow && (senderId == currentUserId || senderId == 'me')) return;

    if (settings.isDndActive) return;
    if (settings.isMuted(senderId)) return;

    if (!forceShow) {
      final isFocused = await windowManager.isFocused();
      final selectedChannel = _ref.read(selectedDmProvider)?.channelId;

      if (isFocused && selectedChannel == channelId) {
        return;
      }

      final now = DateTime.now();
      final lastTime = _lastNotificationTimes[senderId];
      if (lastTime != null && now.difference(lastTime).inSeconds < 5) {
        return;
      }
      _lastNotificationTimes[senderId] = now;
    }

    String contentPreview = (message['content'] ?? '').toString();
    if (contentPreview.isEmpty) {
      final media = message['media'] as List<dynamic>? ?? [];
      if (media.isNotEmpty) {
        contentPreview = 'Sent an attachment';
      } else {
        contentPreview = 'New message';
      }
    }

    if (contentPreview.length > 80) {
      contentPreview = '${contentPreview.substring(0, 77)}...';
    }

    final notification = LocalNotification(
      title: 'New DM from $senderName',
      body: contentPreview,
    );

    notification.onClick = () async {
      await openDmFromNotification(channelId);
    };

    await notification.show();
  }

  /// Opens the DM conversation referenced by a desktop notification.
  ///
  /// DMs live inside [HomeView] and selection is driven by Riverpod state,
  /// not by a URL — there is no `/dms/:id` route. So this brings the window
  /// to the front, switches the rail to the DMs tab, and selects the
  /// matching conversation when it is already loaded. When the conversation
  /// is unknown (deleted / not yet loaded) it still lands on the DMs tab
  /// instead of erroring.
  Future<void> openDmFromNotification(String channelId) async {
    try {
      await windowManager.show();
    } catch (_) {
      // No-op in tests / platforms without window support.
    }
    try {
      await windowManager.focus();
    } catch (_) {
      // No-op in tests / platforms without window support.
    }

    // Always land on the DMs tab, even for unknown conversations.
    _ref.read(homeSidebarProvider.notifier).setType(HomeSidebarType.dms);

    final conversations =
        _ref.read(dmListProvider).asData?.value ?? const <DmConversation>[];
    for (final conversation in conversations) {
      if (conversation.channelId == channelId) {
        _ref.read(selectedDmProvider.notifier).select(conversation);
        break;
      }
    }

    // Keep the router resolvable from the handler (registered in
    // setupLocator). If the app is signed in but not on /home, bring it
    // there so the DMs tab is visible. Never force navigation when
    // unauthenticated or already home.
    try {
      if (locator.isRegistered<GoRouter>()) {
        final router = locator<GoRouter>();
        final isAuthenticated =
            _ref.read(authNotifierProvider).status == AuthStatus.authenticated;
        final current = router.state.uri.toString();
        if (isAuthenticated && current != AppRouter.home) {
          router.go(AppRouter.home);
        }
      }
    } catch (_) {
      // Navigation is best-effort; state selection above already landed
      // the user on the DMs tab when HomeView is visible.
    }
  }
}
