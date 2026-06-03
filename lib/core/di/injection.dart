import 'package:get_it/get_it.dart';
import 'package:injectable/injectable.dart';

import 'app_module.dart'; // Ensure it's imported
import 'injection.config.dart';

/// Global GetIt service locator instance.
///
/// Use this to resolve dependencies throughout the app.
/// Prefer constructor injection via `@injectable` annotations
/// over direct `getIt<T>()` calls where possible.
final getIt = GetIt.instance;

/// Initializes all dependencies registered via Injectable annotations.
///
/// Call this in `main()` before `runApp()` to ensure all services
/// are available when the widget tree builds.
///
/// Example:
/// ```dart
/// void main() async {
///   WidgetsFlutterBinding.ensureInitialized();
///   await configureDependencies();
///   runApp(const App());
/// }
/// ```
@InjectableInit()
Future<void> configureDependencies() async {
  // Manual registrations for third-party modules that injectable missed
  getIt.init();
}
