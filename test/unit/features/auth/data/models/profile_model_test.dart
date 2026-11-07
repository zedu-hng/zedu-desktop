import '../../../../../helpers/helpers.dart';
import 'package:zedu/features/features.dart';

/// A `GET /profile` payload (zedu-be `ProfileSummary`) with a status set.
Map<String, dynamic> _profileJson() => <String, dynamic>{
  'id': 'profile-1',
  'user_id': 'user-1',
  'email': 'ada@example.com',
  'first_name': 'Ada',
  'last_name': 'Lovelace',
  'username': 'ada',
  'organisation_id': 'org-1',
  'created_at': '2026-11-01T10:00:00Z',
  'icon': '📅',
  'text': 'In a meeting',
  'pause_notification': true,
  'status_timeout': '4102444800',
  'online': false,
};

void main() {
  group('ProfileModel status', () {
    test('reads the custom status and presence from /profile', () {
      final status = ProfileModel.fromJson(_profileJson()).toEntity().status;

      expect(status.emoji, '📅');
      expect(status.text, 'In a meeting');
      expect(status.pauseNotifications, isTrue);
      expect(status.online, isFalse);
      expect(
        status.expiresAt,
        DateTime.fromMillisecondsSinceEpoch(4102444800 * 1000),
      );
      expect(status.hasCustomStatus, isTrue);
    });

    test('accepts status_timeout as a number', () {
      final json = _profileJson()..['status_timeout'] = 4102444800;

      final status = ProfileModel.fromJson(json).toEntity().status;

      expect(
        status.expiresAt,
        DateTime.fromMillisecondsSinceEpoch(4102444800 * 1000),
      );
    });

    for (final raw in <Object?>['', '0', 'dont-clear', '30 minutes', null]) {
      test('keeps the status with no expiry when status_timeout is $raw', () {
        final json = _profileJson()..['status_timeout'] = raw;

        final status = ProfileModel.fromJson(json).toEntity().status;

        expect(status.expiresAt, isNull);
        expect(status.hasCustomStatus, isTrue);
      });
    }

    test('treats empty icon and text as no status', () {
      final json = _profileJson()
        ..['icon'] = ''
        ..['text'] = ''
        ..['status_timeout'] = '';

      final status = ProfileModel.fromJson(json).toEntity().status;

      expect(status.emoji, isNull);
      expect(status.text, isNull);
      expect(status.hasCustomStatus, isFalse);
    });

    test('defaults to Active with no status when the fields are missing', () {
      final json = _profileJson()
        ..remove('icon')
        ..remove('text')
        ..remove('pause_notification')
        ..remove('status_timeout')
        ..remove('online');

      final status = ProfileModel.fromJson(json).toEntity().status;

      expect(status.hasCustomStatus, isFalse);
      expect(status.pauseNotifications, isFalse);
      expect(status.online, isTrue);
    });
  });
}
