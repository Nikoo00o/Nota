import 'package:args/args.dart';
import 'package:server/core/get_it.dart';
import 'package:server/data/datasources/local_data_source.dart';
import 'package:server/data/datasources/note_data_source.dart';
import 'package:server/domain/usecases/start_note_server.dart';

Future<void> main(List<String> arguments) async {
  await initializeGetIt();
  await sl<LocalDataSource>().init();
  await sl<NoteDataSource>().init();

  final ArgParser parser = ArgParser()..addOption("rsaPassword", abbr: "r");
  final ArgResults argResults = parser.parse(arguments);
  final String? rsaPassword = argResults["rsaPassword"] as String?;

  await sl<StartNotaServer>().execute(StartNotaServerParams(rsaPassword: rsaPassword, autoRestart: true));
}
