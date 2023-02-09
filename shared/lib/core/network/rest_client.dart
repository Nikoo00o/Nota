import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;

import 'package:http/io_client.dart';
import 'package:shared/core/config/shared_config.dart';
import 'package:shared/core/constants/endpoints.dart';
import 'package:shared/core/exceptions/exceptions.dart';
import 'package:shared/core/constants/error_codes.dart';
import 'package:shared/core/enums/http_method.dart';
import 'package:shared/core/constants/rest_json_parameter.dart';
import 'package:shared/core/network/endpoint.dart';
import 'package:shared/core/utils/logger/logger.dart';
import 'package:shared/services/shared_session_service.dart';

/// Wrapper around a http client to connect to the REST API web server.
///
/// Will retrieve the server url from the [config] and the session token from the [sessionService]
class RestClient {
  final SharedConfig config;
  final SharedSessionService sessionService;
  late final IOClient client;

  /// successful http responses
  static const List<int> validHttpResponseCodes = <int>[200, 201, 202, 203, 204, 205, 206];

  RestClient({required this.config, required this.sessionService}) {
    final HttpClient httpClient = HttpClient();
    if (config.acceptSelfSignedCertificates) {
      httpClient.badCertificateCallback = (X509Certificate cert, String host, int port) => true;
    }
    client = IOClient(httpClient);
  }

  /// Will send a http request to the specified [endpoint] of the hostname stored in the [config].
  ///
  /// [endpoint] should be one of the [Endpoints].
  ///
  /// [queryParams] can always be used to add query params.
  /// [bodyData] can be used for put and post requests (the [endpoint] defines the http method).
  /// [httpHeaders] can be used to add additional http headers.
  ///
  /// If the endpoint has the property [endpoint.needsSessionToken] set to true, then the query params will automatically
  /// have the session token returned from the session service added to them!
  ///
  /// Throws a [ServerException] if the session token is null, or if any server error occurred! If the session token is
  /// invalid, the server returns the http status code 401.
  ///
  /// HTTP status code errors will be thrown as [ErrorCodes.HTTP_STATUS]statusCode.
  /// If the endpoint is unknown, 404 is returned.
  /// If the request is completely empty, or if the request parameter could not be parsed, 400 is returned.
  ///
  /// The [RestJsonParameter.SERVER_ERROR] jsn key will be thrown as one of [ErrorCodes]
  Future<Map<String, dynamic>> sendRequest({
    required Endpoint endpoint,
    Map<String, String> queryParams = const <String, String>{},
    Map<String, dynamic> bodyData = const <String, dynamic>{},
    Map<String, String> httpHeaders = const <String, String>{
      'Content-type': 'application/json',
      'Accept': 'application/json',
    },
  }) async {
    final Uri url = await _buildFinalUrl(endpoint, queryParams);

    Logger.debug("Sending the following ${endpoint.httpMethod} request to the server: $url");
    final http.Response response = await _send(url, endpoint.httpMethod, httpHeaders, bodyData);
    if (validHttpResponseCodes.contains(response.statusCode) == false) {
      throw ServerException(message: ErrorCodes.httpStatusWith(response.statusCode));
    }

    final dynamic jsonData = jsonDecode(response.body);
    if (jsonData is Map<String, dynamic>) {
      _checkResponseForErrors(jsonData);
      Logger.debug("Received the following response: $jsonData");
      return jsonData;
    } else {
      Logger.error("Error sending the request. Invalid JSON Data: $jsonData");
      throw const ServerException(message: ErrorCodes.UNKNOWN_SERVER);
    }
  }

  void _checkResponseForErrors(Map<String, dynamic> jsonMap) {
    if (jsonMap[RestJsonParameter.SERVER_ERROR] is String) {
      final String errorCode = jsonMap[RestJsonParameter.SERVER_ERROR] as String;
      Logger.error("Error sending the request, because of a server side error: $errorCode");
      throw ServerException(message: errorCode);
    }
  }

  Future<http.Response> _send(
      Uri url, HttpMethod httpMethod, Map<String, String> httpHeaders, Map<String, dynamic>? bodyData) async {
    try {
      late final http.Response response;

      switch (httpMethod) {
        case HttpMethod.GET:
          response = await client.get(url, headers: httpHeaders);
          break;
        case HttpMethod.POST:
          response = await client.post(url, headers: httpHeaders, body: jsonEncode(bodyData));
          break;
        case HttpMethod.PUT:
          response = await client.put(url, headers: httpHeaders, body: jsonEncode(bodyData));
          break;
        case HttpMethod.DELETE:
          response = await client.delete(url, headers: httpHeaders, body: jsonEncode(bodyData));
          break;
        default:
          throw const ServerException(message: ErrorCodes.UNKNOWN_HTTP_METHOD);
      }

      return response;
    } catch (e, s) {
      Logger.error("Error sending the request", e, s);
      if (e is ServerException) {
        rethrow;
      }
      throw const ServerException(message: ErrorCodes.UNKNOWN_SERVER);
    }
  }

  /// Adds together base server url, api url and the query parameter.
  /// throws a [ServerException] if the session token is null
  Future<Uri> _buildFinalUrl(Endpoint endpoint, Map<String, String> queryParams) async {
    String baseUrl = endpoint.getFullApiPath(config.getServerUrl());
    if (baseUrl.endsWith("/")) {
      baseUrl = baseUrl.substring(0, baseUrl.length - 1);
    }
    baseUrl = Uri.encodeFull(baseUrl);
    final String urlEncodedQueryParams = await _urlEncodeQueryParams(endpoint, queryParams);
    return Uri.parse("$baseUrl$urlEncodedQueryParams");
  }

  /// Also includes the session token and throws a [ServerException] if the session token is null
  Future<String> _urlEncodeQueryParams(Endpoint endpoint, Map<String, String> queryParams) async {
    if (queryParams.isEmpty && endpoint.needsSessionToken == false) {
      return "";
    }
    final StringBuffer buffer = StringBuffer();
    buffer.write("?");
    queryParams.forEach((String key, String value) {
      _writeToBuffer(buffer, key, value);
    });
    if (endpoint.needsSessionToken) {
      final String? sessionToken = await sessionService.fetchCurrentSessionToken();
      if (sessionToken != null) {
        _writeToBuffer(buffer, RestJsonParameter.SESSION_TOKEN, sessionToken);
      } else {
        Logger.error("Error sending the following ${endpoint.httpMethod} request to the server: ${endpoint.apiPath}");
        throw const ServerException(message: ErrorCodes.MISSING_SESSION_TOKEN);
      }
    }
    return buffer.toString();
  }

  /// url encodes parameter
  void _writeToBuffer(StringBuffer buffer, String key, String value) {
    if (buffer.length > 1) {
      buffer.write("&");
    }
    buffer.write(Uri.encodeComponent(key));
    buffer.write("=");
    buffer.write(Uri.encodeComponent(value));
  }
}
