import 'dart:io';
import 'package:server/config/server_config.dart';
import 'package:server/network/rest_callback.dart';
import 'package:server/network/rest_server.dart';
import 'package:shared/core/network/endpoints.dart';
import 'package:shared/core/utils/file_utils.dart';
import 'package:shared/core/utils/logger/logger.dart';
import 'package:shared/domain/entities/account.dart';

/// The server side nota implementation for the REST API communication.
///
/// Controls the [RestServer]
class ServerRepository {
  final ServerConfig serverConfig;
  final RestServer restServer;

  ServerRepository({required this.serverConfig, required this.restServer});

  /// runs the nota server and will not return if [autoRestart] is set to true!
  /// Otherwise it returns if the server was started!
  /// Will also add the callbacks for the clients http requests
  Future<bool> runNota({String? rsaPassword, required bool autoRestart}) async {
    restServer.addCallback(endpoint: Endpoints.ABOUT, callback: _handleAbout);
    restServer.addCallback(endpoint: Endpoints.ACCOUNT_CREATE, callback: _handleCreateAccount);
    restServer.addCallback(endpoint: Endpoints.ACCOUNT_LOGIN, callback: _handleLoginAccount);
    restServer.addCallback(endpoint: Endpoints.ACCOUNT_CHANGE_PASSWORD, callback: _handleChangeAccountPassword);

    final bool serverStarted = await restServer.start(
      certificateFilePath: getLocalFilePath(serverConfig.certificatePath),
      privateKeyFilePath: getLocalFilePath(serverConfig.privateKeyPath),
      rsaPassword: rsaPassword,
      port: serverConfig.serverPort,
      authenticationCallback: _sessionTokenAuthentication,
    );
    if (serverStarted) {
      Logger.info("Clients should be able to connect to ${Endpoints.ABOUT.getFullApiPath(serverConfig.getServerUrl())}");
    }
    if (serverStarted && autoRestart) {
      await restServer.restartAfterDone(
        certificateFilePath: getLocalFilePath(serverConfig.certificatePath),
        privateKeyFilePath: getLocalFilePath(serverConfig.privateKeyPath),
        rsaPassword: rsaPassword,
        port: serverConfig.serverPort,
        authenticationCallback: _sessionTokenAuthentication,
      );
    }
    return serverStarted;
  }

  Future<Account?> _sessionTokenAuthentication(String sessionToken) async {
    if (sessionToken.isNotEmpty) {
      return Account(userName: "test", passwordHash: "test");
    }
    return null;
    // todo: here check and remove session token if no longer valid. in the callbacks only use the session token to access
    //  the  account. and maybe return a nullable account? which then also gets passed to the callback?
  }

  Future<RestCallbackResult> _handleAbout(RestCallbackParams params) async {
    return RestCallbackResult(jsonResult: <String, dynamic>{
      "Nota REST API": "This Webserver is used with the Nota App for"
          " synchronized note taking!",
    }, statusCode: HttpStatus.ok);
  }

  Future<RestCallbackResult> _handleCreateAccount(RestCallbackParams params) async {
    return RestCallbackResult(jsonResult: params.data ?? <String, dynamic>{}, statusCode: HttpStatus.ok);
  }

  Future<RestCallbackResult> _handleLoginAccount(RestCallbackParams params) async {
    return RestCallbackResult(jsonResult: params.data ?? <String, dynamic>{}, statusCode: HttpStatus.ok);
  }

  Future<RestCallbackResult> _handleChangeAccountPassword(RestCallbackParams params) async {
    return RestCallbackResult(
      jsonResult: <String, dynamic>{params.authenticatedAccount!.userName: params.authenticatedAccount!.passwordHash},
      statusCode: HttpStatus.ok,
    );
  }
}
