import 'package:get_it/get_it.dart';
import 'package:server/core/config/server_config.dart';
import 'package:server/data/datasources/account_data_source.dart.dart';
import 'package:server/data/datasources/local_data_source.dart';
import 'package:server/data/datasources/note_data_source.dart';
import 'package:server/data/repositories/account_repository.dart';
import 'package:server/data/repositories/note_repository.dart';
import 'package:server/data/repositories/server_repository.dart';
import 'package:server/data/datasources/rest_server.dart';
import 'package:server/domain/usecases/fetch_authenticated_account.dart';
import 'package:server/domain/usecases/start_note_server.dart';
import 'package:server/domain/usecases/stop_nota_server.dart';
import 'package:shared/core/utils/logger/logger.dart';

/// Returns the GetIt service locator / singleton instance
final GetIt sl = GetIt.instance;

/// This and all constructor calls inside may not call the logger, because it will be initialized later!
Future<void> initializeGetIt() async {
  Logger.initLogger(Logger());

  sl.registerLazySingleton<ServerConfig>(() => ServerConfig());
  sl.registerLazySingleton<FetchAuthenticatedAccount>(() => FetchAuthenticatedAccount(accountRepository: sl()));
  sl.registerLazySingleton<RestServer>(() => RestServer(fetchAuthenticatedAccount: sl()));
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

  await sl<LocalDataSource>().init();
  await sl<NoteDataSource>().init();
}
