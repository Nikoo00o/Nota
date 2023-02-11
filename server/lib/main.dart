import 'dart:convert';

import 'package:args/args.dart';
import 'package:hive/hive.dart';
import 'package:server/core/config/server_config.dart';
import 'package:server/core/get_it.dart';
import 'package:server/data/repositories/server_repository.dart';
import 'package:shared/core/utils/logger/logger.dart';
import 'package:shared/core/utils/security_utils.dart';
import 'package:shared/core/utils/string_utils.dart';

Future<void> main(List<String> arguments) async {
  Logger.initLogger(Logger());
  await initializeGetIt();
  Hive.init(sl<ServerConfig>().resourceFolderPath);

  final ArgParser parser = ArgParser()..addOption("rsaPassword", abbr: "r");
  final ArgResults argResults = parser.parse(arguments);
  final String? rsaPassword = argResults["rsaPassword"] as String?;

  await sl<ServerRepository>().runNota(rsaPassword: rsaPassword, autoRestart: true);
}
