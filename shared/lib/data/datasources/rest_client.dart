import 'dart:io';
import 'dart:typed_data';
import 'package:http/http.dart' as http;

import 'package:http/io_client.dart';
import 'package:shared/core/config/shared_config.dart';
import 'package:shared/core/constants/endpoints.dart';
import 'package:shared/core/constants/error_codes.dart';
import 'package:shared/core/constants/rest_json_parameter.dart';
import 'package:shared/core/enums/http_method.dart';
import 'package:shared/core/exceptions/exceptions.dart';
import 'package:shared/core/network/endpoint.dart';
import 'package:shared/core/network/network_utils.dart';
import 'package:shared/core/utils/logger/logger.dart';
import 'package:shared/domain/entities/response_data.dart';
import 'package:shared/domain/entities/session_token.dart';

/// Wrapper around a http client to connect to the REST API web server.
///
/// Will retrieve the server url from the [sharedConfig].
///
/// Will retrieve the session token for the authenticated account from the [fetchSessionTokenCallback]. This is needed for
/// some http requests where the endpoint needs the logged in account!
class RestClient {
  final SharedConfig sharedConfig;
  final Future<SessionToken?> Function() fetchSessionTokenCallback;
  late final IOClient client;

  /// successful http responses
  static const List<int> validHttpResponseCodes = <int>[200, 201, 202, 203, 204, 205, 206];

  RestClient({required this.sharedConfig, required this.fetchSessionTokenCallback}) {
    final HttpClient httpClient = HttpClient();
    if (sharedConfig.acceptSelfSignedCertificates) {
      httpClient.badCertificateCallback = (X509Certificate cert, String host, int port) => true;
    }
    httpClient.connectionTimeout = sharedConfig.connectionTimeout;
    client = IOClient(httpClient);
  }

  /// Will send a http request to the specified [endpoint] of the hostname stored in the [sharedConfig].
  ///
  /// [endpoint] should be one of the [Endpoints].
  ///
  /// [queryParams] can always be used to add query params.
  ///
  /// [bodyData] can be used for put and post (and also delete) requests (the [endpoint] defines the http method).
  /// [bodyData] can be a json map of String and dynamic, or it can be a list of raw bytes! Or of course it can be null
  ///
  /// For GET requests [bodyData] must be null!
  ///
  /// [httpHeaders] can be used to add additional http headers.
  /// Values for the keys [HttpHeaders.contentTypeHeader], [HttpHeaders.acceptHeader] and
  /// [HttpHeaders.contentLengthHeader] will be ignored, because they are set automatically to json, or octet-stream.
  ///
  /// The Accept header will also include those 2 if its missing
  ///
  /// If the endpoint has the property [endpoint.needsSessionToken] set to true, then the query params will automatically
  /// have the session token returned from the [fetchSessionTokenCallback] added to them!
  ///
  /// Throws a [ServerException] if any server error occurred by using the [RestJsonParameter.SERVER_ERROR] json key!
  /// If the session token is null, the error code will be [ErrorCodes.MISSING_SESSION_TOKEN]
  ///
  /// HTTP status code errors will be thrown as [ServerException] with [ErrorCodes.HTTP_STATUS]statusCode.
  /// If the session token is invalid, 401 (unauthorized) is returned
  /// If the endpoint is unknown, 404 (not found) is returned.
  /// If the request is completely empty, or if the request parameter could not be parsed, 400 (bad request) is returned.
  ///
  ///
  /// In most cases the returned data will be a json map of string and dynamic, but for file downloads it can also
  /// be a list of raw bytes! It will never be null.
  ///
  /// If the content type did not match the type of the data, a [ServerException] with [ErrorCodes.INVALID_DATA_TYPE] will
  /// be thrown! If no data was send, then a [ServerException] with [ErrorCodes.UNKNOWN_SERVER] will be thrown which will
  /// also be thrown on timeout!
  ///
  /// For some file requests (like the note transfer), a [FileException] with [ErrorCodes.FILE_NOT_FOUND] can also be thrown.
  Future<ResponseData> sendRequest({
    required Endpoint endpoint,
    Map<String, String> queryParams = const <String, String>{},
    dynamic bodyData,
    Map<String, String>? httpHeaders,
  }) async {
    final Uri url = await _buildFinalUrl(endpoint, queryParams);

    if (endpoint.httpMethod == HttpMethod.GET && bodyData != null) {
      Logger.error("Can not send a GET request to $url with body data");
      throw const ServerException(message: ErrorCodes.INVALID_DATA_TYPE);
    }

    final Map<String, String> requestHeaders = httpHeaders ?? <String, String>{};
    final List<int> requestData = NetworkUtils.encodeNetworkData(httpHeaders: requestHeaders, data: bodyData);

    Logger.verbose("Sending the following ${endpoint.httpMethod} request to the server: $url");
    final http.Response response = await _send(url, endpoint.httpMethod, requestHeaders, requestData);

    if (validHttpResponseCodes.contains(response.statusCode) == false) {
      Logger.error("Received invalid http status code from server: ${response.statusCode}");
      throw ServerException(message: ErrorCodes.httpStatusWith(response.statusCode));
    }

    final dynamic responseData =
        NetworkUtils.decodeNetworkData(httpHeaders: response.headers, data: response.bodyBytes);

    if (responseData is Map<String, dynamic>) {
      _checkResponseForErrors(responseData);
      Logger.verbose("Received the following JSON response:\n$responseData");
      return ResponseData(json: responseData, bytes: null, responseHeaders: response.headers);
    } else if (responseData is List<int>) {
      Logger.verbose("Received binary data");
      return ResponseData(json: null, bytes: responseData, responseHeaders: response.headers);
    } else {
      Logger.verbose("Received empty / no data from server");
      return ResponseData(json: null, bytes: Uint8List(0), responseHeaders: response.headers);
    }
  }

  /// This is the same as [sendRequest], but with explicit types for json communication.
  ///
  /// For "GET" http requests, the [bodyData] must stay empty!
  Future<Map<String, dynamic>> sendJsonRequest({
    required Endpoint endpoint,
    Map<String, String> queryParams = const <String, String>{},
    Map<String, dynamic> bodyData = const <String, dynamic>{},
    Map<String, String>? httpHeaders,
  }) async {
    final ResponseData response = await sendRequest(
        endpoint: endpoint,
        queryParams: queryParams,
        bodyData: bodyData.isEmpty ? null : bodyData,
        httpHeaders: httpHeaders);
    return response.json!;
  }

  void _checkResponseForErrors(Map<String, dynamic> jsonMap) {
    if (jsonMap[RestJsonParameter.SERVER_ERROR] is String) {
      final String errorCode = jsonMap[RestJsonParameter.SERVER_ERROR] as String;
      Logger.error("Error sending the request, because of a server side error: $errorCode");
      throw ServerException(message: errorCode);
    }
  }

  Future<http.Response> _send(
      Uri url, HttpMethod httpMethod, Map<String, String> httpHeaders, List<int> bytesToSend) async {
    try {
      late final http.Response response;

      switch (httpMethod) {
        case HttpMethod.GET:
          response = await client.get(url, headers: httpHeaders);
          break;
        case HttpMethod.POST:
          response = await client.post(url, headers: httpHeaders, body: bytesToSend);
          break;
        case HttpMethod.PUT:
          response = await client.put(url, headers: httpHeaders, body: bytesToSend);
          break;
        case HttpMethod.DELETE:
          response = await client.delete(url, headers: httpHeaders, body: bytesToSend);
          break;
        default:
          throw const ServerException(message: ErrorCodes.UNKNOWN_HTTP_METHOD);
      }

      return response;
    } catch (e, s) {
      Logger.error("Error sending the $httpMethod request with the headers: $httpHeaders", e, s);
      if (e is ServerException) {
        rethrow;
      }
      throw const ServerException(message: ErrorCodes.UNKNOWN_SERVER);
    }
  }

  /// Adds together base server url, api url and the query parameter.
  /// throws a [ServerException] if the session token is null
  Future<Uri> _buildFinalUrl(Endpoint endpoint, Map<String, String> queryParams) async {
    String baseUrl = endpoint.getFullApiPath(sharedConfig.getServerUrl());
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
    if (endpoint.needsSessionToken) {
      final SessionToken? sessionToken = await fetchSessionTokenCallback();
      if (sessionToken != null && sessionToken.isStillValid()) {
        _writeToBuffer(buffer, RestJsonParameter.SESSION_TOKEN, sessionToken.token);
      } else {
        Logger.error("Error sending the following ${endpoint.httpMethod} request to the server: ${endpoint.apiPath}");
        throw const ServerException(message: ErrorCodes.MISSING_SESSION_TOKEN);
      }
    }
    queryParams.forEach((String key, String value) {
      _writeToBuffer(buffer, key, value);
    });
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

  /// Closes the inner http client t o terminate the active connections
  void close() {
    client.close();
  }
}
