import 'package:zedu/features/features.dart';

import '../../../../../helpers/helpers.dart';

void main() {
  group('NewGroupChatView.getComposerPlaceholder', () {
    test('returns default placeholder when no recipients are selected', () {
      final placeholder = NewGroupChatView.getComposerPlaceholder([]);
      expect(placeholder, 'Select a recipient above to start messaging...');
    });

    test('returns single recipient placeholder with name when available', () {
      const member = TeamMember(
        id: 'user-1',
        name: 'Sarah Connor',
        email: 'sarah@example.com',
        role: 'Developer',
        dateJoined: '2026-01-01',
        status: TeamMemberStatus.active,
      );

      final placeholder = NewGroupChatView.getComposerPlaceholder([member]);
      expect(placeholder, 'Message @Sarah Connor');
    });

    test('returns single recipient placeholder with email when name is null', () {
      const member = TeamMember(
        id: 'user-2',
        email: 'alex@example.com',
        role: 'Designer',
        dateJoined: '2026-01-01',
        status: TeamMemberStatus.active,
      );

      final placeholder = NewGroupChatView.getComposerPlaceholder([member]);
      expect(placeholder, 'Message @alex@example.com');
    });

    test('returns single recipient placeholder with email when name is empty', () {
      const member = TeamMember(
        id: 'user-3',
        name: '   ',
        email: 'empty@example.com',
        role: 'Tester',
        dateJoined: '2026-01-01',
        status: TeamMemberStatus.active,
      );

      final placeholder = NewGroupChatView.getComposerPlaceholder([member]);
      expect(placeholder, 'Message @empty@example.com');
    });

    test('returns group count placeholder when multiple recipients are selected', () {
      const member1 = TeamMember(
        id: 'user-1',
        name: 'Sarah Connor',
        email: 'sarah@example.com',
        role: 'Developer',
        dateJoined: '2026-01-01',
        status: TeamMemberStatus.active,
      );
      const member2 = TeamMember(
        id: 'user-2',
        name: 'Alex M.',
        email: 'alex@example.com',
        role: 'Designer',
        dateJoined: '2026-01-01',
        status: TeamMemberStatus.active,
      );

      final placeholder = NewGroupChatView.getComposerPlaceholder([
        member1,
        member2,
      ]);
      expect(placeholder, 'Message group (2 members)...');
    });
  });
}
