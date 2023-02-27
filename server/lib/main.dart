import 'package:args/args.dart';
import 'package:server/core/get_it.dart';
import 'package:server/data/datasources/local_data_source.dart';
import 'package:server/data/datasources/note_data_source.dart';
import 'package:server/domain/usecases/start_note_server.dart';
import 'package:shared/core/enums/log_level.dart';
import 'package:shared/core/utils/logger/logger.dart';

Future<void> main(List<String> arguments) async {
  Logger.initLogger(Logger(logLevel: LogLevel.VERBOSE));
  await initializeGetIt();
  await sl<LocalDataSource>().init();
  await sl<NoteDataSource>().init();

  final ArgParser parser = ArgParser()..addOption("rsaPassword", abbr: "r");
  final ArgResults argResults = parser.parse(arguments);
  final String? rsaPassword = argResults["rsaPassword"] as String?;

  await sl<StartNotaServer>().call(StartNotaServerParams(rsaPassword: rsaPassword, autoRestart: true));
}
