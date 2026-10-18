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
  static bool createSucceeds = true;

  @override
  Future<bool> createChannel({
    required String name,
    required String description,
    required bool isPrivate,
    String? topic,
  }) async => createSucceeds;

  @override
  ChannelState build() => const ChannelState();
}

class _CreateChannelLauncher extends StatelessWidget {
  const _CreateChannelLauncher();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Builder(
        builder: (context) => ElevatedButton(
          onPressed: () => showDialog<void>(
            context: context,
            builder: (_) => const CreateChannelModal(),
          ),
          child: const Text('Add channel'),
        ),
      ),
    );
  }
}

void main() {
  testWidgets(
    'creating a channel confirms success with a toast before closing the modal',
    (tester) async {
      _Channels.createSucceeds = true;
      tester.view.physicalSize = const Size(1264, 680);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authNotifierProvider.overrideWith(_Auth.new),
            workspaceProvider.overrideWith(_Workspaces.new),
            channelProvider.overrideWith(_Channels.new),
            orgCreditBalanceProvider.overrideWithValue(0),
            channelScopeProvider.overrideWithValue((
              userId: 'user',
              workspaceId: 'workspace',
            )),
            starredChannelRepositoryProvider.overrideWithValue(
              StarredChannelRepositoryImpl(MemoryStorage()),
            ),
          ],
          child: buildTestMaterialApp(const _CreateChannelLauncher()),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Add channel'));
      await tester.pumpAndSettle();
      expect(find.byType(CreateChannelModal), findsOneWidget);

      await tester.enterText(
        find
            .descendant(
              of: find.byType(CreateChannelModal),
              matching: find.byType(TextField),
            )
            .first,
        'plan-budget',
      );
      await tester.ensureVisible(find.text('Create'));
      await tester.tap(find.text('Create'));
      await tester.pumpAndSettle();

      expect(find.byType(CreateChannelModal), findsNothing);
      expect(
        find.text('Channel "#plan-budget" created successfully.'),
        findsOneWidget,
      );

      await tester.pump(const Duration(seconds: 5));
      await tester.pumpAndSettle();

      expect(find.byType(CreateChannelModal), findsNothing);
      expect(
        find.text('Channel "#plan-budget" created successfully.'),
        findsNothing,
      );
      expect(tester.takeException(), isNull);
    },
  );
}
