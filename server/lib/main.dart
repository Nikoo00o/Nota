import 'dart:async';

import 'package:args/args.dart';
import 'package:server/core/get_it.dart';
import 'package:server/core/logger/server_logger.dart';
import 'package:server/data/datasources/local_data_source.dart';
import 'package:server/data/datasources/note_data_source.dart';
import 'package:server/domain/usecases/start_note_server.dart';
import 'package:shared/core/enums/log_level.dart';
import 'package:shared/core/utils/logger/logger.dart';

Future<void> main(List<String> arguments) async {
  await runZonedGuarded(() async {
    Logger.initLogger(Logger(logLevel: LogLevel.DEBUG));
    final ArgParser parser = ArgParser()
      ..addOption("rsaPassword", abbr: "r")
      ..addOption("loglevel", abbr: "l");
    final ArgResults argResults = parser.parse(arguments);
    final String? rsaPassword = argResults["rsaPassword"] as String?;
    final String? logLevelStr = argResults["loglevel"] as String?;
    final int? logLevel = int.tryParse(logLevelStr ?? "");

    await initializeGetIt();
    if (logLevel != null && logLevel >= 0 && logLevel < LogLevel.values.length) {
      Logger.initLogger(ServerLogger(logLevel: LogLevel.values[logLevel], serverConfig: sl()));
    } else {
      Logger.initLogger(ServerLogger(logLevel: LogLevel.VERBOSE, serverConfig: sl()));
    }
    Logger.debug("Using log level ${Logger.currentLogLevel}");
    await sl<LocalDataSource>().init();
    await sl<NoteDataSource>().init();

    await sl<StartNotaServer>().call(StartNotaServerParams(rsaPassword: rsaPassword, autoRestart: true));
  }, (Object? error, StackTrace stack) {
    Logger.error("Async Zone Error", error, stack);
  });
}
