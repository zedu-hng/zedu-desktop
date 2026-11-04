import 'package:zedu/core/core.dart';
import 'package:zedu/app/app.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await windowManager.ensureInitialized();
  await loadAppEnv();
  setupLocator();
  await locator<GlobalHotkeyService>().init();

  runApp(const ProviderScope(child: App()));
}
