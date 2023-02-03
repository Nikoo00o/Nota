import 'package:get_it/get_it.dart';
import 'package:server/config/server_config.dart';
import 'package:server/network/nota_server.dart';
import 'package:server/network/rest_server.dart';

/// Returns the GetIt service locator / singleton instance
final GetIt sl = GetIt.instance;

Future<void> initializeGetIt() async {
  sl.registerLazySingleton<ServerConfig>(() => ServerConfig());
  sl.registerLazySingleton<RestServer>(() => RestServer());
  sl.registerLazySingleton<NotaServer>(() => NotaServer(serverConfig: sl(), restServer: sl()));
}
