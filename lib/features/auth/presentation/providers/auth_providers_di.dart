import 'package:zedu/core/core.dart';
import 'package:zedu/features/features.dart';

final authRemoteDataSourceProvider = Provider<AuthRemoteDataSource>(
  (ref) => AuthRemoteDataSourceImpl(
    config: locator<AppConfig>(),
    apiBaseService: locator<ApiBaseService>(),
  ),
);

final authRepositoryProvider = Provider<AuthRepository>(
  (ref) => AuthRepositoryImpl(remote: ref.watch(authRemoteDataSourceProvider)),
);

/// How long [AuthNotifier.loginWithGoogle] waits for Google's redirect to
/// reach the loopback server before giving up. Overridden in tests so they
/// do not have to wait out the real bound.
final googleRedirectTimeoutProvider = Provider<Duration>(
  (ref) => const Duration(minutes: 2),
);

/// Opens a URL in the user's browser. Injected so the Google sign-in flow can
/// be driven in tests without launching a real browser.
final externalUrlLauncherProvider = Provider<Future<bool> Function(Uri)>(
  (ref) =>
      (uri) => launchUrl(uri, mode: LaunchMode.externalApplication),
);

final authNotifierProvider = NotifierProvider<AuthNotifier, AuthState>(
  AuthNotifier.new,
);
