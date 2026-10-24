import 'package:zedu/features/features.dart';

import '../../../../../helpers/helpers.dart';

/// One item of `GET /organisations/:org_id/channels`, shaped like zedu-be's
/// `GetUserChannelResp`.
Map<String, dynamic> channelListItem({required bool access}) => {
  'channels_id': 'channel-1',
  'name': 'general',
  'description': 'General chat',
  'organisation_id': 'org-1',
  'is_private': false,
  'owner_id': 'user-1',
  'archived': false,
  'thread_count': 3,
  'access': access,
  'mention_count': 0,
  'last_thread_id': '',
};

void main() {
  group('Channel.fromJson membership', () {
    test('a channel the user belongs to is joined', () {
      final channel = Channel.fromJson(channelListItem(access: true));

      expect(channel.id, 'channel-1');
      expect(channel.isJoined, isTrue);
    });

    test('a public channel the user has not joined is not joined', () {
      final channel = Channel.fromJson(channelListItem(access: false));

      expect(channel.isJoined, isFalse);
    });

    test('still reads is_joined when access is absent', () {
      final channel = Channel.fromJson({'id': 'channel-2', 'is_joined': true});

      expect(channel.isJoined, isTrue);
    });
  });
}
