import '../../../../../helpers/helpers.dart';

import 'package:zedu/core/core.dart';
import 'package:zedu/features/features.dart';

void main() {
  group('activeCallProvider incoming calls (Ziki #2917)', () {
    test('an incoming call event moves the notifier to the incoming state', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      // Reading the provider builds it, which subscribes to the call events.
      final notifier = container.read(activeCallProvider);
      expect(notifier.state.status, CallStatus.none);

      container.read(buzzRepositoryProvider).emitCallEvent({
        'type': 'incoming',
        'buzzId': 'buzz-1',
        'remoteUserId': 'user-2',
        'remoteUserName': 'Ada',
        'channelId': 'channel-9',
        'remoteAvatarUrl': 'https://example.com/ada.png',
      });
      await pumpEventQueue();

      expect(notifier.state.status, CallStatus.incoming);
      expect(notifier.state.buzzId, 'buzz-1');
      expect(notifier.state.remoteUserId, 'user-2');
      expect(notifier.state.remoteUserName, 'Ada');
      expect(notifier.state.channelId, 'channel-9');
      expect(notifier.state.remoteAvatarUrl, 'https://example.com/ada.png');
    });

    test('an event that is not an incoming call is ignored', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final notifier = container.read(activeCallProvider);
      container.read(buzzRepositoryProvider).emitCallEvent({
        'type': 'accepted',
        'buzzId': 'buzz-1',
      });
      await pumpEventQueue();

      expect(notifier.state.status, CallStatus.none);
    });
  });
}
