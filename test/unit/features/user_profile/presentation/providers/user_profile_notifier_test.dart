import 'dart:async';

import '../../../../../helpers/helpers.dart';
import 'package:zedu/core/core.dart';
import 'package:zedu/features/features.dart';

class MockUserProfileRepository extends Mock implements UserProfileRepository {}

class MockSecureStorageService extends Mock implements SecureStorageService {}

const _members = [
  TeamMember(
    id: 'member-1',
    email: 'owner@example.com',
    role: 'Owner',
    dateJoined: '2026-10-08T16:37:13Z',
    status: TeamMemberStatus.active,
    name: 'owner',
  ),
  TeamMember(
    id: 'member-2',
    email: 'user@example.com',
    role: 'User',
    dateJoined: '2026-10-08T16:40:05Z',
    status: TeamMemberStatus.active,
    name: 'user',
  ),
];

void main() {
  group('UserProfileNotifier', () {
    late MockUserProfileRepository repository;
    late ProviderContainer container;

    setUp(() {
      repository = MockUserProfileRepository();

      final storage = MockSecureStorageService();
      when(() => storage.readData(any())).thenAnswer((_) async => null);
      if (locator.isRegistered<SecureStorageService>()) {
        locator.unregister<SecureStorageService>();
      }
      locator.registerSingleton<SecureStorageService>(storage);
      locator.registerSingleton<AppConfig>(
        const AppConfig(apiBaseUrl: 'http://test/', usesMockData: false),
      );

      when(
        () => repository.getAccount(),
      ).thenAnswer((_) async => Success(ProfileAccount.empty()));
      when(
        () => repository.getNotificationPreferences(),
      ).thenAnswer((_) async => Success(NotificationPreferences.empty()));
      when(
        () => repository.getSecuritySessions(),
      ).thenAnswer((_) async => const Success(<SecuritySession>[]));
      when(
        () => repository.getOrganization(),
      ).thenAnswer((_) async => Success(OrganizationProfile.empty()));
      when(
        () => repository.getRolesAndPermissions(),
      ).thenAnswer((_) async => const Success(<RolePermission>[]));
      when(
        () => repository.getBillingInfo(),
      ).thenAnswer((_) async => Success(BillingInfo.empty()));

      when(
        () => repository.getInvites(
          orgId: any(named: 'orgId'),
          page: any(named: 'page'),
          search: any(named: 'search'),
        ),
      ).thenAnswer((_) async => const Success(<TeamMember>[]));

      container = ProviderContainer(
        overrides: [
          userProfileRepositoryProvider.overrideWithValue(repository),
        ],
      );
      addTearDown(container.dispose);
    });

    tearDown(() {
      locator.unregister<SecureStorageService>();
      locator.unregister<AppConfig>();
    });

    Future<UserProfileState> loaded() async {
      final completer = Completer<UserProfileState>();
      final subscription = container.listen<UserProfileState>(
        userProfileNotifierProvider,
        (_, next) {
          if (!next.isLoading && !completer.isCompleted) {
            completer.complete(next);
          }
        },
        fireImmediately: true,
      );
      addTearDown(subscription.close);
      return completer.future.timeout(const Duration(seconds: 5));
    }

    test('starts in the loading state', () async {
      when(
        () => repository.getTeamMembers(orgId: any(named: 'orgId')),
      ).thenAnswer((_) async => const Success(_members));

      expect(container.read(userProfileNotifierProvider).isLoading, isTrue);

      // Let the pending load finish so it doesn't outlive the container.
      await loaded();
    });

    test('loads team members after build without throwing', () async {
      when(
        () => repository.getTeamMembers(orgId: any(named: 'orgId')),
      ).thenAnswer((_) async => const Success(_members));

      final state = await loaded();

      expect(state.teamMembers, _members);
      expect(state.error, isNull);
      verify(
        () => repository.getTeamMembers(orgId: any(named: 'orgId')),
      ).called(1);
    });

    test('sets an error and no members when loading members fails', () async {
      when(
        () => repository.getTeamMembers(orgId: any(named: 'orgId')),
      ).thenAnswer(
        (_) async => const Failure(
          ApiFailure(message: 'Forbidden', kind: ApiFailureKind.client),
        ),
      );

      final state = await loaded();

      expect(state.teamMembers, isEmpty);
      expect(state.error, isNotNull);
    });

    test('loads pending invites and drops one when it is deleted', () async {
      when(
        () => repository.getTeamMembers(orgId: any(named: 'orgId')),
      ).thenAnswer((_) async => const Success(_members));
      when(
        () => repository.getInvites(
          orgId: any(named: 'orgId'),
          page: any(named: 'page'),
          search: any(named: 'search'),
        ),
      ).thenAnswer((_) async => Success([_members[1]]));
      when(
        () => repository.deleteInvite('member-2'),
      ).thenAnswer((_) async => const Success(null));

      await loaded();
      final notifier = container.read(userProfileNotifierProvider.notifier);
      await notifier.loadInvites();
      expect(container.read(userProfileNotifierProvider).invites, [
        _members[1],
      ]);

      await notifier.deleteInvite('member-2');

      expect(container.read(userProfileNotifierProvider).invites, isEmpty);
    });

    test('keeps a newly invited email out of the team members', () async {
      when(
        () => repository.getTeamMembers(orgId: any(named: 'orgId')),
      ).thenAnswer((_) async => const Success(_members));
      when(
        () => repository.inviteMember(
          email: any(named: 'email'),
          role: any(named: 'role'),
          orgId: any(named: 'orgId'),
        ),
      ).thenAnswer(
        (_) async => const Success(
          TeamMember(
            id: 'invite-1',
            email: 'new@example.com',
            role: 'User',
            dateJoined: 'Pending',
            status: TeamMemberStatus.pending,
          ),
        ),
      );

      await loaded();
      final notifier = container.read(userProfileNotifierProvider.notifier);
      await notifier.inviteMember(email: 'new@example.com', role: 'User');

      expect(container.read(userProfileNotifierProvider).teamMembers, _members);
    });

    test('shows the delete toast again on a second delete', () async {
      when(
        () => repository.getTeamMembers(orgId: any(named: 'orgId')),
      ).thenAnswer((_) async => const Success(_members));
      when(
        () => repository.deleteInvite(any()),
      ).thenAnswer((_) async => const Success(null));
      await loaded();

      final messages = <String?>[];
      container.listen<UserProfileState>(
        userProfileNotifierProvider,
        (_, next) => messages.add(next.successMessage),
      );
      final notifier = container.read(userProfileNotifierProvider.notifier);
      await notifier.deleteInvite('a');
      await notifier.deleteInvite('b');

      // The view toasts only when the message changes, so it has to be cleared
      // between deletes for the second toast to show.
      var shown = 0;
      String? previous;
      for (final message in messages) {
        if (message == 'Invite deleted.' && previous != message) shown++;
        previous = message;
      }
      expect(shown, 2);
    });

    test('still toasts that an invite was sent', () async {
      when(
        () => repository.getTeamMembers(orgId: any(named: 'orgId')),
      ).thenAnswer((_) async => const Success(_members));
      when(
        () => repository.inviteMember(
          email: any(named: 'email'),
          role: any(named: 'role'),
          orgId: any(named: 'orgId'),
        ),
      ).thenAnswer((_) async => Success(_members[1]));
      await loaded();

      final messages = <String?>[];
      container.listen<UserProfileState>(
        userProfileNotifierProvider,
        (_, next) => messages.add(next.successMessage),
      );
      final notifier = container.read(userProfileNotifierProvider.notifier);
      await notifier.inviteMember(email: 'new@example.com', role: 'User');

      expect(messages, contains('Invite sent successfully.'));
    });

    test(
      'ignores an invites response that arrives after a newer one',
      () async {
        when(
          () => repository.getTeamMembers(orgId: any(named: 'orgId')),
        ).thenAnswer((_) async => const Success(_members));
        await loaded();
        final notifier = container.read(userProfileNotifierProvider.notifier);

        final slow = Completer<Result<List<TeamMember>>>();
        when(
          () => repository.getInvites(
            orgId: any(named: 'orgId'),
            page: any(named: 'page'),
            search: any(named: 'search'),
          ),
        ).thenAnswer(
          (call) => call.namedArguments[#search] == 'old'
              ? slow.future
              : Future.value(Success([_members[1]])),
        );

        final first = notifier.loadInvites(search: 'old');
        await notifier.loadInvites(search: 'new');
        slow.complete(Success([_members[0]]));
        await first;

        expect(container.read(userProfileNotifierProvider).invites, [
          _members[1],
        ]);
      },
    );

    test(
      'flags a failed invites load and clears it on the next success',
      () async {
        when(
          () => repository.getTeamMembers(orgId: any(named: 'orgId')),
        ).thenAnswer((_) async => const Success(_members));
        await loaded();
        final notifier = container.read(userProfileNotifierProvider.notifier);
        when(
          () => repository.getInvites(
            orgId: any(named: 'orgId'),
            page: any(named: 'page'),
            search: any(named: 'search'),
          ),
        ).thenAnswer(
          (_) async => const Failure(
            ApiFailure(message: 'Forbidden', kind: ApiFailureKind.client),
          ),
        );

        await notifier.loadInvites();
        expect(
          container.read(userProfileNotifierProvider).invitesLoadFailed,
          isTrue,
        );

        when(
          () => repository.getInvites(
            orgId: any(named: 'orgId'),
            page: any(named: 'page'),
            search: any(named: 'search'),
          ),
        ).thenAnswer((_) async => const Success(<TeamMember>[]));
        await notifier.loadInvites();
        expect(
          container.read(userProfileNotifierProvider).invitesLoadFailed,
          isFalse,
        );
      },
    );

    test('reloads invites with the same search after sending one', () async {
      when(
        () => repository.getTeamMembers(orgId: any(named: 'orgId')),
      ).thenAnswer((_) async => const Success(_members));
      when(
        () => repository.inviteMember(
          email: any(named: 'email'),
          role: any(named: 'role'),
          orgId: any(named: 'orgId'),
        ),
      ).thenAnswer((_) async => Success(_members[1]));
      await loaded();
      final notifier = container.read(userProfileNotifierProvider.notifier);

      await notifier.loadInvites(search: 'guest');
      await notifier.inviteMember(email: 'new@example.com', role: 'User');

      // Once for the search itself and once for the reload after the invite.
      verify(
        () => repository.getInvites(
          orgId: any(named: 'orgId'),
          page: any(named: 'page'),
          search: 'guest',
        ),
      ).called(2);
    });
  });
}
