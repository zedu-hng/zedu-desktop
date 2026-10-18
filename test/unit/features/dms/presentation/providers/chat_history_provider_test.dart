import 'package:zedu/core/core.dart';
import 'package:zedu/features/features.dart';

import '../../../../../helpers/helpers.dart';

class MockDmRepository extends Mock implements DmRepository {}

void main() {
  late MockDmRepository repository;
  late ProviderContainer container;

  final history = <Map<String, dynamic>>[
    {'id': 'thread-2', 'content': 'newest', 'user_id': 'user-2'},
    {'id': 'thread-1', 'content': 'oldest', 'user_id': 'user-1'},
  ];

  setUp(() {
    repository = MockDmRepository();
    container = ProviderContainer(
      overrides: [dmRepositoryProvider.overrideWithValue(repository)],
    );
  });

  tearDown(() => container.dispose());

  void stubHistory(Future<List<Map<String, dynamic>>> Function() answer) {
    when(
      () => repository.getMessages('ch-1', page: any(named: 'page')),
    ).thenAnswer((_) => answer());
  }

  Future<ChatHistoryNotifier> loadHistory() async {
    final notifier = container.read(chatHistoryProvider('ch-1'));
    while (notifier.isLoading) {
      await Future<void>.delayed(Duration.zero);
    }
    return notifier;
  }

  test('loads the DM history on open', () async {
    stubHistory(() async => history);

    final notifier = await loadHistory();

    expect(notifier.messages, history);
    expect(notifier.loadError, isNull);
    expect(notifier.hasMore, isFalse);
  });

  test('stores an error instead of failing silently', () async {
    stubHistory(() async => throw Exception('400'));

    final notifier = await loadHistory();

    expect(notifier.messages, isEmpty);
    expect(notifier.loadError, isNotNull);
    expect(notifier.isLoading, isFalse);
  });

  test('retry loads the history and clears the error', () async {
    stubHistory(() async => throw Exception('400'));
    final notifier = await loadHistory();
    expect(notifier.loadError, isNotNull);

    stubHistory(() async => history);
    await notifier.retry();

    expect(notifier.messages, history);
    expect(notifier.loadError, isNull);
  });
}
