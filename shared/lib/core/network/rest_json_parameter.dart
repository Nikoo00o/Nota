import 'package:shared/core/network/error_codes.dart';

/// The json keys (query, header, or body parameter) used for the REST API communication between server and client
class RestJsonParameter {
  /// The query parameter for the session token for authentication
  static const String SESSION_TOKEN = "SESSION_TOKEN";
  /// json body key for specific server errors. Should contain one of [ErrorCodes] which are then translated on the client
  static const String SERVER_ERROR = "SERVER_ERROR";
}
