import 'package:zedu/core/core.dart';
import 'package:zedu/features/features.dart';

import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockUserProfileRepository extends Mock
    implements UserProfileRepository {}

class _EmptyWorkspaceNotifier extends WorkspaceNotifier {
  @override
  WorkspaceState build() => const WorkspaceState();
}

Failure<T> _failure<T>() =>
    Failure<T>(const ApiFailure(message: 'Not used by this test'));

void main() {
  test('initializes state before loading profile data', () async {
    final repository = _MockUserProfileRepository();
    when(() => repository.getAccount()).thenAnswer((_) async => _failure());
    when(
      () => repository.getNotificationPreferences(),
    ).thenAnswer((_) async => _failure());
    when(
      () => repository.getSecuritySessions(),
    ).thenAnswer((_) async => _failure());
    when(
      () => repository.getOrganization(),
    ).thenAnswer((_) async => _failure());
    when(
      () => repository.getTeamMembers(orgId: any(named: 'orgId')),
    ).thenAnswer((_) async => _failure());
    when(
      () => repository.getRolesAndPermissions(),
    ).thenAnswer((_) async => _failure());
    when(() => repository.getBillingInfo()).thenAnswer((_) async => _failure());

    final container = ProviderContainer(
      overrides: [
        userProfileRepositoryProvider.overrideWithValue(repository),
        workspaceProvider.overrideWith(_EmptyWorkspaceNotifier.new),
      ],
    );
    addTearDown(container.dispose);

    final initialState = container.read(userProfileNotifierProvider);
    expect(initialState.isLoading, isTrue);

    await Future<void>.delayed(Duration.zero);
    expect(container.read(userProfileNotifierProvider).isLoading, isFalse);
  });
}
