import 'dart:async';
import 'package:shared/core/network/endpoints.dart';
import 'package:shared/core/network/http_method.dart';
import 'package:shared/domain/entities/account.dart';

/// The Result of a rest callback method which will be send to the client as a response
class RestCallbackResult {
  /// The json map that should be returned to the client which will be converted to a string
  final Map<String, dynamic> jsonResult;

  /// The http status code that should be returned to the client
  final int statusCode;

  RestCallbackResult({required this.jsonResult, required this.statusCode});
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
  final Account? authenticatedAccount;

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
