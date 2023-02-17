import 'dart:async';
import 'dart:io';
import 'package:server/core/config/server_config.dart';
import 'package:server/data/repositories/account_repository.dart';
import 'package:server/data/repositories/note_repository.dart';
import 'package:server/domain/entities/network/rest_callback.dart';
import 'package:server/domain/entities/network/rest_callback_params.dart';
import 'package:server/domain/entities/network/rest_callback_result.dart';
import 'package:server/data/datasources/rest_server.dart';
import 'package:shared/core/constants/endpoints.dart';
import 'package:shared/core/constants/rest_json_parameter.dart';
import 'package:shared/core/utils/logger/logger.dart';

// following the clean architecture, this would be its own use case and also all of the callbacks for the requests would
// get their own use cases which should handle most of the work, or logic. But in my opinion for the scope of the whole
// project, the whole server part is already kind of in the data layer in relation to the app. So here the repositories
// and data sources also contain some business logic and work and there are no additional use cases and there is also no
// presentation layer, because the data will just get send back to the client.

/// The server side nota implementation for the REST API communication.
///
/// Controls the [RestServer]
class ServerRepository {
  final ServerConfig serverConfig;
  final RestServer restServer;
  final AccountRepository accountRepository;
  final NoteRepository noteRepository;

  bool _callbacksAdded = false;
  Timer? cleanupTimer;

  ServerRepository({
    required this.serverConfig,
    required this.restServer,
    required this.accountRepository,
    required this.noteRepository,
  });

  /// runs the http rest api server and will not return if [autoRestart] is set to true!
  /// Otherwise it returns if the server was started, or not!
  Future<bool> run({String? rsaPassword, required bool autoRestart}) async {
    final bool serverStarted = await restServer.start(
      certificateFilePath: serverConfig.certificatePath,
      privateKeyFilePath: serverConfig.privateKeyPath,
      rsaPassword: rsaPassword,
      port: serverConfig.serverPort,
    );

    if (serverStarted) {
      Logger.debug("Clients should be able to connect to ${Endpoints.ABOUT.getFullApiPath(serverConfig.getServerUrl())}");
    }

    if (serverStarted && autoRestart) {
      // will not return
      await restServer.restartAfterDone();
    }
    return serverStarted;
  }

  /// Will be called automatically from [run]
  void resetSessionCleanupTimer(Duration delay) {
    cleanupTimer?.cancel();
    cleanupTimer = Timer.periodic(delay, (Timer timer) => _cleanup());
  }

  /// Stops the rest api server and also calls the cleanup callback once and then cancels it
  Future<void> stop() async {
    await _cleanup();
    cleanupTimer?.cancel();
    await restServer.stop();
  }

  /// This is called periodically from the timer to remove no longer valid session tokens and the note transactions of those
  Future<void> _cleanup() async {
    await accountRepository.clearOldSessions();
    await noteRepository.cleanUpOldTransfers();
  }

  /// Adds the callbacks for the endpoints if they are not already initialized.
  ///
  /// [endpointCallbacks] must be a list of endpoints with a matching callback function which handles http requests to the
  /// endpoint.
  ///
  /// For http request where no callback is found, the StatusCode 404 will be returned.
  ///
  /// If the [endpoint] needs a session token for authentication, then the [RestServer.fetchAuthenticatedAccount] use case
  /// is used to
  /// return the attached account which the callback then can use.
  /// If the session token was invalid and the returned account was [null], the StatusCode 401 will be returned.
  ///
  /// Otherwise the StatusCode of the callback along with the json response will be returned to the client.
  /// If the callback throws an exception (for example because wrong request data could not be parsed), or if the request
  /// was empty, then the StatusCode 400 will be returned.
  ///
  /// The session token must be present in the query parameter with the tag [RestJsonParameter.SESSION_TOKEN]
  ///
  /// [endpoint] should be one of the [Endpoints].
  ///
  /// For example: <RestCallback>[RestCallback(endpoint: Endpoints.ABOUT, callback: ServerRepository.handleAbout)]
  Future<void> initEndpoints(List<RestCallback> endpointCallbacks) async {
    if (_callbacksAdded) {
      return;
    } else {
      _callbacksAdded = true;

    }
    for (final RestCallback callback in endpointCallbacks) {
      restServer.addCallback(callback: callback);
    }
  }

  /// An example callback for the endpoint [Endpoints.ABOUT]
  Future<RestCallbackResult> handleAbout(RestCallbackParams params) async {
    return RestCallbackResult(jsonResult: const <String, dynamic>{
      RestJsonParameter.NOTA_ABOUT: "This Webserver is used with the Nota App for"
          " synchronized note taking!",
    }, statusCode: HttpStatus.ok);
  }
}
