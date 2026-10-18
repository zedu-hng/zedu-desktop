import 'package:zedu/core/core.dart';
import 'package:zedu/features/features.dart';

import '../../../helpers/helpers.dart';

class _FakeChannelNotifier extends ChannelNotifier {
  Result<Channel> result = Success<Channel>(
    Channel(
      id: 'channel-1',
      name: 'plan-budget',
      description: '',
      organisationId: 'org-1',
      ownerId: 'user-1',
    ),
  );

  @override
  Future<List<Channel>> build() async => const [];

  @override
  Future<Result<Channel>> createChannel({
    required String name,
    required String description,
    required bool isPrivate,
    String? topic,
  }) async => result;
}

void main() {
  testWidgets('creating a channel confirms success with a toast', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1200, 1400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [channelProvider.overrideWith(_FakeChannelNotifier.new)],
        child: buildTestMaterialApp(
          Builder(
            builder: (context) => Scaffold(
              body: TextButton(
                onPressed: () => showDialog<void>(
                  context: context,
                  builder: (_) => const CreateChannelModal(),
                ),
                child: const Text('Open'),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();
    expect(find.byType(CreateChannelModal), findsOneWidget);

    await tester.enterText(find.byType(TextField).first, 'plan-budget');
    await tester.tap(find.text('Create'));
    await tester.pumpAndSettle();

    expect(find.byType(CreateChannelModal), findsNothing);
    expect(
      find.text('Channel "#plan-budget" created successfully.'),
      findsOneWidget,
    );

    await tester.pump(const Duration(seconds: 5));
    await tester.pumpAndSettle();

    expect(
      find.text('Channel "#plan-budget" created successfully.'),
      findsNothing,
    );
    expect(tester.takeException(), isNull);
  });
}
