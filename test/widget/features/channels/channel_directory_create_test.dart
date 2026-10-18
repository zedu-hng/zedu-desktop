import 'package:zedu/core/core.dart';
import 'package:zedu/features/features.dart';

import '../../../helpers/helpers.dart';

Channel _channel(String name) => Channel(
  id: 'channel-$name',
  name: name,
  description: '',
  organisationId: 'org-1',
  ownerId: 'user-1',
);

class _FakeChannelNotifier extends ChannelNotifier {
  _FakeChannelNotifier(this.channels);

  final List<Channel> channels;

  @override
  Future<List<Channel>> build() async => channels;
}

class _EmptyChannelNotifier extends ChannelNotifier {
  @override
  Future<List<Channel>> build() async => const [];
}

void main() {
  Future<void> pumpDirectory(
    WidgetTester tester,
    ChannelNotifier Function() channels,
  ) async {
    tester.view.physicalSize = const Size(1024, 600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [channelProvider.overrideWith(channels)],
        child: buildTestMaterialApp(
          const Scaffold(body: ChannelDirectoryView()),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('the directory header opens the create channel modal', (
    tester,
  ) async {
    await pumpDirectory(
      tester,
      () => _FakeChannelNotifier([_channel('general')]),
    );

    final addChannel = find.widgetWithText(AppButton, 'Add channel');
    expect(addChannel, findsOneWidget);

    await tester.tap(addChannel);
    await tester.pumpAndSettle();
    expect(find.byType(CreateChannelModal), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('the empty directory offers channel creation', (tester) async {
    await pumpDirectory(tester, _EmptyChannelNotifier.new);

    expect(find.text('No channels found.'), findsOneWidget);

    final createChannel = find.widgetWithText(AppButton, 'Create a channel');
    expect(createChannel, findsOneWidget);

    await tester.tap(createChannel);
    await tester.pumpAndSettle();
    expect(find.byType(CreateChannelModal), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
