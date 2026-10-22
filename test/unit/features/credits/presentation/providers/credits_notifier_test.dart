import 'package:zedu/core/core.dart';
import 'package:zedu/features/features.dart';

import '../../../../../helpers/helpers.dart';

class MockCreditsRepository extends Mock implements CreditsRepository {}

void main() {
  late MockCreditsRepository repository;
  late ProviderContainer container;

  setUp(() {
    repository = MockCreditsRepository();
    container = ProviderContainer(
      overrides: [creditsRepositoryProvider.overrideWithValue(repository)],
    );
  });

  tearDown(() => container.dispose());

  void stubAllCreditCalls() {
    when(() => repository.getPackages()).thenAnswer(
      (_) async => const Success<List<CreditPackage>>([]),
    );
    when(() => repository.getUsage(any())).thenAnswer(
      (_) async => const Success<CreditUsage>(CreditUsage.empty),
    );
    when(() => repository.getUsageReport(any())).thenAnswer(
      (_) async => const Success<CreditUsageReport>(CreditUsageReport.empty),
    );
    when(() => repository.getTransactions(any())).thenAnswer(
      (_) async => const Success<List<CreditTransaction>>([]),
    );
  }

  test('loads credits using the provided orgId', () async {
    stubAllCreditCalls();
    final notifier = container.read(creditsNotifierProvider.notifier);
    await notifier.load(orgId: 'workspace-123');

    verify(() => repository.getUsage('workspace-123')).called(1);
    verify(() => repository.getUsageReport('workspace-123')).called(1);
    verify(() => repository.getTransactions('workspace-123')).called(1);
  });

  test('does not load when orgId is null or empty', () async {
    stubAllCreditCalls();
    final notifier = container.read(creditsNotifierProvider.notifier);
    await notifier.load(orgId: '');

    verifyNever(() => repository.getUsage(any()));
    verifyNever(() => repository.getUsageReport(any()));
    verifyNever(() => repository.getTransactions(any()));
  });
}
