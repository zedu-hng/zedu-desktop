import 'package:zedu/core/core.dart';
import 'package:zedu/features/features.dart';

final notificationServiceProvider = Provider<NotificationService>((ref) {
  return NotificationService(ref);
});

/// Truncates a message preview for a notification body.
///
/// [String.substring] counts UTF-16 code units, so a cut that lands inside an
/// emoji or another non-BMP character leaves an unpaired high surrogate, which
/// renders as a replacement glyph in the notification. When the cut would fall
/// between a high and a low surrogate, this backs off one code unit so the pair
/// stays whole.
String truncateNotificationPreview(
  String text, {
  int maxLength = 80,
  int keep = 77,
}) {
  if (text.length <= maxLength) {
    return text;
  }
  var end = keep;
  if (end > 0 && (text.codeUnitAt(end - 1) & 0xFC00) == 0xD800) {
    end -= 1;
  }
  return '${text.substring(0, end)}...';
}

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

    contentPreview = truncateNotificationPreview(contentPreview);

    final notification = LocalNotification(
      title: 'New DM from $senderName',
      body: contentPreview,
    );

    notification.onClick = () async {
      await windowManager.show();
      await windowManager.focus();

      final router = locator<GoRouter>();
      router.go('/dms/$channelId');
    };

    await notification.show();
  }
}
