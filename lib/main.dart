import 'package:zedu/core/core.dart';
import 'package:zedu/app/app.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await windowManager.ensureInitialized();
  await loadAppEnv();
  setupLocator();

  final windowState = WindowStateStore(locator<SecureStorageService>());
  await windowState.restore();
  WindowStateTracker(windowState).attach();

  runApp(const ProviderScope(child: App()));
}
