import 'package:zedu/core/core.dart';
import 'package:zedu/features/features.dart';
import '../../../../helpers/helpers.dart';

class FakeAuthNotifier extends AuthNotifier {
  FakeAuthNotifier(this._initial);

  final AuthState _initial;

  @override
  AuthState build() => _initial;
}

class FakeDmListNotifier extends DmListNotifier {
  FakeDmListNotifier(this._conversations);

  final List<DmConversation> _conversations;

  @override
  Future<List<DmConversation>> build() async => _conversations;
}

DmConversation dm(String channelId, String name) => DmConversation(
  channelId: channelId,
  username: name,
  participantId: 'user-$channelId',
  previewMessage: 'hello',
  unreadCount: 0,
);

ProviderContainer makeContainer({
  List<DmConversation> conversations = const [],
  AuthState authState = const AuthState(status: AuthStatus.unauthenticated),
}) {
  return ProviderContainer(
    overrides: [
      authNotifierProvider.overrideWith(() => FakeAuthNotifier(authState)),
      dmListProvider.overrideWith(() => FakeDmListNotifier(conversations)),
    ],
  );
}

void main() {
  // Test-only scaffolding for the click-through tests below: keeps GoRouter
  // resolvable without booting the whole app. The real registration is
  // covered separately via setupLocator() in the test after this setUp.
  setUp(() {
    if (!locator.isRegistered<GoRouter>()) {
      locator.registerSingleton<GoRouter>(AppRouter.router);
    }
  });

  test(
    'setupLocator registers GoRouter for the notification handler',
    () async {
      // Start from an empty locator so this assertion can only pass when
      // setupLocator itself performs the registration.
      await locator.reset();

      // main() runs loadAppEnv() before setupLocator(); AppConfig reads
      // dotenv, so seed it here without touching bundled assets.
      dotenv.loadFromString(envString: 'API_BASE_URL=https://example.test/');

      setupLocator();

      expect(locator.isRegistered<GoRouter>(), isTrue);
      expect(locator<GoRouter>(), same(AppRouter.router));
    },
  );

  test('click-through selects DMs tab + correct conversation', () async {
    final conversations = [dm('c1', 'Alice'), dm('c2', 'Bob')];
    final container = makeContainer(conversations: conversations);
    addTearDown(container.dispose);

    // Wait for the overridden async DM list to resolve.
    await container.read(dmListProvider.future);

    final service = container.read(notificationServiceProvider);
    await service.openDmFromNotification('c2');

    expect(container.read(homeSidebarProvider), HomeSidebarType.dms);
    expect(container.read(selectedDmProvider)?.channelId, 'c2');
  });

  test(
    'click-through for unknown conversation still lands on DMs tab',
    () async {
      final container = makeContainer(conversations: [dm('c1', 'Alice')]);
      addTearDown(container.dispose);

      await container.read(dmListProvider.future);

      // Pre-select an unrelated DM: an unknown notification must not leave
      // it open.
      container.read(selectedDmProvider.notifier).select(dm('c1', 'Alice'));

      final service = container.read(notificationServiceProvider);
      await service.openDmFromNotification('missing-id');

      expect(container.read(homeSidebarProvider), HomeSidebarType.dms);
      expect(container.read(selectedDmProvider), isNull);
    },
  );
}
