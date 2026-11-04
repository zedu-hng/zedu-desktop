import '../../../../../helpers/helpers.dart';
import 'package:zedu/core/core.dart';
import 'package:zedu/features/features.dart';

class _FakeCallDeviceService implements CallDeviceService {
  final List<Map<String, String?>> applied = [];

  @override
  Future<List<CallDevice>> listDevices(CallDeviceKind kind) async {
    return [
      systemDefaultDevice(kind),
      CallDevice(id: '${kind.name}-1', label: '${kind.label} 1', kind: kind),
    ];
  }

  @override
  Future<void> apply({
    CallDevice? microphone,
    CallDevice? camera,
    CallDevice? speaker,
  }) async {
    applied.add({
      'microphone': microphone?.id,
      'camera': camera?.id,
      'speaker': speaker?.id,
    });
  }
}

class _MockBuzzRepository extends Mock implements BuzzRepository {}

void main() {
  group('CallDevicesNotifier', () {
    late _FakeCallDeviceService service;
    late ProviderContainer container;
    late CallDevicesNotifier notifier;

    setUp(() {
      service = _FakeCallDeviceService();
      container = ProviderContainer(
        overrides: [callDeviceServiceProvider.overrideWithValue(service)],
      );
      notifier = container.read(callDevicesProvider.notifier);
    });

    tearDown(() {
      container.dispose();
    });

    test(
      'loads a device list per kind and defaults to system default',
      () async {
        await notifier.load();

        expect(notifier.state.isLoading, isFalse);
        expect(notifier.state.devices.keys, CallDeviceKind.values);
        for (final kind in CallDeviceKind.values) {
          expect(notifier.selectedFor(kind), systemDefaultDevice(kind));
        }
      },
    );

    test(
      'keeps the previous selection when the device is still listed',
      () async {
        await notifier.load();
        final camera = CallDevice(
          id: 'camera-1',
          label: 'Camera 1',
          kind: CallDeviceKind.camera,
        );
        await notifier.select(CallDeviceKind.camera, camera);

        await notifier.load();

        expect(notifier.selectedFor(CallDeviceKind.camera), camera);
      },
    );

    test('applies a new device immediately', () async {
      await notifier.load();

      final microphone = CallDevice(
        id: 'microphone-1',
        label: 'Microphone 1',
        kind: CallDeviceKind.microphone,
      );
      await notifier.select(CallDeviceKind.microphone, microphone);

      expect(notifier.selectedFor(CallDeviceKind.microphone), microphone);
      expect(service.applied.last['microphone'], 'microphone-1');
    });

    test('ignores a device of the wrong kind', () async {
      await notifier.load();
      final before = service.applied.length;

      await notifier.select(
        CallDeviceKind.speaker,
        const CallDevice(
          id: 'camera-1',
          label: 'Camera 1',
          kind: CallDeviceKind.camera,
        ),
      );

      expect(
        notifier.selectedFor(CallDeviceKind.speaker),
        systemDefaultDevice(CallDeviceKind.speaker),
      );
      expect(service.applied.length, before);
    });
  });

  group('pre-join device selection', () {
    test('is applied to the engine when the call is accepted', () async {
      final service = _FakeCallDeviceService();
      final repository = _MockBuzzRepository();
      when(
        () => repository.respondToInvitation(any(), any()),
      ).thenAnswer((_) async => true);

      final container = ProviderContainer(
        overrides: [
          callDeviceServiceProvider.overrideWithValue(service),
          buzzRepositoryProvider.overrideWithValue(repository),
        ],
      );
      addTearDown(container.dispose);

      final calls = container.read(activeCallProvider.notifier);
      calls.receiveIncomingCall(
        buzzId: 'buzz-1',
        remoteUserId: 'user-2',
        remoteUserName: 'Ruby',
        channelId: 'channel-1',
      );
      await container.read(callDevicesProvider.notifier).load();
      await container
          .read(callDevicesProvider.notifier)
          .select(
            CallDeviceKind.speaker,
            const CallDevice(
              id: 'speaker-1',
              label: 'Speaker 1',
              kind: CallDeviceKind.speaker,
            ),
          );

      await calls.acceptCall();

      expect(calls.state.status, CallStatus.active);
      expect(service.applied.last['speaker'], 'speaker-1');
    });
  });
}
