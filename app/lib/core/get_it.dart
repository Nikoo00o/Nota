import 'package:app/core/config/app_config.dart';
import 'package:app/core/logger/app_logger.dart';
import 'package:app/data/datasources/local_data_source.dart';
import 'package:app/data/datasources/local_data_source_impl.dart';
import 'package:app/domain/usecases/fetch_current_session_token.dart';
import 'package:app/services/session_service.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:get_it/get_it.dart';
import 'package:shared/core/utils/logger/logger.dart';

/// Returns the GetIt service locator / singleton instance
final GetIt sl = GetIt.instance;

Future<void> initializeGetIt() async {
  Logger.initLogger(AppLogger());

  sl.registerLazySingleton<AppConfig>(() => AppConfig());
  sl.registerLazySingleton<LocalDataSource>(() => LocalDataSourceImpl(secureStorage: const FlutterSecureStorage()));
  sl.registerLazySingleton<SessionService>(() => SessionService());
  sl.registerLazySingleton<FetchCurrentSessionToken>(() => FetchCurrentSessionToken());

  await sl<LocalDataSource>().init();
}
