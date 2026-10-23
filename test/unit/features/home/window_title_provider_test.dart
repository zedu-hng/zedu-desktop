import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:zedu/core/core.dart';
import 'package:zedu/features/features.dart';

class MockUnreadChannelRepository extends Mock implements ChannelRepository {}

class MockUnreadDmRepository extends Mock implements DmRepository {}

class FakeChannelNotifier extends ChannelNotifier {
  FakeChannelNotifier(this._channels);
  final List<Channel> _channels;

  @override
  Future<List<Channel>> build() async => _channels;
}

class FakeDmListNotifier extends DmListNotifier {
  FakeDmListNotifier(this._dms);
  final List<DmConversation> _dms;

  @override
  Future<List<DmConversation>> build() async => _dms;
}

class FakeWorkspaceNotifier extends WorkspaceNotifier {
  @override
  WorkspaceState build() => const WorkspaceState(
    workspaces: [Workspace(id: '1', name: 'Learning Workspace', avatar: 'L')],
    selectedWorkspace: Workspace(
      id: '1',
      name: 'Learning Workspace',
      avatar: 'L',
    ),
  );
}

Channel _channel(int unread) => Channel(
  id: 'c$unread',
  name: 'general',
  description: 'test',
  organisationId: 'org1',
  ownerId: 'u1',
  unreadCount: unread,
);

DmConversation _dm(int unread) => DmConversation(
  channelId: 'd$unread',
  username: 'Sam',
  participantId: 'p1',
  previewMessage: 'hi',
  unreadCount: unread,
);

Future<ProviderContainer> _makeContainer({
  required List<Channel> channels,
  required List<DmConversation> dms,
}) async {
  final container = ProviderContainer(
    overrides: [
      channelProvider.overrideWith(() => FakeChannelNotifier(channels)),
      dmListProvider.overrideWith(() => FakeDmListNotifier(dms)),
      workspaceProvider.overrideWith(FakeWorkspaceNotifier.new),
    ],
  );
  addTearDown(container.dispose);
  // Wait for both asynchronous lists to finish loading.
  await container.read(channelProvider.future);
  await container.read(dmListProvider.future);
  return container;
}

void main() {
  test(
    'opening conversations lowers the title and refresh picks up new unread messages',
    () async {
      final channelRepository = MockUnreadChannelRepository();
      final dmRepository = MockUnreadDmRepository();
      var channelUnread = 3;
      var dmUnread = 2;
      when(() => channelRepository.markRead('c1')).thenAnswer((_) async {
        channelUnread = 0;
        return const Success(null);
      });
      when(() => dmRepository.markRead('d1')).thenAnswer((_) async {
        dmUnread = 0;
      });
      when(() => channelRepository.fetchChannels('1')).thenAnswer(
        (_) async => Success([
          Channel(
            id: 'c1',
            name: 'announcements',
            description: '',
            organisationId: '1',
            ownerId: 'u1',
            unreadCount: channelUnread,
          ),
        ]),
      );
      when(() => dmRepository.getConversations(orgId: '1', page: 1)).thenAnswer(
        (_) async => [
          DmConversation(
            channelId: 'd1',
            username: 'Sam',
            participantId: 'p1',
            previewMessage: 'hi',
            unreadCount: dmUnread,
          ),
        ],
      );
      final container = ProviderContainer(
        overrides: [
          workspaceProvider.overrideWith(FakeWorkspaceNotifier.new),
          channelRepositoryProvider.overrideWithValue(channelRepository),
          dmRepositoryProvider.overrideWithValue(dmRepository),
        ],
      );
      addTearDown(container.dispose);
      final subscription = container.listen(windowTitleProvider, (_, _) {});
      addTearDown(subscription.close);
      await container.read(channelProvider.future);
      final conversations = await container.read(dmListProvider.future);
      expect(
        container.read(windowTitleProvider),
        '(5) Zedu - Learning Workspace',
      );

      container.read(activeChatProvider.notifier).selectChannel('c1');
      expect(
        container.read(windowTitleProvider),
        '(2) Zedu - Learning Workspace',
      );
      container.read(selectedDmProvider.notifier).select(conversations.single);
      expect(container.read(windowTitleProvider), 'Zedu - Learning Workspace');

      container.read(activeChatProvider.notifier).selectChannelDirectory();
      container.read(selectedDmProvider.notifier).select(null);
      await container.read(channelProvider.notifier).refreshUnreadCounts();
      await container.read(dmListProvider.notifier).refreshUnreadCounts();
      expect(container.read(windowTitleProvider), 'Zedu - Learning Workspace');
      verify(() => channelRepository.markRead('c1')).called(1);
      verify(() => dmRepository.markRead('d1')).called(1);
      channelUnread = 4;
      dmUnread = 3;
      await container.read(channelProvider.notifier).refreshUnreadCounts();
      await container.read(dmListProvider.notifier).refreshUnreadCounts();
      expect(
        container.read(windowTitleProvider),
        '(7) Zedu - Learning Workspace',
      );

      when(
        () => channelRepository.fetchChannels('1'),
      ).thenThrow(Exception('offline'));
      when(
        () => dmRepository.getConversations(orgId: '1', page: 1),
      ).thenThrow(Exception('offline'));
      await container.read(channelProvider.notifier).refreshUnreadCounts();
      await container.read(dmListProvider.notifier).refreshUnreadCounts();
      expect(
        container.read(windowTitleProvider),
        '(7) Zedu - Learning Workspace',
      );
    },
  );

  group('buildWindowTitle', () {
    test('shows plain title when there are no unread messages', () {
      expect(
        buildWindowTitle(unreadCount: 0, workspaceName: 'Learning Workspace'),
        'Zedu - Learning Workspace',
      );
    });

    test('adds the unread count in front when above zero', () {
      expect(
        buildWindowTitle(unreadCount: 37, workspaceName: 'Learning Workspace'),
        '(37) Zedu - Learning Workspace',
      );
    });

    test('falls back to Zedu when there is no workspace name', () {
      expect(buildWindowTitle(unreadCount: 0), 'Zedu');
      expect(buildWindowTitle(unreadCount: 5), '(5) Zedu');
    });
  });

  group('windowTitleProvider', () {
    test('adds channel and DM unread counts together', () async {
      final container = await _makeContainer(
        channels: [_channel(10), _channel(20)],
        dms: [_dm(7)],
      );

      expect(container.read(totalUnreadProvider), 37);
      expect(
        container.read(windowTitleProvider),
        '(37) Zedu - Learning Workspace',
      );
    });

    test('returns to the plain title when nothing is unread', () async {
      final container = await _makeContainer(
        channels: [_channel(0)],
        dms: [_dm(0)],
      );

      expect(container.read(totalUnreadProvider), 0);
      expect(container.read(windowTitleProvider), 'Zedu - Learning Workspace');
    });
  });
}
