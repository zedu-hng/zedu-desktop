import 'package:zedu/features/features.dart';

import '../../../helpers/helpers.dart';

User _user({String firstName = 'Ada', String lastName = 'Test'}) => User(
  id: 'user-1',
  firstName: firstName,
  lastName: lastName,
  email: 'ada@z.com',
  phone: '',
  username: 'ada_test',
  isVerified: true,
  isOnboarded: true,
  createdAt: DateTime(2026, 1, 1),
  currentOrg: 'org-1',
  currentOrganisationSlug: 'hng',
  avatarUrl: '',
  defaultAvatarUrl: '',
);

void main() {
  group('topBarChipName', () {
    test('uses the full name, like Home and Buy credits', () {
      final user = _user();

      final name = topBarChipName(user, fallback: user.username);

      expect(name, 'Ada Test');
      expect(TopUserMenu.initialsFor(name), 'AT');
      expect(
        TopUserMenu.initialsFor(name),
        TopUserMenu.initialsFor(user.fullname),
      );
    });

    test('falls back when the full name is empty', () {
      final user = _user(firstName: '', lastName: '');

      expect(topBarChipName(user, fallback: 'ada_test'), 'ada_test');
    });

    test('falls back when nobody is signed in', () {
      expect(topBarChipName(null, fallback: 'Zedu User'), 'Zedu User');
    });
  });
}
