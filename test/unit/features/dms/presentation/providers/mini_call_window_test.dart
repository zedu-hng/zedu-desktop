import '../../../../../helpers/helpers.dart';
import 'package:zedu/core/core.dart';
import 'package:zedu/features/features.dart';

class _FakeCallWindowService implements CallWindowService {
  final List<bool> alwaysOnTopChanges = [];

  @override
  Future<void> setAlwaysOnTop(bool value) async {
    alwaysOnTopChanges.add(value);
  }
}

void main() {
  group('mini call window', () {
    late _FakeCallWindowService window;
    late ProviderContainer container;
    late ActiveCallNotifier notifier;

    setUp(() {
      window = _FakeCallWindowService();
      container = ProviderContainer(
        overrides: [callWindowServiceProvider.overrideWithValue(window)],
      );
      notifier = container.read(activeCallProvider.notifier);
    });

    tearDown(() {
      container.dispose();
    });

    test('starts unmuted and without a mini window', () {
      expect(notifier.state.isMuted, isFalse);
      expect(notifier.state.isMiniWindow, isFalse);
      expect(notifier.state.isFullPage, isFalse);
    });

    test('mute state is shared through the notifier', () async {
      await notifier.setMuted(true);
      expect(notifier.state.isMuted, isTrue);

      await notifier.setMuted(false);
      expect(notifier.state.isMuted, isFalse);
    });

    test(
      'opening the mini window exits full page and pins the window',
      () async {
        notifier.setFullPage(true);
        await pumpEventQueue();

        notifier.setMiniWindow(true);
        await pumpEventQueue();

        expect(notifier.state.isMiniWindow, isTrue);
        expect(notifier.state.isFullPage, isFalse);
        expect(window.alwaysOnTopChanges.last, isTrue);
      },
    );

    test('closing the mini window unpins the window', () async {
      notifier.setMiniWindow(true);
      await pumpEventQueue();

      notifier.setMiniWindow(false);
      await pumpEventQueue();

      expect(notifier.state.isMiniWindow, isFalse);
      expect(window.alwaysOnTopChanges.last, isFalse);
    });

    test('opening the full page unpins the mini window', () async {
      notifier.setMiniWindow(true);
      await pumpEventQueue();

      notifier.setFullPage(true);
      await pumpEventQueue();

      expect(notifier.state.isFullPage, isTrue);
      expect(notifier.state.isMiniWindow, isFalse);
      expect(window.alwaysOnTopChanges.last, isFalse);
    });

    test('leaving the call resets the mini window and unpins', () async {
      notifier.setMiniWindow(true);
      await notifier.setMuted(true);
      await pumpEventQueue();

      notifier.endCall();
      await pumpEventQueue();

      expect(notifier.state.status, CallStatus.none);
      expect(notifier.state.isMiniWindow, isFalse);
      expect(notifier.state.isMuted, isFalse);
      expect(window.alwaysOnTopChanges.last, isFalse);
    });
  });
}
