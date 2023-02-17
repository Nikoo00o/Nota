import 'package:server/core/config/server_config.dart';
import 'package:server/data/repositories/account_repository.dart';
import 'package:server/data/repositories/note_repository.dart';
import 'package:server/data/repositories/server_repository.dart';
import 'package:server/domain/entities/network/rest_callback.dart';
import 'package:shared/core/constants/endpoints.dart';
import 'package:shared/domain/usecases/usecase.dart';

/// Starts the nota server and adds the callbacks for the endpoints and starts the cleanup timer.
///
/// Remember to initialize GetIt first (including logger and local data source)
class StartNotaServer extends UseCase<bool, StartNotaServerParams> {
  final ServerConfig serverConfig;
  final ServerRepository serverRepository;
  final AccountRepository accountRepository;
  final NoteRepository noteRepository;

  const StartNotaServer({
    required this.serverConfig,
    required this.serverRepository,
    required this.accountRepository,
    required this.noteRepository,
  });

  @override
  Future<bool> execute(StartNotaServerParams params) async {
    final List<RestCallback> endpoints = <RestCallback>[
      RestCallback(endpoint: Endpoints.ABOUT, callback: serverRepository.handleAbout),
      RestCallback(endpoint: Endpoints.ACCOUNT_CREATE, callback: accountRepository.handleCreateAccountRequest),
      RestCallback(endpoint: Endpoints.ACCOUNT_LOGIN, callback: accountRepository.handleLoginToAccountRequest),
      RestCallback(
        endpoint: Endpoints.ACCOUNT_CHANGE_PASSWORD,
        callback: accountRepository.handleChangeAccountPasswordRequest,
      ),
      RestCallback(endpoint: Endpoints.NOTE_TRANSFER_START, callback: noteRepository.handleStartNoteTransfer),
      RestCallback(endpoint: Endpoints.NOTE_TRANSFER_FINISH, callback: noteRepository.handleFinishNoteTransfer),
      RestCallback(endpoint: Endpoints.NOTE_DOWNLOAD, callback: noteRepository.handleDownloadNote),
      RestCallback(endpoint: Endpoints.NOTE_UPLOAD, callback: noteRepository.handleUploadNote),
    ];

    await serverRepository.initEndpoints(endpoints);

    serverRepository.resetSessionCleanupTimer(serverConfig.clearOldSessionsAfter);

    return serverRepository.run(autoRestart: params.autoRestart, rsaPassword: params.rsaPassword);
  }
}

class StartNotaServerParams {
  /// If this is set to true, the UseCase will not return! Otherwise the UseCase will return if the server was started,
  /// or not!
  final bool autoRestart;

  /// Can be set from the command-line arguments
  final String? rsaPassword;

  const StartNotaServerParams({
    required this.autoRestart,
    this.rsaPassword,
  });
}
