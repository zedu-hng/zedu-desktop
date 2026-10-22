import 'package:zedu/core/core.dart';
import 'package:zedu/features/features.dart';

import '../../../../../helpers/helpers.dart';

class MockAuthRepository extends Mock implements AuthRepository {}

void main() {
  late MockAuthRepository repository;
  late ProviderContainer container;

  setUp(() {
    repository = MockAuthRepository();
    container = ProviderContainer(
      overrides: [authRepositoryProvider.overrideWithValue(repository)],
    );
  });

  tearDown(() => container.dispose());

  test('shows generic error message on login failure', () async {
    when(
      () => repository.login(email: any(named: 'email'), password: any(named: 'password')),
    ).thenAnswer((_) async => Failure(ApiFailure.client(message: 'Invalid email and password supplied')));

    final notifier = container.read(authNotifierProvider.notifier);
    await notifier.login(email: 'user@example.com', password: 'wrongpassword');

    final state = container.read(authNotifierProvider);
    expect(state.error, 'Invalid email or password. Please check your credentials and try again.');
    expect(state.status, AuthStatus.unauthenticated);
  });
}
