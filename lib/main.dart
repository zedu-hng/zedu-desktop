// Review-flow end-to-end test. This PR is closed without merging.
import 'package:zedu/core/core.dart';
import 'package:zedu/app/app.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await windowManager.ensureInitialized();
  await loadAppEnv();
  setupLocator();

  runApp(const ProviderScope(child: App()));
}
