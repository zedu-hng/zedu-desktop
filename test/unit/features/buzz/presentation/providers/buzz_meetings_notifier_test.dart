import 'dart:async';

import 'package:zedu/core/core.dart';
import 'package:zedu/features/features.dart';

import '../../../../../helpers/helpers.dart';

class _FakeRepository implements BuzzMeetingsRepository {
  _FakeRepository(this.result);

  Result<String> result;
  Completer<void>? gate;
  int calls = 0;

  @override
  Future<Result<String>> createMeeting() async {
    calls++;
    await gate?.future;
    return result;
  }
}

ProviderContainer _container(
  _FakeRepository repository, {
  String slug = 'acme',
}) {
  final container = ProviderContainer(
    overrides: [
      buzzMeetingsRepositoryProvider.overrideWithValue(repository),
      buzzOrgSlugProvider.overrideWithValue(slug),
      buzzConfigProvider.overrideWithValue(
        const AppConfig(
          apiBaseUrl: 'https://api.zedu.chat/api/v1/',
          usesMockData: false,
        ),
      ),
    ],
  );
  addTearDown(container.dispose);
  return container;
}

void main() {
  test('starting now links straight into the new meeting', () async {
    final container = _container(_FakeRepository(const Success('abc')));

    final result = await container
        .read(buzzMeetingsProvider.notifier)
        .create(startNow: true);

    expect(
      (result as Success<Uri>).value.toString(),
      'https://zedu.chat/acme/buzz/abc?direct=1',
    );
    expect(container.read(buzzMeetingsProvider), BuzzMeetingAction.none);
  });

  test('a meeting for later gets its plain link', () async {
    final container = _container(_FakeRepository(const Success('abc')));

    final result = await container
        .read(buzzMeetingsProvider.notifier)
        .create(startNow: false);

    expect(
      (result as Success<Uri>).value.toString(),
      'https://zedu.chat/acme/buzz/abc',
    );
  });

  test('shows which action is running and ignores a second one', () async {
    final repository = _FakeRepository(const Success('abc'))
      ..gate = Completer<void>();
    final container = _container(repository);
    final notifier = container.read(buzzMeetingsProvider.notifier);

    final first = notifier.create(startNow: false);
    expect(
      container.read(buzzMeetingsProvider),
      BuzzMeetingAction.createForLater,
    );
    expect(await notifier.create(startNow: true), isA<Failure<Uri>>());

    repository.gate!.complete();
    await first;
    expect(repository.calls, 1);
  });

  test('a server failure gives a message to show', () async {
    final container = _container(
      _FakeRepository(const Failure(ApiFailure(message: 'boom'))),
    );

    final result = await container
        .read(buzzMeetingsProvider.notifier)
        .create(startNow: true);

    expect(
      (result as Failure<Uri>).error.message,
      'Failed to create meeting. Please try again.',
    );
  });

  test('without an organisation nothing is created', () async {
    final repository = _FakeRepository(const Success('abc'));
    final container = _container(repository, slug: '');

    final result = await container
        .read(buzzMeetingsProvider.notifier)
        .create(startNow: true);

    expect(result, isA<Failure<Uri>>());
    expect(repository.calls, 0);
    expect(
      container.read(buzzMeetingsProvider.notifier).linkFor('abc'),
      isNull,
    );
  });

  group('joinLink', () {
    String opened(ProviderContainer container, String input) =>
        (container.read(buzzMeetingsProvider.notifier).joinLink(input)
                as Success<Uri>)
            .value
            .toString();
    String refused(ProviderContainer container, String input) =>
        (container.read(buzzMeetingsProvider.notifier).joinLink(input)
                as Failure<Uri>)
            .error
            .message;

    test('a bare code joins in the current organisation', () {
      final container = _container(_FakeRepository(const Success('abc')));

      expect(
        opened(container, ' abc-defg-hij '),
        'https://zedu.chat/acme/buzz/abc-defg-hij',
      );
    });

    test('a pasted link keeps the organisation in the link', () {
      final container = _container(_FakeRepository(const Success('abc')));

      expect(
        opened(container, 'https://zedu.chat/other-org/buzz/abc-defg-hij'),
        'https://zedu.chat/other-org/buzz/abc-defg-hij',
      );
      expect(
        opened(container, 'zedu.chat/other-org/buzz/abc/'),
        'https://zedu.chat/other-org/buzz/abc',
      );
      expect(
        opened(container, 'https://www.ZEDU.chat/other-org/buzz/abc?direct=1'),
        'https://zedu.chat/other-org/buzz/abc?direct=1',
      );
    });

    test('a link works without a current organisation', () {
      final container = _container(
        _FakeRepository(const Success('abc')),
        slug: '',
      );

      expect(
        opened(container, 'https://zedu.chat/other-org/buzz/abc'),
        'https://zedu.chat/other-org/buzz/abc',
      );
      expect(
        refused(container, 'abc-defg-hij'),
        'Sign in again to join a meeting.',
      );
    });

    test('a link that is not a Zedu meeting is refused', () {
      final container = _container(_FakeRepository(const Success('abc')));

      for (final input in [
        'https://meet.google.com/abc-defg-hij',
        'meet.google.com/abc-defg-hij',
        'https://zedu.chat.evil.test/acme/buzz/abc',
        'https://zedu.chat/acme/channels/abc',
        'https://zedu.chat/buzz/abc',
        'https://zedu.chat/acme/buzz/abc/extra',
        'javascript://zedu.chat/acme/buzz/abc',
      ]) {
        expect(
          refused(container, input),
          "That isn't a Zedu meeting link.",
          reason: input,
        );
      }
    });
  });
}
