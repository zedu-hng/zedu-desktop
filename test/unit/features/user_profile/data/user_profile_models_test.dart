import 'package:flutter_test/flutter_test.dart';
import 'package:zedu/features/features.dart';

void main() {
  group('ProfileAccountModel', () {
    test('retains saved fields from a backend profile summary', () {
      final account = ProfileAccountModel.fromJson(const {
        'full_name': 'Test Learner',
        'email': 'learner@example.com',
        'timezone': 'Africa/Lagos',
        'display_name': 'Learner',
        'username': 'test-learner',
        'phone': '+2348000000000',
        'title': 'Student',
        'name_pronounciation': 'lear-ner',
      });

      expect(account.name, 'Test Learner');
      expect(account.displayName, 'Learner');
      expect(account.username, 'test-learner');
      expect(account.phoneNumber, '+2348000000000');
      expect(account.title, 'Student');
      expect(account.namePronunciation, 'lear-ner');
      expect(account.country, isEmpty);
    });

    test('preserves legacy account fields through serialization', () {
      const json = {
        'name': 'Test Learner',
        'email': 'learner@example.com',
        'timezone': 'Africa/Lagos',
        'avatar_url': 'https://example.com/avatar.png',
        'display_name': 'Learner',
        'username': 'test-learner',
        'phone_number': '+2348000000000',
        'title': 'Student',
        'name_pronunciation': 'lear-ner',
        'country': 'Nigeria',
      };

      expect(ProfileAccountModel.fromJson(json).toJson(), json);
    });

    test('uses defaults when optional profile values are absent or null', () {
      final account = ProfileAccountModel.fromJson(const {
        'full_name': null,
        'phone': null,
        'name_pronounciation': null,
      });

      expect(account.name, 'Anonymous user');
      expect(account.displayName, isEmpty);
      expect(account.username, isEmpty);
      expect(account.phoneNumber, isEmpty);
      expect(account.title, isEmpty);
      expect(account.namePronunciation, isEmpty);
      expect(account.country, isEmpty);
    });

    test('maps account json to entity fields', () {
      final account = ProfileAccountModel.fromJson(const {
        'name': 'Anonymous user',
        'email': 'anonymoususer@email.com',
        'timezone': 'Africa/Lagos',
        'avatar_url': 'https://example.com/avatar.png',
      });

      expect(account.name, 'Anonymous user');
      expect(account.email, 'anonymoususer@email.com');
      expect(account.timezone, 'Africa/Lagos');
      expect(account.initials, 'AU');
      expect(account.avatarUrl, 'https://example.com/avatar.png');
    });
  });

  group('NotificationPreferencesModel', () {
    test('maps notification mode and desktop/email preferences', () {
      final preferences = NotificationPreferencesModel.fromJson(const {
        'mode': 'mentions_only',
        'from_time': '9:00 AM',
        'to_time': '5:00 PM',
        'use_desktop_settings': true,
        'email_notifications': true,
      });

      expect(preferences.mode, NotificationMode.mentionsOnly);
      expect(preferences.fromTime, '9:00 AM');
      expect(preferences.toTime, '5:00 PM');
      expect(preferences.useDesktopSettings, isTrue);
      expect(preferences.emailNotifications, isTrue);
    });
  });

  group('TeamMemberModel', () {
    test('maps pending members from json', () {
      final member = TeamMemberModel.fromJson(const {
        'id': 'member-2',
        'email': 'invitee@zedu.chat',
        'role': 'Manager',
        'date_joined': 'Pending',
        'status': 'pending',
      });

      expect(member.id, 'member-2');
      expect(member.email, 'invitee@zedu.chat');
      expect(member.role, 'Manager');
      expect(member.status, TeamMemberStatus.pending);
    });
  });
}
