import 'dart:async';

import '../../../../../helpers/helpers.dart';
import 'package:zedu/core/core.dart';
import 'package:zedu/features/features.dart';

class MockUserProfileRepository extends Mock implements UserProfileRepository {}

void main() {
  group('UserProfileNotifier.updateAccount', () {
    late MockUserProfileRepository repository;

    setUpAll(() => registerFallbackValue(ProfileAccount.empty()));

    setUp(() {
      repository = MockUserProfileRepository();
      when(
        () => repository.updateAccount(any()),
      ).thenAnswer((_) async => Success(ProfileAccount.empty()));
    });

    // build() starts the profile load in a microtask, without awaiting it.
    // Against this bare mock that load fails before it sets the account, so
    // the account stays the placeholder the edit form opens with. Its error is
    // the only one that reaches the zone handler: failures in the test body
    // arrive through body()'s own future.
    Future<void> ignoringProfileLoadError(Future<void> Function() body) {
      final done = Completer<void>();
      runZonedGuarded(
        () => body().then(done.complete, onError: done.completeError),
        (error, stack) {},
      );
      return done.future;
    }

    test('sends only the edited fields and shows only what was saved', () {
      return ignoringProfileLoadError(() async {
        final container = ProviderContainer(
          overrides: [
            userProfileRepositoryProvider.overrideWithValue(repository),
          ],
        );
        addTearDown(container.dispose);
        final notifier = container.read(userProfileNotifierProvider.notifier);
        final placeholder = ProfileAccount.empty();

        await notifier.updateAccount(
          placeholder.copyWith(
            phoneNumber: '+2348012345678',
            email: 'me@zedu.chat',
          ),
        );

        final sent =
            verify(() => repository.updateAccount(captureAny())).captured.single
                as ProfileAccount;
        expect(sent.name, '');
        expect(sent.phoneNumber, '+2348012345678');

        final shown = container.read(userProfileNotifierProvider).account!;
        expect(shown.phoneNumber, '+2348012345678');
        expect(shown.name, placeholder.name);
        expect(shown.email, placeholder.email);
      });
    });
  });
}
