import 'dart:async';

import 'package:zedu/core/core.dart';
import 'package:zedu/features/features.dart';
import '../../../../../helpers/helpers.dart';

class FakeAuthNotifier extends AuthNotifier {
  @override
  AuthState build() => const AuthState(status: AuthStatus.unauthenticated);
}

class MockDmRepository extends Mock implements DmRepository {}

class MockSecureStorageService extends Mock implements SecureStorageService {}

void main() {
  testWidgets('DmChatArea header has no test notification button', (
    tester,
  ) async {
    // History stays loading so the polling that follows a load never starts.
    final repository = MockDmRepository();
    when(
      () => repository.getMessages(any(), page: any(named: 'page')),
    ).thenAnswer((_) => Completer<List<Map<String, dynamic>>>().future);
    final storage = MockSecureStorageService();
    when(() => storage.readData(any())).thenAnswer((_) async => null);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authNotifierProvider.overrideWith(FakeAuthNotifier.new),
          dmRepositoryProvider.overrideWithValue(repository),
          dmDraftStoreProvider.overrideWith(
            (ref) => DmDraftStore(storage, userId: 'u', orgId: 'o'),
          ),
        ],
        child: buildTestMaterialApp(
          Scaffold(
            body: DmChatArea(
              conversation: DmConversation(
                channelId: 'channel-1',
                username: 'Bola',
                participantId: 'user-2',
                previewMessage: '',
                unreadCount: 0,
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pump();

    expect(find.byTooltip('More options'), findsOneWidget);
    expect(find.byTooltip('Test Notification (Delayed 5s)'), findsNothing);
  });

  testWidgets(
    'deleting a DM discards its draft, even when the composer closes',
    (tester) async {
      final repository = MockDmRepository();
      when(
        () => repository.getMessages(any(), page: any(named: 'page')),
      ).thenAnswer((_) => Completer<List<Map<String, dynamic>>>().future);
      when(
        () => repository.deleteConversation(
          orgId: any(named: 'orgId'),
          channelId: any(named: 'channelId'),
        ),
      ).thenAnswer((_) async {});
      final storage = MockSecureStorageService();
      when(() => storage.readData(any())).thenAnswer((_) async => null);
      when(() => storage.writeData(any(), any())).thenAnswer((_) async {});
      when(() => storage.deleteValue(any())).thenAnswer((_) async {});
      // The history spinner never stops, so pumpAndSettle would time out.
      Future<void> settle() async {
        for (var i = 0; i < 10; i++) {
          await tester.pump(const Duration(milliseconds: 100));
        }
      }

      await tester.binding.setSurfaceSize(const Size(1200, 800));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authNotifierProvider.overrideWith(FakeAuthNotifier.new),
            currentOrgIdProvider.overrideWithValue('org-1'),
            dmRepositoryProvider.overrideWithValue(repository),
            dmDraftStoreProvider.overrideWith(
              (ref) => DmDraftStore(storage, userId: 'u', orgId: 'org-1'),
            ),
          ],
          child: buildTestMaterialApp(
            Scaffold(
              body: DmChatArea(
                conversation: DmConversation(
                  channelId: 'channel-1',
                  username: 'Bola',
                  participantId: 'user-2',
                  previewMessage: '',
                  unreadCount: 0,
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pump();

      await tester.enterText(find.byType(TextField), 'unsent text');
      await tester.tap(find.byTooltip('More options'));
      await settle();
      await tester.tap(find.text('Delete conversation'));
      await settle();
      // From here on, nothing may write the draft back.
      clearInteractions(storage);
      await tester.tap(find.widgetWithText(TextButton, 'Delete conversation'));
      await settle();

      verify(
        () => repository.deleteConversation(
          orgId: 'org-1',
          channelId: 'channel-1',
        ),
      ).called(1);

      // Close the composer, then let any deferred save run.
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump();

      verify(() => storage.deleteValue('dm_draft_u_org-1_channel-1')).called(1);
      verifyNever(() => storage.writeData(any(), any()));
    },
  );
}
