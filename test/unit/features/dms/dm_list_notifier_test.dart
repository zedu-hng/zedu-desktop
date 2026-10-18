import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:zedu/features/features.dart';

class MockDmRepository extends Mock implements DmRepository {}

void main() {
  group('DmListNotifier', () {
    late MockDmRepository mockRepository;

    setUp(() {
      mockRepository = MockDmRepository();
    });

    ProviderContainer makeContainer() {
      return ProviderContainer(
        overrides: [
          dmRepositoryProvider.overrideWithValue(mockRepository),
          // Provide a non-empty orgId so the notifier actually calls the repo.
          currentOrgIdProvider.overrideWithValue('org-123'),
        ],
      );
    }

    test(
      'returns an empty list when the API returns no conversations on page 1',
      () async {
        when(
          () => mockRepository.getConversations(
            orgId: any(named: 'orgId'),
            page: any(named: 'page'),
          ),
        ).thenAnswer((_) async => []);

        final container = makeContainer();
        addTearDown(container.dispose);

        // Wait for the async notifier to finish loading.
        final result = await container.read(dmListProvider.future);

        expect(
          result,
          isEmpty,
          reason:
              'No fake "Test User" conversation should appear when the user has no DMs',
        );
      },
    );

    test(
      'returns real conversations from the repository when they exist',
      () async {
        final fakeConversation = DmConversation(
          channelId: 'ch-1',
          username: 'Alice',
          participantId: 'user-1',
          previewMessage: 'Hey!',
          unreadCount: 1,
        );

        when(
          () => mockRepository.getConversations(
            orgId: any(named: 'orgId'),
            page: any(named: 'page'),
          ),
        ).thenAnswer((_) async => [fakeConversation]);

        final container = makeContainer();
        addTearDown(container.dispose);

        final result = await container.read(dmListProvider.future);

        expect(result, hasLength(1));
        expect(result.first.username, 'Alice');
      },
    );

    test(
      'returns empty list when orgId is empty, without calling the repository',
      () async {
        final container = ProviderContainer(
          overrides: [
            dmRepositoryProvider.overrideWithValue(mockRepository),
            currentOrgIdProvider.overrideWithValue(''),
          ],
        );
        addTearDown(container.dispose);

        final result = await container.read(dmListProvider.future);

        expect(result, isEmpty);
        verifyNever(
          () => mockRepository.getConversations(
            orgId: any(named: 'orgId'),
            page: any(named: 'page'),
          ),
        );
      },
    );
  });
}
