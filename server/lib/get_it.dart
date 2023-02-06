import 'package:get_it/get_it.dart';
import 'package:server/config/server_config.dart';
import 'package:server/data/datasources/account_data_source.dart.dart';
import 'package:server/data/datasources/local_data_source.dart';
import 'package:server/data/repositories/account_repository.dart';
import 'package:server/data/repositories/server_repository.dart';
import 'package:server/network/rest_server.dart';

/// Returns the GetIt service locator / singleton instance
final GetIt sl = GetIt.instance;

Future<void> initializeGetIt() async {
  sl.registerLazySingleton<ServerConfig>(() => ServerConfig());
  sl.registerLazySingleton<RestServer>(() => RestServer());
  sl.registerLazySingleton<LocalDataSource>(() => LocalDataSourceImpl(serverConfig: sl()));
  sl.registerLazySingleton<AccountDataSource>(() => AccountDataSource(serverConfig: sl(), localDataSource: sl()));
  sl.registerLazySingleton<AccountRepository>(() => AccountRepository(accountDataSource: sl(), serverConfig: sl()));
  sl.registerLazySingleton<ServerRepository>(() => ServerRepository(
        serverConfig: sl(),
        restServer: sl(),
        accountRepository: sl(),
      ));
}
