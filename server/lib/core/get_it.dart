import 'package:get_it/get_it.dart';
import 'package:server/core/config/server_config.dart';
import 'package:server/data/datasources/account_data_source.dart.dart';
import 'package:server/data/datasources/local_data_source.dart';
import 'package:server/data/datasources/note_data_source.dart';
import 'package:server/data/repositories/account_repository.dart';
import 'package:server/data/repositories/note_repository.dart';
import 'package:server/data/repositories/server_repository.dart';
import 'package:server/data/datasources/rest_server.dart';
import 'package:server/domain/entities/server_account.dart';
import 'package:server/domain/usecases/fetch_authenticated_account.dart';
import 'package:server/domain/usecases/start_note_server.dart';
import 'package:server/domain/usecases/stop_nota_server.dart';
import 'package:shared/core/enums/log_level.dart';
import 'package:shared/core/utils/logger/logger.dart';

/// Returns the GetIt service locator / singleton instance
final GetIt sl = GetIt.instance;

/// Initializes all singletons (also the lazy ones).
///
/// Some registrations are done with the abstract type instead of the implementation type.
///
/// You should always initialize the logger first!!! The next calls after this should be: [LocalDataSource.init] and
/// [NoteDataSource.init]!
Future<void> initializeGetIt() async {
    Logger.initLogger(Logger(logLevel: LogLevel.VERBOSE));

  sl.registerLazySingleton<ServerConfig>(() => ServerConfig());
  sl.registerLazySingleton<RestServer>(
      () => RestServer(fetchAuthenticatedAccountCallback: _fetchAuthenticatedAccountCallback));

  sl.registerLazySingleton<LocalDataSource>(() => LocalDataSourceImpl(serverConfig: sl()));
  sl.registerLazySingleton<AccountDataSource>(() => AccountDataSource(serverConfig: sl(), localDataSource: sl()));
  sl.registerLazySingleton<NoteDataSource>(() => NoteDataSource(serverConfig: sl(), localDataSource: sl()));

  sl.registerLazySingleton<AccountRepository>(() => AccountRepository(accountDataSource: sl(), serverConfig: sl()));
  sl.registerLazySingleton<NoteRepository>(() => NoteRepository(
        noteDataSource: sl(),
        serverConfig: sl(),
        accountRepository: sl(),
      ));
  sl.registerLazySingleton<ServerRepository>(() => ServerRepository(
        serverConfig: sl(),
        restServer: sl(),
        accountRepository: sl(),
        noteRepository: sl(),
      ));

  sl.registerLazySingleton<StartNotaServer>(() => StartNotaServer(
        serverConfig: sl(),
        serverRepository: sl(),
        accountRepository: sl(),
        noteRepository: sl(),
      ));

  sl.registerLazySingleton<StopNotaServer>(() => StopNotaServer(
        serverRepository: sl(),
      ));
  sl.registerLazySingleton<FetchAuthenticatedAccount>(() => FetchAuthenticatedAccount(accountRepository: sl()));
}

Future<ServerAccount?> _fetchAuthenticatedAccountCallback(String sessionToken) =>
    sl<FetchAuthenticatedAccount>().call(FetchAuthenticatedAccountParams(sessionToken: sessionToken));
