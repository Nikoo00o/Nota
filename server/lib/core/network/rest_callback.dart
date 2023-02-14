import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:server/domain/entities/server_account.dart';
import 'package:shared/core/constants/error_codes.dart';
import 'package:shared/core/constants/rest_json_parameter.dart';
import 'package:shared/core/enums/http_method.dart';
import 'package:shared/core/exceptions/exceptions.dart';
import 'package:shared/core/network/endpoint.dart';
import 'package:shared/data/dtos/response_dto.dart';
import 'package:shared/domain/entities/shared_account.dart';

/// The Result of a rest callback method which will be send to the client as a response
class RestCallbackResult {
  /// The json map that should be returned to the client which will be converted to a string. It can also be empty
  final Map<String, dynamic> jsonResult;

  /// The http status code that should be returned to the client
  final int statusCode;

  /// Instead of returning a json map, you can also return raw data bytes.
  ///
  /// If this is not null, then [jsonResult] will not be used
  List<int>? rawBytes;

  /// Contains additional response headers which should be send to the client. Otherwise this is empty.
  /// It has to be a modifiable map!!!
  /// Values for the keys [HttpHeaders.contentTypeHeader], [HttpHeaders.acceptHeader] and
  /// [HttpHeaders.contentLengthHeader] will be ignored, because they are set automatically to json, or octet-stream.
  late final Map<String, String> responseHeaders;

  /// Both Parameter have valid default values. If [rawBytes] is not null, it will replace [jsonResult]
  ///
  /// [responseHeaders] is optional and will be empty otherwise. It has to be a modifiable map!!!
  RestCallbackResult({
    this.jsonResult = const <String, dynamic>{},
    this.statusCode = HttpStatus.ok,
    this.rawBytes,
    Map<String, String>? responseHeaders,
  }) {
    this.responseHeaders = responseHeaders ?? <String, String>{};
  }

  /// Returns a RestCallbackResult with a specific [errorCode] from [ErrorCodes] as a json map with the key
  /// [RestJsonParameter.SERVER_ERROR]
  ///
  /// The http [statusCode] is optional.
  factory RestCallbackResult.withErrorCode(String errorCode, {int statusCode = HttpStatus.ok}) {
    return RestCallbackResult(
      jsonResult: <String, dynamic>{RestJsonParameter.SERVER_ERROR: errorCode},
      statusCode: statusCode,
    );
  }

  /// Returns a RestCallbackResult with a specific [ResponseDTO] by calling toJson() on the dto.
  ///
  /// The [statusCode] is optional.
  factory RestCallbackResult.withResponse(ResponseDTO responseDTO, {int statusCode = HttpStatus.ok}) {
    return RestCallbackResult(jsonResult: responseDTO.toJson(), statusCode: statusCode);
  }

  /// Returns either the json map, or raw data list of bytes depending on which was set
  dynamic get data => rawBytes ?? jsonResult;
}

/// The Parameter that a rest callback method will be called with.
///
/// The members will come from the clients http request.
///
/// For "POST", or "PUT" requests, either [jsonBody], or [rawBytes] will be set, but if the clients sends no data, it
/// can also happen that both are null!
class RestCallbackParams {
  /// the method of the http request from the client: "GET", "POST", "PUT", or "DELETE"
  final HttpMethod httpMethod;

  /// the query parameters (can be empty) from the client as map
  final Map<String, String> queryParams;

  /// the http request headers
  final Map<String, String> requestHeaders;

  /// the body data for "POST", or "PUT" (or also "DELETE") requests from the client if it was send in the json format
  final Map<String, dynamic>? jsonBody;

  /// the body data bytes for "POST", or "PUT" (or also "DELETE") requests from the client if it was send raw (like from a
  /// file)
  final List<int>? rawBytes;

  /// the remote address of the client
  final String ip;

  /// If the endpoint for the http request needed a session token and this request send a valid one, this will be the
  /// attached account to the request! Otherwise it will be [null]
  final SharedAccount? authenticatedAccount;

  RestCallbackParams({
    required this.httpMethod,
    required this.requestHeaders,
    required this.queryParams,
    required this.jsonBody,
    required this.rawBytes,
    required this.ip,
    required this.authenticatedAccount,
  }) {
    assert(httpMethod != HttpMethod.GET || (jsonBody == null && rawBytes == null),
        "Error: get requests may not have body data set");
    assert((jsonBody != null && rawBytes != null) == false, "Error: jsonBody and rawBytes may not both be set");
  }

  /// Casts the dynamic [data] either as [jsonBody], or [rawBytes] depending on its type.
  ///
  /// If [data] is neither Map<String, dynamic>, List<int>, or "null",  then a
  /// [ServerException] with [ErrorCodes.INVALID_DATA_TYPE] will be thrown!
  factory RestCallbackParams.castData({
    required HttpMethod httpMethod,
    required Map<String, String> requestHeaders,
    required Map<String, String> queryParams,
    required String ip,
    required SharedAccount? authenticatedAccount,
    required dynamic data,
  }) {
    if (data is Map<String, dynamic>) {
      return RestCallbackParams(
        httpMethod: httpMethod,
        requestHeaders: requestHeaders,
        queryParams: queryParams,
        jsonBody: data,
        rawBytes: null,
        ip: ip,
        authenticatedAccount: authenticatedAccount,
      );
    } else if (data is List<int>) {
      return RestCallbackParams(
        httpMethod: httpMethod,
        requestHeaders: requestHeaders,
        queryParams: queryParams,
        jsonBody: null,
        rawBytes: data,
        ip: ip,
        authenticatedAccount: authenticatedAccount,
      );
    } else if (data == null) {
      return RestCallbackParams(
        httpMethod: httpMethod,
        requestHeaders: requestHeaders,
        queryParams: queryParams,
        jsonBody: null,
        rawBytes: null,
        ip: ip,
        authenticatedAccount: authenticatedAccount,
      );
    }
    throw const ServerException(message: ErrorCodes.INVALID_DATA_TYPE);
  }

  /// Returns either the json map, or raw data list of bytes depending on which was used for "POST", "PUT" (, or "DELETE")
  /// requests. For "GET" requests, this will return "null"! For "POST" and "PUT" requests it can still be null if no data
  /// was send!
  dynamic get data => rawBytes != null ? rawBytes! : jsonBody;

  /// Returns the [authenticatedAccount] as a ServerAccount.
  ///
  /// Important: This only works for requests that need a session token and will throw an exception otherwise!
  ServerAccount getAttachedServerAccount() => authenticatedAccount as ServerAccount;
}

/// Used in RestServer to store the callback functions
class RestCallback {
  /// The endpoint for which this callback should be added for.
  ///
  /// Contains the api url and the http method which is used for this callback.
  final Endpoint endpoint;

  /// The callback function that will get called for the client requests
  final FutureOr<RestCallbackResult> Function(RestCallbackParams) callback;

  RestCallback({required this.endpoint, required this.callback});
}