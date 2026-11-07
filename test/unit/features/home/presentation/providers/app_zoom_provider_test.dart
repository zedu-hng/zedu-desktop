import 'package:zedu/core/core.dart';
import 'package:zedu/features/features.dart';

import '../../../../../helpers/helpers.dart';

class MockSecureStorageService extends Mock implements SecureStorageService {}

void main() {
  group('stepAppZoom', () {
    test('steps one level in and out', () {
      expect(stepAppZoom(1.0, 1), 1.1);
      expect(stepAppZoom(1.0, -1), 0.9);
    });

    test('stops at the limits', () {
      expect(stepAppZoom(1.5, 1), 1.5);
      expect(stepAppZoom(0.8, -1), 0.8);
    });

    test('an unknown level starts from 100%', () {
      expect(stepAppZoom(1.07, 1), 1.1);
    });
  });

  group('AppZoomNotifier', () {
    late MockSecureStorageService storage;
    late Map<String, String> saved;

    setUp(() {
      storage = MockSecureStorageService();
      saved = {};
      when(() => storage.readData(any())).thenAnswer(
        (invocation) async =>
            saved[invocation.positionalArguments[0] as String],
      );
      when(() => storage.writeData(any(), any())).thenAnswer((
        invocation,
      ) async {
        saved[invocation.positionalArguments[0] as String] =
            invocation.positionalArguments[1] as String;
      });
      locator.registerSingleton<SecureStorageService>(storage);
    });

    tearDown(() async {
      await locator.reset();
    });

    test('zoomIn saves the new level', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      await container.read(appZoomProvider.notifier).zoomIn();

      expect(container.read(appZoomProvider), 1.1);
      expect(saved[AppZoomNotifier.storageKey], '1.1');
    });

    test('restores a saved level on start', () async {
      saved[AppZoomNotifier.storageKey] = '1.25';
      final container = ProviderContainer();
      addTearDown(container.dispose);

      container.read(appZoomProvider);
      await Future<void>.delayed(Duration.zero);

      expect(container.read(appZoomProvider), 1.25);
    });

    test('ignores a saved level that is not a known zoom level', () async {
      saved[AppZoomNotifier.storageKey] = '3.0';
      final container = ProviderContainer();
      addTearDown(container.dispose);

      container.read(appZoomProvider);
      await Future<void>.delayed(Duration.zero);

      expect(container.read(appZoomProvider), 1.0);
    });

    test('reset returns to 100%', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final notifier = container.read(appZoomProvider.notifier);

      await notifier.zoomIn();
      await notifier.reset();

      expect(container.read(appZoomProvider), 1.0);
      expect(saved[AppZoomNotifier.storageKey], '1.0');
    });
  });
}
