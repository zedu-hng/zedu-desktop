import 'package:flutter_test/flutter_test.dart';
import 'package:zedu/core/core.dart';
import 'package:zedu/features/features.dart';

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
