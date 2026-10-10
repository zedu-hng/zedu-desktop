import '../../../../../helpers/helpers.dart';
import 'package:zedu/core/core.dart';
import 'package:zedu/features/features.dart';

class MockChannelRepository extends Mock implements ChannelRepository {}

class FakeWorkspaceNotifier extends WorkspaceNotifier {
  @override
  WorkspaceState build() => const WorkspaceState(
    selectedWorkspace: Workspace(id: 'org-1', name: 'Test org', avatar: ''),
  );
}

class FakeAuthNotifier extends AuthNotifier {
  @override
  AuthState build() => AuthState(
    status: AuthStatus.authenticated,
    user: User(
      id: 'user-1',
      firstName: 'Test',
      lastName: 'User',
      email: 'test@example.com',
      phone: '',
      username: 'testuser',
      isVerified: true,
      isOnboarded: true,
      createdAt: DateTime(2026),
      currentOrg: 'org-1',
      currentOrganisationSlug: 'test-org',
      avatarUrl: '',
      defaultAvatarUrl: '',
    ),
  );
}

Channel _channel(String name) => Channel(
  id: 'channel-$name',
  name: name,
  description: '',
  organisationId: 'org-1',
  ownerId: 'user-1',
);

void main() {
  group('ChannelNotifier.createChannel', () {
    late MockChannelRepository repository;
    late ProviderContainer container;

    setUp(() {
      repository = MockChannelRepository();
      when(
        () => repository.fetchChannels(any()),
      ).thenAnswer((_) async => Success<List<Channel>>([_channel('general')]));

      container = ProviderContainer(
        overrides: [
          channelRepositoryProvider.overrideWithValue(repository),
          workspaceProvider.overrideWith(FakeWorkspaceNotifier.new),
          authNotifierProvider.overrideWith(FakeAuthNotifier.new),
        ],
      );
      addTearDown(container.dispose);
    });

    void stubCreateChannel(Result<Channel> result) {
      when(
        () => repository.createChannel(
          name: any(named: 'name'),
          description: any(named: 'description'),
          orgId: any(named: 'orgId'),
          username: any(named: 'username'),
          isPrivate: any(named: 'isPrivate'),
          topic: any(named: 'topic'),
        ),
      ).thenAnswer((_) async => result);
    }

    // Reads the notifier and waits for the first channel fetch to finish.
    Future<ChannelNotifier> loadNotifier() async {
      final notifier = container.read(channelProvider.notifier);
      await pumpEventQueue();
      return notifier;
    }

    test('adds the new channel to the list and returns true', () async {
      stubCreateChannel(Success<Channel>(_channel('team-heron')));
      final notifier = await loadNotifier();

      final created = await notifier.createChannel(
        name: 'team-heron',
        description: '',
        isPrivate: false,
      );

      final state = container.read(channelProvider);
      expect(created, isTrue);
      expect(state.channels.map((c) => c.name), ['general', 'team-heron']);
      expect(state.isLoading, isFalse);
      expect(state.errorMessage, isNull);
    });

    test('keeps the list and saves the server message on failure', () async {
      stubCreateChannel(
        const Failure<Channel>(
          ApiFailure(message: 'Channel name already exists'),
        ),
      );
      final notifier = await loadNotifier();

      final created = await notifier.createChannel(
        name: 'general',
        description: '',
        isPrivate: false,
      );

      final state = container.read(channelProvider);
      expect(created, isFalse);
      expect(state.channels.map((c) => c.name), ['general']);
      expect(state.isLoading, isFalse);
      expect(state.errorMessage, 'Channel name already exists');
    });
  });
}
