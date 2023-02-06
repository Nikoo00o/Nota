import 'package:shared/core/constants/endpoints.dart';
import 'package:shared/core/constants/error_codes.dart';

/// The json keys (query, header, or body parameter) used for the REST API communication between server and client
class RestJsonParameter {
  /// The query parameter for the session token for authentication. Will be handled automatically!
  static const String SESSION_TOKEN = "SESSION_TOKEN";

  /// json body key for specific server errors. Should contain one of [ErrorCodes] which are then translated on the client
  /// Will be handled automatically!
  static const String SERVER_ERROR = "SERVER_ERROR";

  /// The response body json key for the text that the [Endpoints.ABOUT] endpoint returns
  static const String NOTA_ABOUT = "Nota REST API";
}
