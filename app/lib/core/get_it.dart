import 'package:app/core/config/app_config.dart';
import 'package:app/data/datasources/local_data_source.dart';
import 'package:app/data/datasources/local_data_source_impl.dart';
import 'package:app/services/session_service.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:get_it/get_it.dart';

/// Returns the GetIt service locator / singleton instance
final GetIt sl = GetIt.instance;

Future<void> initializeGetIt() async {
  sl.registerLazySingleton<AppConfig>(() => AppConfig());
  sl.registerLazySingleton<LocalDataSource>(() => LocalDataSourceImpl(secureStorage: const FlutterSecureStorage()));
  sl.registerLazySingleton<SessionService>(() => SessionService());
}
