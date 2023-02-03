import 'package:app/core/config/app_config.dart';
import 'package:get_it/get_it.dart';

/// Returns the GetIt service locator / singleton instance
final GetIt sl = GetIt.instance;

Future<void> initializeGetIt() async {
  sl.registerLazySingleton<AppConfig>(() => AppConfig());
}
