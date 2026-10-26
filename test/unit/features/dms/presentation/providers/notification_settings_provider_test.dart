import 'package:flutter_test/flutter_test.dart';
import 'package:riverpod/riverpod.dart';
import 'package:zedu/features/features.dart';

void main() {
  group('NotificationSettingsNotifier', () {
    late ProviderContainer container;

    setUp(() {
      container = ProviderContainer();
    });
    tearDown(() {
      container.dispose();
    });

    test('starts with no active DND mode', () {
      final settings = container.read(notificationSettingsProvider);
      expect(settings.isDndActive, isFalse);
    });

    test('setDndMode activates DND until manually cleared', () {
      final notifier = container.read(notificationSettingsProvider.notifier);
      notifier.setDndMode();
      expect(container.read(notificationSettingsProvider).isDndActive, isTrue);
    });

    test('clearDndMode deactivates DND', () {
      final notifier = container.read(notificationSettingsProvider.notifier);
      notifier.setDndMode();
      expect(container.read(notificationSettingsProvider).isDndActive, isTrue);
      notifier.clearDndMode();
      expect(container.read(notificationSettingsProvider).isDndActive, isFalse);
    });

    test('clearDndMode preserves muted participants', () {
      final notifier = container.read(notificationSettingsProvider.notifier);
      notifier.muteParticipant('user-1');
      notifier.setDndMode();
      notifier.clearDndMode();
      final settings = container.read(notificationSettingsProvider);
      expect(settings.isMuted('user-1'), isTrue);
      expect(settings.isDndActive, isFalse);
    });
  });
}
