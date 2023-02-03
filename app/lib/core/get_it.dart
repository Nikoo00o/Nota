import 'package:app/core/config/app_config.dart';
import 'package:app/services/session_service.dart';
import 'package:get_it/get_it.dart';

/// Returns the GetIt service locator / singleton instance
final GetIt sl = GetIt.instance;

Future<void> initializeGetIt() async {
  sl.registerLazySingleton<AppConfig>(() => AppConfig());
  sl.registerLazySingleton<SessionService>(() => SessionService());
}
