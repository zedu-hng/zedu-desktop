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
}
