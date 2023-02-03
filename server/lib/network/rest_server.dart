import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:server/network/rest_callback.dart';
import 'package:shared/core/network/endpoints.dart';
import 'package:shared/core/network/http_method.dart';
import 'package:shared/core/network/rest_json_parameter.dart';
import 'package:shared/core/utils/file_utils.dart';
import 'package:shared/core/utils/logger/logger.dart';
import 'package:shared/domain/entities/account.dart';

/// A https REST API Webserver that you can add callbacks to which will be called for specific http requests
class RestServer {
  HttpServer? _server;

  /// The callbacks which are called for the endpoints
  final List<RestCallback> _restCallbacks = <RestCallback>[];

  /// The callback for the endpoints that require a session token
  FutureOr<Account?> Function(String sessionToken)? _authenticationCallback;

  /// Starts the server and returns [true] if it was successful
  ///
  /// [privateKeyFilePath] can be null if the private key file does not need a password
  ///
  /// After calling start, use [addCallback] to add callbacks for client http requests to specific endpoint urls
  ///
  /// [authenticationCallback] is used for endpoints that require a session token for authentication and it should return
  /// the attached account if the session token was valid. Otherwise it should return null.
  Future<bool> start({
    required String certificateFilePath,
    required String privateKeyFilePath,
    String? rsaPassword,
    required int port,
    FutureOr<Account?> Function(String sessionToken)? authenticationCallback,
  }) async {
    _authenticationCallback = authenticationCallback;
    if (_server == null) {
      try {
        if (File(certificateFilePath).existsSync() == false) {
          Logger.error("Error starting REST API server: certificate file $certificateFilePath does not exist");
          return false;
        } else if (File(privateKeyFilePath).existsSync() == false) {
          Logger.error("Error starting REST API server: private key file $privateKeyFilePath does not exist");
          return false;
        } else {
          final SecurityContext serverContext = SecurityContext();
          serverContext.useCertificateChain(certificateFilePath);
          serverContext.usePrivateKey(privateKeyFilePath, password: rsaPassword);
          _server = await HttpServer.bindSecure(InternetAddress.anyIPv4, port, serverContext);

          _server!.listen(_onClientRequest, onError: (Object? error) {
            Logger.error("REST API error: $error");
          }, onDone: () {
            Logger.info("REST API server closed");
            _server = null;
          });

          Logger.info("Started REST API server");
          return true;
        }
      } catch (e, s) {
        Logger.error("Error starting REST API server", e, s);
      }
    }
    Logger.error("Error starting REST API server: server is already running");
    return false;
  }

  /// Is called when the server receives data from the client
  Future<void> _onClientRequest(HttpRequest request) async {
    try {
      final String fullApiPath = request.requestedUri.path;
      final Map<String, String> queryParams = request.requestedUri.queryParameters;
      final Map<String, dynamic>? jsonBody = await _getJsonBody(request);
      final String clientIp = request.connectionInfo?.remoteAddress.address ?? "";
      Logger.info("Got request ${request.requestedUri} from $clientIp with data: $jsonBody");

      late RestCallbackResult response;
      if (queryParams.isEmpty && fullApiPath.isEmpty && (jsonBody?.isEmpty ?? false)) {
        response = RestCallbackResult(jsonResult: <String, dynamic>{}, statusCode: HttpStatus.badRequest);
      } else {
        response = await _handleCallback(request, fullApiPath, queryParams, jsonBody, clientIp);
      }

      request.response.statusCode = response.statusCode;
      request.response.headers.contentType = ContentType.json;
      request.response.headers.add("Accept", "application/json");
      request.response.write(jsonEncode(response.jsonResult));
      await request.response.close();

      Logger.info("Send response for ${request.requestedUri} to $clientIp with status code: ${response.statusCode} "
          "and data: ${response.jsonResult}");
    } catch (e, s) {
      Logger.error("REST API error parsing request", e, s);
    }
  }

  Future<Map<String, dynamic>?> _getJsonBody(HttpRequest request) async {
    final String dataString = await getEncoding(request.headers).decodeStream(request);
    if (dataString.isNotEmpty) {
      final dynamic json = jsonDecode(dataString);
      if (json is Map<String, dynamic>) {
        return json;
      }
    }
    return null;
  }

  Future<RestCallbackResult> _handleCallback(HttpRequest request, String fullApiPath, Map<String, String> queryParams,
      Map<String, dynamic>? jsonBody, String clientIp) async {
    final Iterable<RestCallback> iterator =
        _restCallbacks.where((RestCallback element) => fullApiPath.endsWith(element.endpoint.apiPath));
    if (iterator.isNotEmpty) {
      assert(iterator.length == 1, "Error, two Endpoints got matched for a request ${request.requestedUri}");
      Account? authenticatedAccount;

      if (iterator.first.endpoint.needsSessionToken) {
        final String sessionToken = queryParams[RestJsonParameter.SESSION_TOKEN] ?? "";
        authenticatedAccount = await _authenticationCallback?.call(sessionToken);
        if (authenticatedAccount == null) {
          Logger.error("REST API error, the Request ${request.requestedUri} from $clientIp does not contain a valid session "
              "token");
          return RestCallbackResult(jsonResult: <String, dynamic>{}, statusCode: HttpStatus.unauthorized);
        }
      }

      return iterator.first.callback.call(RestCallbackParams(
        httpMethod: HttpMethod.fromString(request.method),
        queryParams: queryParams,
        data: jsonBody,
        ip: clientIp,
        authenticatedAccount: authenticatedAccount,
      ));
    } else {
      return RestCallbackResult(jsonResult: <String, dynamic>{}, statusCode: HttpStatus.notFound);
    }
  }

  /// Adds a new callback for the specific endpoint (url and http method) to respond to a client http request.
  ///
  /// For http request where no callback is found, the StatusCode 404 will be returned and for empty requests 400 will be
  /// returned.
  ///
  /// If the [endpoint] needs a session token for authentication, then the [_authenticationCallback] method is used to
  /// return the attached account which the callback then can use.
  /// If the session token was invalid and the returned account was [null], the StatusCode 401 will be returned.
  ///
  /// Otherwise the StatusCode of the callback along with the json response will be returned to the client.
  ///
  /// The session token must be present in the query parameter with the tag [RestJsonParameter.SESSION_TOKEN]
  void addCallback({
    required Endpoint endpoint,
    required FutureOr<RestCallbackResult> Function(RestCallbackParams) callback,
  }) {
    _restCallbacks.add(RestCallback(endpoint: endpoint, callback: callback));
  }

  /// Close the server. but it can be started again with another call to [start]
  Future<void> stop() async {
    try {
      Logger.info("Closing REST API server");
      await _server?.close();
      _server = null;
    } catch (e, s) {
      Logger.error("Error closing REST API server", e, s);
    }
  }

  /// Will call start and automatically restart the server if it closes after a delay.
  ///
  /// This method will never return.
  Future<void> restartAfterDone({
    required String certificateFilePath,
    required String privateKeyFilePath,
    String? rsaPassword,
    required int port,
    FutureOr<Account?> Function(String sessionToken)? authenticationCallback,
  }) async {
    while (true) {
      await Future<void>.delayed(const Duration(seconds: 10));
      if (_server == null) {
        await start(
            certificateFilePath: certificateFilePath,
            privateKeyFilePath: privateKeyFilePath,
            rsaPassword: rsaPassword,
            port: port,
            authenticationCallback: authenticationCallback);
      }
    }
  }
}
