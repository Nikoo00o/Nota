import 'dart:async';
import 'dart:io';
import 'package:server/core/config/server_config.dart';
import 'package:server/data/repositories/account_repository.dart';
import 'package:server/core/network/rest_callback.dart';
import 'package:server/core/network/rest_server.dart';
import 'package:shared/core/constants/endpoints.dart';
import 'package:shared/core/constants/rest_json_parameter.dart';
import 'package:shared/core/utils/logger/logger.dart';

/// The server side nota implementation for the REST API communication.
///
/// Controls the [RestServer]
class ServerRepository {
  final ServerConfig serverConfig;
  final RestServer restServer;
  final AccountRepository accountRepository;

  ServerRepository({required this.serverConfig, required this.restServer, required this.accountRepository});

  /// runs the nota server and will not return if [autoRestart] is set to true!
  /// Otherwise it returns if the server was started!
  /// Will also add the callbacks for the clients http requests.
  ///
  /// Also starts a periodic timer which calls [accountRepository.clearOldSessions].
  Future<bool> runNota({String? rsaPassword, required bool autoRestart}) async {
    await _addCallbacks();

    final bool serverStarted = await restServer.start(
      certificateFilePath: serverConfig.certificatePath,
      privateKeyFilePath: serverConfig.privateKeyPath,
      rsaPassword: rsaPassword,
      port: serverConfig.serverPort,
      authenticationCallback: accountRepository.getAccountBySessionToken,
    );

    if (serverStarted) {
      Logger.debug("Clients should be able to connect to ${Endpoints.ABOUT.getFullApiPath(serverConfig.getServerUrl())}");
    }

    Timer.periodic(serverConfig.clearOldSessionsAfter, (Timer timer) {
      accountRepository.clearOldSessions();
    });

    if (serverStarted && autoRestart) {
      // will not return
      await restServer.restartAfterDone(
        certificateFilePath: serverConfig.certificatePath,
        privateKeyFilePath: serverConfig.privateKeyPath,
        rsaPassword: rsaPassword,
        port: serverConfig.serverPort,
        authenticationCallback: accountRepository.getAccountBySessionToken,
      );
    }
    return serverStarted;
  }

  Future<void> _addCallbacks() async {
    restServer.addCallback(endpoint: Endpoints.ABOUT, callback: _handleAbout);
    restServer.addCallback(endpoint: Endpoints.ACCOUNT_CREATE, callback: accountRepository.handleCreateAccountRequest);
    restServer.addCallback(endpoint: Endpoints.ACCOUNT_LOGIN, callback: accountRepository.handleLoginToAccountRequest);
    restServer.addCallback(
        endpoint: Endpoints.ACCOUNT_CHANGE_PASSWORD, callback: accountRepository.handleChangeAccountPasswordRequest);
  }

  Future<RestCallbackResult> _handleAbout(RestCallbackParams params) async {
    return RestCallbackResult(jsonResult: <String, dynamic>{
      RestJsonParameter.NOTA_ABOUT: "This Webserver is used with the Nota App for"
          " synchronized note taking!",
    }, statusCode: HttpStatus.ok);
  }
}
