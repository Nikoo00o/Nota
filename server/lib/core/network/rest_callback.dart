import 'dart:async';
import 'dart:io';
import 'package:shared/core/constants/error_codes.dart';
import 'package:shared/core/constants/rest_json_parameter.dart';
import 'package:shared/core/enums/http_method.dart';
import 'package:shared/core/network/endpoint.dart';
import 'package:shared/data/dtos/response_dto.dart';
import 'package:shared/domain/entities/shared_account.dart';

/// The Result of a rest callback method which will be send to the client as a response
class RestCallbackResult {
  /// The json map that should be returned to the client which will be converted to a string
  final Map<String, dynamic> jsonResult;

  /// The http status code that should be returned to the client
  final int statusCode;

  /// Both Parameter have valid default values
  RestCallbackResult({this.jsonResult = const <String, dynamic>{}, this.statusCode = HttpStatus.ok});

  /// Returns a RestCallbackResult with a specific [errorCode] from [ErrorCodes] as a json map with the key
  /// [RestJsonParameter.SERVER_ERROR]
  ///
  /// The [statusCode] is optional.
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
}

/// The Parameter that a rest callback method will be called with.
///
/// The members will come from the clients http request.
class RestCallbackParams {
  /// the method of the http request from the client: "GET", "POST", "PUT", or "DELETE"
  final HttpMethod httpMethod;

  /// the query parameters (can be empty) from the client as map
  final Map<String, String> queryParams;

  /// the body data for "POST", or "PUT" requests from the client
  final Map<String, dynamic>? data;

  /// the remote address of the client
  final String ip;

  /// If the endpoint for the http request needed a session token and this request send a valid one, this will be the
  /// attached account to the request! Otherwise it will be [null]
  final SharedAccount? authenticatedAccount;

  RestCallbackParams({
    required this.httpMethod,
    required this.queryParams,
    required this.data,
    required this.ip,
    required this.authenticatedAccount,
  });
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
