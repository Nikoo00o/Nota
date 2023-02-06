import 'package:shared/core/enums/http_method.dart';
import 'package:shared/core/network/endpoint.dart';

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
