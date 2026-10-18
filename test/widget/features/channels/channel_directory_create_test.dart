import 'package:zedu/core/core.dart';
import 'package:zedu/features/features.dart';
import '../../../helpers/helpers.dart';
import '../../../unit/features/channels/starred_channel_test.dart'
    show MemoryStorage;

class _Auth extends AuthNotifier {
  @override
  AuthState build() => const AuthState(status: AuthStatus.unauthenticated);
}

class _Workspaces extends WorkspaceNotifier {
  @override
  WorkspaceState build() => const WorkspaceState();
}

class _Channels extends ChannelNotifier {
  @override
  Future<List<Channel>> build() async => [
    Channel.fromJson({
      'channels_id': 'general',
      'name': 'general',
      'description': '',
      'organisation_id': 'workspace',
      'owner_id': 'owner',
    }),
  ];
}

class _EmptyChannels extends ChannelNotifier {
  @override
  Future<List<Channel>> build() async => const <Channel>[];
}

Widget _host(Widget child, ChannelNotifier channels) => ProviderScope(
  overrides: [
    authNotifierProvider.overrideWith(_Auth.new),
    workspaceProvider.overrideWith(_Workspaces.new),
    channelProvider.overrideWith(() => channels),
    orgCreditBalanceProvider.overrideWithValue(0),
    channelScopeProvider.overrideWithValue((
      userId: 'user',
      workspaceId: 'workspace',
    )),
    starredChannelRepositoryProvider.overrideWithValue(
      StarredChannelRepositoryImpl(MemoryStorage()),
    ),
  ],
  child: buildTestMaterialApp(child),
);

void _expectNoLayoutOverflow(WidgetTester tester) {
  expect(tester.takeException(), isNull);
}

void main() {
  testWidgets('channel directory header opens the create channel modal', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1264, 680);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      _host(const Scaffold(body: ChannelDirectoryView()), _Channels()),
    );
    await tester.pumpAndSettle();

    final addChannel = find.widgetWithText(AppButton, 'Add channel');
    expect(addChannel, findsOneWidget);

    tester.view.physicalSize = const Size(1024, 600);
    await tester.pumpAndSettle();
    _expectNoLayoutOverflow(tester);
    expect(addChannel, findsOneWidget);

    tester.view.physicalSize = const Size(1264, 680);
    await tester.pumpAndSettle();

    await tester.tap(addChannel);
    await tester.pumpAndSettle();
    expect(find.byType(CreateChannelModal), findsOneWidget);
  });

  testWidgets('channel directory empty state offers channel creation', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1024, 600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      _host(const Scaffold(body: ChannelDirectoryView()), _EmptyChannels()),
    );
    await tester.pumpAndSettle();

    expect(find.text('No channels found.'), findsOneWidget);
    final createChannel = find.widgetWithText(AppButton, 'Create a channel');
    expect(createChannel, findsOneWidget);
    _expectNoLayoutOverflow(tester);

    await tester.tap(createChannel);
    await tester.pumpAndSettle();
    expect(find.byType(CreateChannelModal), findsOneWidget);
  });
}
