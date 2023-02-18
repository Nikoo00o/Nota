import 'package:app/core/config/app_config.dart';
import 'package:app/core/logger/app_logger.dart';
import 'package:app/data/datasources/local_data_source.dart';
import 'package:app/data/datasources/local_data_source_impl.dart';
import 'package:app/data/datasources/remote_account_data_source.dart';
import 'package:app/data/repositories/account_repository_impl.dart';
import 'package:app/domain/repositories/account_repository.dart';
import 'package:app/domain/usecases/fetch_current_session_token.dart';
import 'package:app/services/session_service.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:get_it/get_it.dart';
import 'package:shared/core/utils/logger/logger.dart';
import 'package:shared/data/datasources/rest_client.dart';
import 'package:shared/domain/entities/session_token.dart';
import 'package:shared/domain/usecases/shared_fetch_current_session_token.dart';
import 'package:shared/domain/usecases/usecase.dart';

/// Returns the GetIt service locator / singleton instance
final GetIt sl = GetIt.instance;

Future<void> initializeGetIt() async {
  Logger.initLogger(AppLogger());

  sl.registerLazySingleton<AppConfig>(() => AppConfig());
  sl.registerLazySingleton<RestClient>(() => RestClient(
        sharedConfig: _config(),
        fetchSessionTokenCallback: _fetchCurrentSessionToken,
      ));

  sl.registerLazySingleton<LocalDataSource>(() => LocalDataSourceImpl(
        secureStorage: const FlutterSecureStorage(),
        appConfig: sl(),
      )); // needs to be [LocalDataSourceImpl] for [LocalDataSource]!
  sl.registerLazySingleton<RemoteAccountDataSource>(() => RemoteAccountDataSource(restClient: sl()));

  // needs to be [FetchCurrentSessionToken] for [SharedFetchCurrentSessionToken]!
  sl.registerLazySingleton<SharedFetchCurrentSessionToken>(() => FetchCurrentSessionToken(accountRepository: sl()));

  sl.registerLazySingleton<AccountRepository>(() => AccountRepositoryImpl(
        remoteAccountDataSource: sl(),
        localDataSource: sl(),
      )); // needs to be [AccountRepositoryImpl] for [AccountRepository]

  sl.registerLazySingleton<SessionService>(() => SessionService());

  await sl<LocalDataSource>().init();
}

Future<SessionToken?> _fetchCurrentSessionToken() => sl<SharedFetchCurrentSessionToken>().call(NoParams());

AppConfig _config() => sl<AppConfig>();
