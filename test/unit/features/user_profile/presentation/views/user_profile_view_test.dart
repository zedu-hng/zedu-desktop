import 'package:flutter_test/flutter_test.dart';
import 'package:zedu/features/features.dart';

ProfileAccount buildAccount({
  String name = 'Stored Name',
  String email = 'stored@zedu.chat',
  String username = 'storedname',
  String? avatarUrl = 'https://example.com/stored.png',
}) {
  return ProfileAccount(
    name: name,
    email: email,
    timezone: 'Africa/Lagos',
    username: username,
    avatarUrl: avatarUrl,
  );
}

User buildSessionUser() {
  return User(
    id: 'user-1',
    firstName: 'Ada',
    lastName: 'Okafor',
    fullName: 'Ada Okafor',
    email: 'ada@zedu.chat',
    phone: '08000000000',
    username: 'ada',
    isVerified: true,
    isOnboarded: true,
    createdAt: DateTime(2026, 1, 1),
    currentOrg: 'org-1',
    currentOrganisationSlug: 'zedu-org',
    avatarUrl: 'https://example.com/session.png',
    defaultAvatarUrl: '',
  );
}

void main() {
  group('accountForAuthenticatedUser', () {
    test('leaves the account untouched when there is no session user', () {
      final account = buildAccount();

      expect(accountForAuthenticatedUser(account, null), same(account));
    });

    group('name', () {
      test('uses the session name when empty', () {
        final account = accountForAuthenticatedUser(
          buildAccount(name: ''),
          buildSessionUser(),
        );

        expect(account.name, 'Ada Okafor');
      });

      test('uses the session name when it is the placeholder', () {
        final account = accountForAuthenticatedUser(
          buildAccount(name: 'Anonymous user'),
          buildSessionUser(),
        );

        expect(account.name, 'Ada Okafor');
      });

      test('keeps a real name', () {
        final account = accountForAuthenticatedUser(
          buildAccount(),
          buildSessionUser(),
        );

        expect(account.name, 'Stored Name');
      });
    });

    group('email', () {
      test('uses the session email when empty', () {
        final account = accountForAuthenticatedUser(
          buildAccount(email: ''),
          buildSessionUser(),
        );

        expect(account.email, 'ada@zedu.chat');
      });

      test('uses the session email when it is the placeholder', () {
        final account = accountForAuthenticatedUser(
          buildAccount(email: 'anonymoususer@email.com'),
          buildSessionUser(),
        );

        expect(account.email, 'ada@zedu.chat');
      });

      test('keeps a real email', () {
        final account = accountForAuthenticatedUser(
          buildAccount(),
          buildSessionUser(),
        );

        expect(account.email, 'stored@zedu.chat');
      });
    });

    group('username', () {
      test('uses the session username when empty', () {
        final account = accountForAuthenticatedUser(
          buildAccount(username: ''),
          buildSessionUser(),
        );

        expect(account.username, 'ada');
      });

      test('uses the session username when it is the placeholder', () {
        final account = accountForAuthenticatedUser(
          buildAccount(username: 'anonymoususer'),
          buildSessionUser(),
        );

        expect(account.username, 'ada');
      });

      test('keeps a real username', () {
        final account = accountForAuthenticatedUser(
          buildAccount(),
          buildSessionUser(),
        );

        expect(account.username, 'storedname');
      });
    });

    group('avatarUrl', () {
      test('uses the session avatar when null', () {
        final account = accountForAuthenticatedUser(
          buildAccount(avatarUrl: null),
          buildSessionUser(),
        );

        expect(account.avatarUrl, 'https://example.com/session.png');
      });

      test('uses the session avatar when whitespace', () {
        final account = accountForAuthenticatedUser(
          buildAccount(avatarUrl: '   '),
          buildSessionUser(),
        );

        expect(account.avatarUrl, 'https://example.com/session.png');
      });

      test('keeps a real avatar', () {
        final account = accountForAuthenticatedUser(
          buildAccount(),
          buildSessionUser(),
        );

        expect(account.avatarUrl, 'https://example.com/stored.png');
      });
    });
  });
}
