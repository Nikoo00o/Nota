import 'package:args/args.dart';
import 'package:server/get_it.dart';
import 'package:server/network/nota_server.dart';
import 'package:shared/core/utils/logger/logger.dart';

Future<void> main(List<String> arguments) async {
  Logger.initLogger(Logger());
  await initializeGetIt();
  final ArgParser parser = ArgParser()..addOption("rsaPassword", abbr: "r");
  final ArgResults argResults = parser.parse(arguments);
  final String? rsaPassword = argResults["rsaPassword"] as String?;
  await sl<NotaServer>().runNota(rsaPassword: rsaPassword, autoRestart: true);
}
