import 'package:app/core/config/app_config.dart';
import 'package:app/core/logger/app_logger.dart';
import 'package:app/data/datasources/local_data_source.dart';
import 'package:app/data/datasources/local_data_source_impl.dart';
import 'package:app/data/datasources/remote_account_data_source.dart';
import 'package:app/data/datasources/remote_note_data_source.dart';
import 'package:app/data/repositories/account_repository_impl.dart';
import 'package:app/data/repositories/app_settings_repository_impl.dart';
import 'package:app/data/repositories/note_transfer_repository_impl.dart';
import 'package:app/domain/repositories/account_repository.dart';
import 'package:app/domain/repositories/app_settings_repository.dart';
import 'package:app/domain/repositories/note_transfer_repository.dart';
import 'package:app/domain/usecases/account/change/change_account_password.dart';
import 'package:app/domain/usecases/account/change/change_auto_login.dart';
import 'package:app/domain/usecases/account/change/logout_of_account.dart';
import 'package:app/domain/usecases/account/fetch_current_session_token.dart';
import 'package:app/domain/usecases/account/get_auto_login.dart';
import 'package:app/domain/usecases/account/login/create_account.dart';
import 'package:app/domain/usecases/account/login/get_required_login_status.dart';
import 'package:app/domain/usecases/account/login/login_to_account.dart';
import 'package:app/services/session_service.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:get_it/get_it.dart';
import 'package:shared/core/enums/log_level.dart';
import 'package:shared/core/utils/logger/logger.dart';
import 'package:shared/data/datasources/rest_client.dart';
import 'package:shared/domain/entities/session_token.dart';
import 'package:shared/domain/usecases/shared_fetch_current_session_token.dart';
import 'package:shared/domain/usecases/usecase.dart';

/// Returns the GetIt service locator / singleton instance
final GetIt sl = GetIt.instance;

/// Initializes all singletons (also the lazy ones).
///
/// Some registrations are done with the abstract type instead of the implementation type, like for example:
/// [SharedFetchCurrentSessionToken] for [FetchCurrentSessionToken] and [AccountRepository] for [AccountRepositoryImpl].
///
/// Also initializes the logger first. The next call after this should be: [LocalDataSource.init]
Future<void> initializeGetIt() async {
  Logger.initLogger(AppLogger(logLevel: LogLevel.VERBOSE));

  sl.registerLazySingleton<AppConfig>(() => AppConfig());
  sl.registerLazySingleton<RestClient>(
      () => RestClient(sharedConfig: _config(), fetchSessionTokenCallback: fetchCurrentSessionToken));

  sl.registerLazySingleton<LocalDataSource>(
      () => LocalDataSourceImpl(secureStorage: const FlutterSecureStorage(), appConfig: sl()));

  sl.registerLazySingleton<RemoteAccountDataSource>(() => RemoteAccountDataSourceImpl(restClient: sl()));
  sl.registerLazySingleton<RemoteNoteDataSource>(() => RemoteNoteDataSourceImpl(restClient: sl()));

  sl.registerLazySingleton<AccountRepository>(() => AccountRepositoryImpl(
        remoteAccountDataSource: sl(),
        localDataSource: sl(),
        appConfig: sl(),
      ));
  sl.registerLazySingleton<NoteTransferRepository>(() => NoteTransferRepositoryImpl(
        remoteNoteDataSource: sl(),
        localDataSource: sl(),
      ));
  sl.registerLazySingleton<AppSettingsRepository>(() => AppSettingsRepositoryImpl(localDataSource: sl(), appConfig: sl()));

  sl.registerLazySingleton<SharedFetchCurrentSessionToken>(
      () => FetchCurrentSessionToken(accountRepository: sl(), appConfig: sl()));
  sl.registerLazySingleton<CreateAccount>(() => CreateAccount(accountRepository: sl(), appConfig: sl()));
  sl.registerLazySingleton<GetRequiredLoginStatus>(() => GetRequiredLoginStatus(accountRepository: sl()));
  sl.registerLazySingleton<LoginToAccount>(() => LoginToAccount(
        accountRepository: sl(),
        appConfig: sl(),
        getRequiredLoginStatus: sl(),
      ));
  sl.registerLazySingleton<LogoutOfAccount>(() => LogoutOfAccount(accountRepository: sl(), appConfig: sl()));
  sl.registerLazySingleton<ChangeAccountPassword>(() => ChangeAccountPassword(accountRepository: sl(), appConfig: sl()));
  sl.registerLazySingleton<GetAutoLogin>(() => GetAutoLogin(accountRepository: sl()));
  sl.registerLazySingleton<ChangeAutoLogin>(() => ChangeAutoLogin(accountRepository: sl()));

  sl.registerLazySingleton<SessionService>(() => SessionService());
}

Future<SessionToken?> fetchCurrentSessionToken() => sl<SharedFetchCurrentSessionToken>().call(NoParams());

AppConfig _config() => sl<AppConfig>();
