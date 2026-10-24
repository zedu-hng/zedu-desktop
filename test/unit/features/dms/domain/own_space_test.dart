import 'package:zedu/features/features.dart';

import '../../../../helpers/helpers.dart';

DmConversation _dm(
  String channelId, {
  String participantId = '',
  List<DmParticipant> participants = const [],
}) => DmConversation(
  channelId: channelId,
  username: channelId,
  participantId: participantId,
  previewMessage: '',
  unreadCount: 0,
  participants: participants,
);

DmParticipant _participant(String userId) =>
    DmParticipant(userId: userId, username: userId, email: '$userId@z.com');

void main() {
  group('isOwnSpaceOf', () {
    test('is true when the other participant is you', () {
      expect(_dm('a', participantId: 'me').isOwnSpaceOf('me'), isTrue);
    });

    test('is false for a DM with someone else', () {
      expect(_dm('a', participantId: 'sam').isOwnSpaceOf('me'), isFalse);
    });

    test('is false when nobody is signed in', () {
      expect(_dm('a', participantId: 'me').isOwnSpaceOf(null), isFalse);
      expect(_dm('a', participantId: 'me').isOwnSpaceOf(''), isFalse);
    });

    test('uses the participants when participant_id is missing', () {
      final own = _dm('a', participants: [_participant('me')]);
      final shared = _dm(
        'b',
        participants: [_participant('me'), _participant('sam')],
      );

      expect(own.isOwnSpaceOf('me'), isTrue);
      expect(shared.isOwnSpaceOf('me'), isFalse);
      expect(_dm('c').isOwnSpaceOf('me'), isFalse);
    });
  });

  group('ownSpaceFirst', () {
    test('moves your own space to the front and keeps the rest in order', () {
      final list = [
        _dm('sam', participantId: 'u-sam'),
        _dm('ada', participantId: 'u-ada'),
        _dm('mine', participantId: 'me'),
        _dm('tobi', participantId: 'u-tobi'),
      ];

      final ordered = ownSpaceFirst(list, 'me');

      expect(ordered.map((c) => c.channelId), ['mine', 'sam', 'ada', 'tobi']);
    });

    test('leaves the list unchanged without an own space', () {
      final list = [
        _dm('sam', participantId: 'u-sam'),
        _dm('ada', participantId: 'u-ada'),
      ];

      expect(ownSpaceFirst(list, 'me'), same(list));
    });

    test('leaves the list unchanged when your own space is already first', () {
      final list = [
        _dm('mine', participantId: 'me'),
        _dm('sam', participantId: 'u-sam'),
      ];

      expect(ownSpaceFirst(list, 'me'), same(list));
    });
  });
}
