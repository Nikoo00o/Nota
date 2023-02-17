import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:server/domain/entities/network/rest_callback.dart';
import 'package:server/domain/entities/network/rest_callback_params.dart';
import 'package:server/domain/entities/network/rest_callback_result.dart';
import 'package:server/domain/entities/server_account.dart';
import 'package:server/domain/usecases/fetch_authenticated_account.dart';
import 'package:shared/core/constants/endpoints.dart';
import 'package:shared/core/constants/rest_json_parameter.dart';
import 'package:shared/core/enums/http_method.dart';
import 'package:shared/core/network/endpoint.dart';
import 'package:shared/core/network/network_utils.dart';
import 'package:shared/core/utils/file_utils.dart';
import 'package:shared/core/utils/logger/logger.dart';

/// A https REST API Webserver that you can add callbacks to which will be called for specific http requests.
///
/// [fetchAuthenticatedAccount] is used for endpoints that require a session token for authentication and it should return
/// the attached account if the session token was valid. Otherwise it should return null.
class RestServer {
  HttpServer? _server;

  StreamSubscription<HttpRequest>? _subscription;

  /// The callbacks which are called for the endpoints
  final List<RestCallback> _restCallbacks = <RestCallback>[];

  late SecurityContext _securityContext;

  late int _port;

  final FetchAuthenticatedAccount fetchAuthenticatedAccount;

  RestServer({required this.fetchAuthenticatedAccount});

  /// Starts the server and returns [true] if it was successful
  ///
  /// [certificateFilePath] and [privateKeyFilePath] must be the absolute path to the rsa key / tls certificate
  ///
  /// [privateKeyFilePath] can be null if the private key file does not need a password
  ///
  /// After calling start, use [addCallback] to add callbacks for client http requests to specific endpoint urls
  Future<bool> start({
    required String certificateFilePath,
    required String privateKeyFilePath,
    String? rsaPassword,
    required int port,
  }) async {
    if (_server == null) {
      if (FileUtils.fileExists(certificateFilePath) == false) {
        Logger.error("Error starting REST API server: certificate file $certificateFilePath does not exist");
        return false;
      } else if (FileUtils.fileExists(privateKeyFilePath) == false) {
        Logger.error("Error starting REST API server: private key file $privateKeyFilePath does not exist");
        return false;
      } else {
        _port = port;
        _securityContext = SecurityContext();
        _securityContext.useCertificateChain(certificateFilePath);
        _securityContext.usePrivateKey(privateKeyFilePath, password: rsaPassword);

        return _internalRun();
      }
    } else {
      Logger.error("Error starting REST API server: server is already running");
    }
    return false;
  }

  Future<bool> _internalRun() async {
    try {
      _server = await HttpServer.bindSecure(InternetAddress.anyIPv4, _port, _securityContext);

      _subscription = _server!.listen(_onClientRequest, onError: (Object? error) {
        Logger.error("REST API error: $error");
      }, onDone: () {
        Logger.debug("REST API server closed");
        _server = null;
      });

      Logger.debug("Started REST API server");
      return true;
    } catch (e, s) {
      Logger.error("Error starting REST API server", e, s);
      return false;
    }
  }

  /// Is called when the server receives data from the client
  Future<void> _onClientRequest(HttpRequest request) async {
    late RestCallbackResult response;
    final String clientIp = request.connectionInfo?.remoteAddress.address ?? "";
    final String fullApiPath = request.requestedUri.path;

    final Map<String, String> queryParams = request.requestedUri.queryParameters
        .map((String key, String value) => MapEntry<String, String>(Uri.decodeComponent(key), Uri.decodeComponent(value)));

    try {
      final dynamic requestData =
          await NetworkUtils.decodeNetworkDataStream(httpHeaders: request.headers.asMap(), data: request);

      Logger.debug("Got request ${request.requestedUri} from $clientIp ${_getDynamicLog(requestData)}");

      if (queryParams.isEmpty && fullApiPath.isEmpty && requestData == null) {
        response = RestCallbackResult(jsonResult: const <String, dynamic>{}, statusCode: HttpStatus.badRequest);
      } else {
        response = await _handleCallback(request, fullApiPath, queryParams, requestData, clientIp);
      }
    } catch (e, s) {
      Logger.error("REST API error parsing request", e, s);
      response = RestCallbackResult(jsonResult: const <String, dynamic>{}, statusCode: HttpStatus.badRequest);
    }

    try {
      await _send(request.response, response);

      Logger.debug("Send response for ${request.requestedUri} to $clientIp "
          "with status code: ${response.statusCode} ${_getDynamicLog(response.data)}");
    } catch (e, s) {
      Logger.error("REST API error sending response", e, s);
    }
  }

  String _getDynamicLog(dynamic data) {
    if (data is Map<String, dynamic>) {
      return " and with json data: $data";
    } else if (data is List<int>) {
      return " and with raw data bytes";
    } else {
      return " and with no body data $data";
    }
  }

  Future<void> _send(HttpResponse httpResponse, RestCallbackResult resultData) async {
    final List<int> responseData =
        NetworkUtils.encodeNetworkData(httpHeaders: resultData.responseHeaders, data: resultData.data);
    httpResponse.statusCode = resultData.statusCode;
    resultData.responseHeaders.forEach((String key, String value) => httpResponse.headers.add(key, value));
    httpResponse.add(responseData);
    await httpResponse.close();
  }

  /// Calls the [fetchAuthenticatedAccount] to return the attached [ServerAccount] to a valid [sessionToken], or otherwise
  /// [null]
  Future<ServerAccount?> _getAuthenticatedAccount(Map<String, String> queryParams) async {
    final String sessionToken = queryParams[RestJsonParameter.SESSION_TOKEN] ?? "";
    return fetchAuthenticatedAccount.call(FetchAuthenticatedAccountParams(sessionToken: sessionToken));
  }

  Future<RestCallbackResult> _handleCallback(
      HttpRequest request, String fullApiPath, Map<String, String> queryParams, dynamic bodyData, String clientIp) async {
    final Iterable<RestCallback> matchingRestCallbackIt = _restCallbacks.where((RestCallback element) =>
        fullApiPath.endsWith(element.endpoint.apiPath) &&
        HttpMethod.fromString(request.method) == element.endpoint.httpMethod);

    if (matchingRestCallbackIt.isNotEmpty) {
      assert(matchingRestCallbackIt.length == 1, "Error, two Endpoints got matched for a request ${request.requestedUri}");
      ServerAccount? authenticatedAccount;

      if (matchingRestCallbackIt.first.endpoint.needsSessionToken) {
        authenticatedAccount = await _getAuthenticatedAccount(queryParams);
        if (authenticatedAccount == null) {
          Logger.error("REST API error, the Request ${request.requestedUri} from $clientIp does not contain a valid session "
              "token");
          return RestCallbackResult(jsonResult: const <String, dynamic>{}, statusCode: HttpStatus.unauthorized);
        }
      }

      final RestCallbackParams restCallbackParams = RestCallbackParams.castData(
        httpMethod: HttpMethod.fromString(request.method),
        requestHeaders: request.headers.asMap(),
        queryParams: queryParams,
        data: bodyData,
        ip: clientIp,
        authenticatedAccount: authenticatedAccount,
      );

      return matchingRestCallbackIt.first.callback.call(restCallbackParams);
    } else {
      return RestCallbackResult(jsonResult: const <String, dynamic>{}, statusCode: HttpStatus.notFound);
    }
  }

  /// Adds a new callback for the specific endpoint (url and http method) to respond to a client http request.
  ///
  /// For http request where no callback is found, the StatusCode 404 will be returned.
  ///
  /// If the [endpoint] needs a session token for authentication, then the [fetchAuthenticatedAccount] use case is used to
  /// return the attached account which the callback then can use.
  /// If the session token was invalid and the returned account was [null], the StatusCode 401 will be returned.
  ///
  /// Otherwise the StatusCode of the callback along with the json response will be returned to the client.
  /// If the callback throws an exception (for example because wrong request data could not be parsed), or if the request
  /// was empty, then the StatusCode 400 will be returned.
  ///
  /// The session token must be present in the query parameter with the tag [RestJsonParameter.SESSION_TOKEN]
  ///
  /// [endpoint] should be one of the [Endpoints]
  void addCallback({required RestCallback callback}) {
    _restCallbacks.add(callback);
  }

  /// Close the server. but it can be started again with another call to [start]
  Future<void> stop() async {
    if (_server == null) {
      return;
    }
    try {
      Logger.debug("Closing REST API server");
      await _subscription?.cancel();
      await _server?.close();
      _server = null;
    } catch (e, s) {
      Logger.error("Error closing REST API server", e, s);
    }
  }

  /// Will restart the server automatically if it stops. Only call this method after a call to [start] returns true
  ///
  /// This method will never return if it has been called after a successful call to [start]
  Future<void> restartAfterDone() async {
    if (_server == null) {
      Logger.error("Error trying to restart a rest server which has not been started! Returning.");
      return;
    }
    while (true) {
      await Future<void>.delayed(const Duration(seconds: 10));
      if (_server == null) {
        await _internalRun();
      }
    }
  }
}
