import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:zedu/core/core.dart';
import 'package:zedu/features/features.dart';

void main() {
  setUpAll(() {
    if (!dotenv.isInitialized) {
      dotenv.loadFromString(
        envString: 'API_BASE_URL=https://api.staging.zedu.chat/api/v1/\n'
            'USE_MOCK_DATA=true',
      );
    }
    if (!locator.isRegistered<AppConfig>()) {
      setupLocator();
    }
  });

  testWidgets('Start Buzz starts a channel call', (tester) async {
    tester.view.physicalSize = const Size(1600, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final container = ProviderContainer(
      overrides: [authNotifierProvider.overrideWith(_TestAuthNotifier.new)],
    );
    addTearDown(container.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(theme: AppTheme.light, home: const HomeView()),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));

    expect(find.text('Start Buzz'), findsOneWidget);

    unawaited(
      container.read(activeCallProvider.notifier).initiateCall(
        remoteUserId: 'channel:general',
        remoteUserName: '#general',
        channelId: 'general',
      ),
    );
    await tester.pump();

    expect(find.text('Starting Buzz in #general...'), findsOneWidget);
    expect(find.text('Buzz in progress'), findsOneWidget);

    await tester.pump(const Duration(seconds: 4));
    expect(find.text('Buzz Call'), findsOneWidget);
    expect(find.byTooltip('Close Buzz'), findsOneWidget);
  });
}

class _TestAuthNotifier extends AuthNotifier {
  @override
  AuthState build() => const AuthState(status: AuthStatus.authenticated);
}
