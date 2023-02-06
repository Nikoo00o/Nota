import 'package:args/args.dart';
import 'package:hive/hive.dart';
import 'package:server/config/server_config.dart';
import 'package:server/get_it.dart';
import 'package:server/data/repositories/server_repository.dart';
import 'package:shared/core/utils/logger/logger.dart';

Future<void> main(List<String> arguments) async {
  Logger.initLogger(Logger());
  await initializeGetIt();
  Hive.init(sl<ServerConfig>().resourceFolderPath);

  final ArgParser parser = ArgParser()..addOption("rsaPassword", abbr: "r");
  final ArgResults argResults = parser.parse(arguments);
  final String? rsaPassword = argResults["rsaPassword"] as String?;

  await sl<ServerRepository>().runNota(rsaPassword: rsaPassword, autoRestart: true);
}
