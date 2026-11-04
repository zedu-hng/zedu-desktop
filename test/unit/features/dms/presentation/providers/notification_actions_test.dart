import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zedu/features/features.dart';

void main() {
  group('muted conversations', () {
    test('mutes and unmutes a channel without touching other channels', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final notifier = container.read(notificationSettingsProvider.notifier);

      notifier.muteChannel('channel-1');
      notifier.muteChannel('channel-2');
      notifier.unmuteChannel('channel-1');

      final settings = container.read(notificationSettingsProvider);
      expect(settings.isChannelMuted('channel-1'), isFalse);
      expect(settings.isChannelMuted('channel-2'), isTrue);
    });
  });

  group('DmConversation.copyWith', () {
    test('clears only the unread count', () {
      final conversation = DmConversation(
        channelId: 'channel-1',
        username: 'Ada',
        participantId: 'user-1',
        previewMessage: 'Hello',
        unreadCount: 4,
      );

      final read = conversation.copyWith(unreadCount: 0);

      expect(read.unreadCount, 0);
      expect(read.channelId, conversation.channelId);
      expect(read.username, conversation.username);
      expect(read.previewMessage, conversation.previewMessage);
    });
  });
}
