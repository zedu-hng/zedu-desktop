import '../../../../helpers/helpers.dart';
import 'package:zedu/core/core.dart';
import 'package:zedu/features/features.dart';

class MockApiBaseService extends Mock implements ApiBaseService {}

Map<String, dynamic> _invite(String id, String email, String status) => {
  'id': id,
  'email': email,
  'role': 'User',
  'status': status,
  'created_at': '2026-10-11T08:00:00Z',
};

void main() {
  group('UserProfileRemoteDataSourceImpl.getInvites', () {
    late MockApiBaseService api;
    late UserProfileRemoteDataSourceImpl datasource;

    setUp(() {
      api = MockApiBaseService();
      datasource = UserProfileRemoteDataSourceImpl(
        config: const AppConfig(
          apiBaseUrl: 'http://test/',
          usesMockData: false,
        ),
        apiBaseService: api,
      );
    });

    void stubInvites(List<Map<String, dynamic>> invites) {
      when(
        () => api.get<Map<String, dynamic>>(
          path: any(named: 'path'),
          queryParameters: any(named: 'queryParameters'),
        ),
      ).thenAnswer(
        (_) async => ApiResponseModel<Map<String, dynamic>>(
          data: {'data': invites},
          statusCode: 200,
        ),
      );
    }

    test('asks the backend for invited invites only', () async {
      stubInvites([_invite('1', 'guest1@example.com', 'invited')]);

      await datasource.getInvites(orgId: 'org-1', page: 2);

      verify(
        () => api.get<Map<String, dynamic>>(
          path: '/organisations/org-1/invites',
          queryParameters: {'page': 2, 'limit': 20, 'invite_status': 'invited'},
        ),
      ).called(1);
    });

    test('drops accepted invites and matches the search on email', () async {
      stubInvites([
        _invite('1', 'Guest7@example.com', 'invited'),
        _invite('2', 'guest8@example.com', 'accepted'),
        _invite('3', 'other@example.com', 'invited'),
      ]);

      final all = await datasource.getInvites(orgId: 'org-1');
      final matches = await datasource.getInvites(
        orgId: 'org-1',
        search: 'GUEST',
      );

      expect(all.map((invite) => invite.id), ['1', '3']);
      expect(matches.map((invite) => invite.id), ['1']);
    });
  });

  group('UserProfileRemoteDataSourceImpl notification preferences', () {
    late MockApiBaseService api;
    late UserProfileRemoteDataSourceImpl datasource;

    const path = '/organisations/org-1/notification-preference';
    const desktop = {
      'notify_about': 'mentions',
      'send_mail': true,
      'time_range': '7:00 AM - 9:59 PM',
    };

    ApiResponseModel<Map<String, dynamic>> ok(Object data) =>
        ApiResponseModel(data: {'data': data}, statusCode: 200);

    setUp(() {
      api = MockApiBaseService();
      datasource = UserProfileRemoteDataSourceImpl(
        config: const AppConfig(
          apiBaseUrl: 'http://test/',
          usesMockData: false,
        ),
        apiBaseService: api,
      );
      when(
        () => api.get<Map<String, dynamic>>(
          path: path,
          queryParameters: any(named: 'queryParameters'),
        ),
      ).thenAnswer((_) async => ok(desktop));
      when(
        () => api.get<Map<String, dynamic>>(path: '/profile'),
      ).thenAnswer((_) async => ok({'timezone': 'Africa/Lagos'}));
      when(
        () => api.post<Map<String, dynamic>>(
          path: path,
          queryParameters: any(named: 'queryParameters'),
          data: any(named: 'data'),
        ),
      ).thenAnswer((_) async => ok(desktop));
    });

    test('loads the desktop preferences with the profile timezone', () async {
      final preferences = await datasource.getNotificationPreferences(
        orgId: 'org-1',
      );

      expect(preferences.mode, NotificationMode.mentionsOnly);
      expect(preferences.quietHoursEnabled, isTrue);
      expect(preferences.differentMobileSettings, isFalse);
      expect(preferences.timezone, 'Africa/Lagos');
      verify(
        () => api.get<Map<String, dynamic>>(
          path: path,
          queryParameters: {'device_type': 'desktop'},
        ),
      ).called(1);
    });

    test('still loads when the mobile and profile requests fail', () async {
      when(
        () => api.get<Map<String, dynamic>>(
          path: path,
          queryParameters: {'device_type': 'mobile'},
        ),
      ).thenThrow(const ApiFailure(message: 'boom'));
      when(
        () => api.get<Map<String, dynamic>>(path: '/profile'),
      ).thenThrow(const ApiFailure(message: 'boom'));

      final preferences = await datasource.getNotificationPreferences(
        orgId: 'org-1',
      );

      expect(preferences.mode, NotificationMode.mentionsOnly);
      expect(preferences.timezone, isNull);
    });

    test('copies the settings to mobile when mobile shares them', () async {
      final saved = await datasource.updateNotificationPreferences(
        orgId: 'org-1',
        preferences: NotificationPreferences.empty(),
      );

      for (final deviceType in ['desktop', 'mobile']) {
        verify(
          () => api.post<Map<String, dynamic>>(
            path: path,
            queryParameters: {'device_type': deviceType},
            data: any(named: 'data'),
          ),
        ).called(1);
      }
      expect(saved.mode, NotificationMode.mentionsOnly);
    });

    test('leaves mobile alone when it has its own settings', () async {
      final saved = await datasource.updateNotificationPreferences(
        orgId: 'org-1',
        preferences: NotificationPreferences.empty().copyWith(
          differentMobileSettings: true,
        ),
      );

      verifyNever(
        () => api.post<Map<String, dynamic>>(
          path: path,
          queryParameters: {'device_type': 'mobile'},
          data: any(named: 'data'),
        ),
      );
      expect(saved.differentMobileSettings, isTrue);
    });

    test('fails without a selected workspace', () async {
      await expectLater(
        datasource.getNotificationPreferences(orgId: null),
        throwsA(isA<ApiFailure>()),
      );
      verifyNever(
        () => api.get<Map<String, dynamic>>(
          path: any(named: 'path'),
          queryParameters: any(named: 'queryParameters'),
        ),
      );
    });
  });
}
