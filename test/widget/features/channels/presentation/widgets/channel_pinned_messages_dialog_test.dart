import 'package:zedu/core/core.dart';
import 'package:zedu/features/features.dart';

import '../../../../../helpers/helpers.dart';

class _MockChannelRepository extends Mock implements ChannelRepository {}

Channel _channel() => Channel(
  id: 'channel-1',
  name: 'general',
  description: '',
  organisationId: 'org-1',
  ownerId: 'user-1',
);

void main() {
  group('ChannelPinnedMessagesDialog (Ziki #17)', () {
    late _MockChannelRepository repository;

    setUp(() => repository = _MockChannelRepository());

    Future<void> pump(WidgetTester tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [channelRepositoryProvider.overrideWithValue(repository)],
          child: buildTestMaterialApp(
            Scaffold(body: ChannelPinnedMessagesDialog(channel: _channel())),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));
    }

    testWidgets('lists the pinned messages with their senders', (tester) async {
      when(() => repository.fetchPinnedMessages('channel-1')).thenAnswer(
        (_) async => const Success<List<PinnedMessage>>([
          PinnedMessage(
            id: 'm1',
            senderName: 'Ada Lovelace',
            text: 'Release is on Friday',
          ),
          PinnedMessage(id: 'm2', senderName: 'Bo', text: 'Standup at 10'),
        ]),
      );

      await pump(tester);

      expect(find.text('#general pinned messages'), findsOneWidget);
      expect(find.text('Ada Lovelace'), findsOneWidget);
      expect(find.text('Release is on Friday'), findsOneWidget);
      expect(find.text('Bo'), findsOneWidget);
      expect(find.text('Standup at 10'), findsOneWidget);
    });

    testWidgets('says so when nothing is pinned', (tester) async {
      when(
        () => repository.fetchPinnedMessages('channel-1'),
      ).thenAnswer((_) async => const Success<List<PinnedMessage>>([]));

      await pump(tester);

      expect(find.text('No pinned messages yet'), findsOneWidget);
    });

    testWidgets('a failure offers Try again, which loads the list again', (
      tester,
    ) async {
      var calls = 0;
      when(() => repository.fetchPinnedMessages('channel-1')).thenAnswer((
        _,
      ) async {
        calls++;
        if (calls == 1) {
          return const Failure<List<PinnedMessage>>(
            ApiFailure(message: 'Server error'),
          );
        }
        return const Success<List<PinnedMessage>>([
          PinnedMessage(id: 'm1', senderName: 'Ada', text: 'Back again'),
        ]);
      });

      await pump(tester);
      expect(find.text("Couldn't load the pinned messages."), findsOneWidget);

      await tester.tap(find.text('Try again'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));

      expect(find.text('Back again'), findsOneWidget);
      expect(calls, 2);
    });
  });
}
