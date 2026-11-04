import '../../../../../helpers/helpers.dart';
import 'package:zedu/core/core.dart';
import 'package:zedu/features/features.dart';

class _FakeCallDeviceService implements CallDeviceService {
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
  }) async {}
}

void main() {
  testWidgets('lists a picker for every call device kind', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          callDeviceServiceProvider.overrideWithValue(_FakeCallDeviceService()),
        ],
        child: buildTestMaterialApp(const Scaffold(body: CallDeviceSelector())),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Microphone'), findsOneWidget);
    expect(find.text('Camera'), findsOneWidget);
    expect(find.text('Speaker'), findsOneWidget);
    expect(find.text('System default'), findsNWidgets(3));
  });

  testWidgets('pre-join dialog offers to start the call', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          callDeviceServiceProvider.overrideWithValue(_FakeCallDeviceService()),
        ],
        child: buildTestMaterialApp(
          const Scaffold(body: CallDeviceSetupDialog(startCall: true)),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Start call'), findsNWidgets(2));
    expect(find.text('Cancel'), findsOneWidget);
  });
}
