import 'package:args/args.dart';
import 'package:server/core/get_it.dart';
import 'package:server/domain/usecases/start_note_server.dart';

Future<void> main(List<String> arguments) async {
  await initializeGetIt();

  final ArgParser parser = ArgParser()..addOption("rsaPassword", abbr: "r");
  final ArgResults argResults = parser.parse(arguments);
  final String? rsaPassword = argResults["rsaPassword"] as String?;

  await sl<StartNotaServer>().execute(StartNotaServerParams(rsaPassword: rsaPassword, autoRestart: true));
}
