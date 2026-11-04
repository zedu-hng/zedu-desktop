import '../../../../helpers/helpers.dart';
import 'package:zedu/features/features.dart';

class _MockBuzzEngine extends Mock implements BuzzEngineService {}

void main() {
  group('CallDeviceService.listDevices', () {
    late _MockBuzzEngine engine;
    late CallDeviceService service;

    setUp(() {
      engine = _MockBuzzEngine();
      service = CallDeviceService(engine);
      when(() => engine.enumerateCameras()).thenAnswer((_) async => const []);
      when(() => engine.enumerateSpeakers()).thenAnswer((_) async => const []);
      when(
        () => engine.enumerateMicrophones(),
      ).thenAnswer((_) async => const []);
    });

    test('lists the system default first and keeps engine devices', () async {
      when(() => engine.enumerateCameras()).thenAnswer(
        (_) async => const [
          CallEngineDevice(id: 'cam-1', label: 'FaceTime HD Camera'),
          CallEngineDevice(id: 'cam-1', label: 'Duplicate'),
          CallEngineDevice(
            id: systemDefaultDeviceId,
            label: 'Duplicate default',
          ),
        ],
      );

      final devices = await service.listDevices(CallDeviceKind.camera);

      expect(devices.first, systemDefaultDevice(CallDeviceKind.camera));
      expect(devices.skip(1).map((device) => device.id), ['cam-1']);
      expect(devices[1].label, 'FaceTime HD Camera');
    });

    test(
      'falls back to the platform microphone list without an engine',
      () async {
        final fallbackService = CallDeviceService(
          engine,
          microphoneFallback: () async => const [
            CallEngineDevice(id: 'mic-1', label: 'Built-in Microphone'),
          ],
        );

        final devices = await fallbackService.listDevices(
          CallDeviceKind.microphone,
        );

        expect(devices, [
          systemDefaultDevice(CallDeviceKind.microphone),
          const CallDevice(
            id: 'mic-1',
            label: 'Built-in Microphone',
            kind: CallDeviceKind.microphone,
          ),
        ]);
      },
    );
  });

  group('CallDeviceService.apply', () {
    late _MockBuzzEngine engine;
    late CallDeviceService service;

    setUp(() {
      engine = _MockBuzzEngine();
      service = CallDeviceService(engine);
      when(() => engine.selectMicrophone(any())).thenAnswer((_) async {});
      when(() => engine.selectCamera(any())).thenAnswer((_) async {});
      when(() => engine.selectSpeaker(any())).thenAnswer((_) async {});
    });

    test('switches every selected device', () async {
      await service.apply(
        microphone: const CallDevice(
          id: 'mic-1',
          label: 'USB mic',
          kind: CallDeviceKind.microphone,
        ),
        camera: const CallDevice(
          id: 'cam-1',
          label: 'HD camera',
          kind: CallDeviceKind.camera,
        ),
        speaker: const CallDevice(
          id: 'spk-1',
          label: 'Headphones',
          kind: CallDeviceKind.speaker,
        ),
      );

      verify(() => engine.selectMicrophone('mic-1')).called(1);
      verify(() => engine.selectCamera('cam-1')).called(1);
      verify(() => engine.selectSpeaker('spk-1')).called(1);
    });

    test('leaves the system default devices untouched', () async {
      await service.apply(
        microphone: systemDefaultDevice(CallDeviceKind.microphone),
        camera: systemDefaultDevice(CallDeviceKind.camera),
        speaker: systemDefaultDevice(CallDeviceKind.speaker),
      );

      verifyNever(() => engine.selectMicrophone(any()));
      verifyNever(() => engine.selectCamera(any()));
      verifyNever(() => engine.selectSpeaker(any()));
    });
  });
}
