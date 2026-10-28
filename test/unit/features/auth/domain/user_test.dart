import 'package:flutter_test/flutter_test.dart';
import 'package:zedu/features/features.dart';

User buildUser({String fullName = ''}) {
  return User(
    id: 'user-1',
    firstName: 'Ada',
    lastName: 'Okafor',
    fullName: fullName,
    email: 'ada@zedu.chat',
    phone: '08000000000',
    username: 'ada',
    isVerified: true,
    isOnboarded: true,
    createdAt: DateTime(2026, 1, 1),
    currentOrg: 'org-1',
    currentOrganisationSlug: 'zedu-org',
    avatarUrl: '',
    defaultAvatarUrl: '',
  );
}

void main() {
  group('User.fullname', () {
    test('uses fullName when it is set', () {
      expect(buildUser(fullName: 'Ada N. Okafor').fullname, 'Ada N. Okafor');
    });

    test('falls back to first and last name when fullName is empty', () {
      expect(buildUser().fullname, 'Ada Okafor');
    });

    test('falls back to first and last name when fullName is whitespace', () {
      expect(buildUser(fullName: '   ').fullname, 'Ada Okafor');
    });
  });
}
