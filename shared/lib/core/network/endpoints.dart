import 'package:shared/core/config/shared_config.dart';
import 'package:shared/core/network/http_method.dart';

class Endpoint {
  /// The path added to the base url of the [SharedConfig] to reach this endpoint. Does not contain any query parameters!
  final String apiPath;

  /// The http method used for this endpoint.
  ///
  /// Will be used on the client side to use the specific http method.
  ///
  /// Will also be used on the server side to add callbacks for the specific http methods:
  /// "GET", "POST", "PUT", or "DELETE", or "ALL" if every http method should be accepted.
  final HttpMethod httpMethod;

  /// If a request to this endpoint must contain a session token from a logged in account for authentication.
  ///
  /// If [true], the request will have an attached account.
  final bool needsSessionToken;

  const Endpoint({
    required this.apiPath,
    required this.httpMethod,
    this.needsSessionToken = false,
  });

  /// Returns the base api path combined with the api path of the endpoint
  ///
  /// [baseApiPath] should be [SharedConfig.getServerUrl]
  String getFullApiPath(String baseApiPath) {
    if (baseApiPath.endsWith(apiPath)) {
      return baseApiPath;
    }
    int slashAmount = 0;
    if (baseApiPath.endsWith("/")) {
      slashAmount++;
    }
    if (apiPath.startsWith("/")) {
      slashAmount++;
    }
    if (slashAmount == 0) {
      return "$baseApiPath/$apiPath";
    } else if (slashAmount == 1) {
      return "$baseApiPath$apiPath";
    } else {
      return "${baseApiPath.substring(0, baseApiPath.length - 1)}$apiPath"; // 2 slashes
    }
  }
}

/// The shared endpoints between server and client which are used for the REST API communication.
///
/// An endpoint should never contain the full api path of another, because otherwise the matching could fail!
///
/// Important: the api Path must a valid url encoded path that will be added to the base server url!
class Endpoints {
  /// Example Endpoint which can also be used inside of a web browser for information about this server
  static const Endpoint ABOUT = Endpoint(
    apiPath: "/api/about",
    httpMethod: HttpMethod.GET,
  );
  static const Endpoint ACCOUNT_CREATE = Endpoint(
    apiPath: "/api/account/create",
    httpMethod: HttpMethod.POST,
  );

  static const Endpoint ACCOUNT_LOGIN = Endpoint(
    apiPath: "/api/account/login",
    httpMethod: HttpMethod.POST,
  );

  static const Endpoint ACCOUNT_CHANGE_PASSWORD = Endpoint(
    apiPath: "/api/account/change",
    httpMethod: HttpMethod.POST,
    needsSessionToken: true,
  );
}
