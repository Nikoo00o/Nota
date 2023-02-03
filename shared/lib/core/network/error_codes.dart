/// The error codes which will be used in exceptions and translated with translation keys
class ErrorCodes {
  /// Only contains the prefix for the server http status code errors which can be send by the server and must be
  /// contained in the translation files like for example "server.http.404"
  static const String HTTP_STATUS = "error.server.http.";

  /// The client did not have a session token stored and could not send the request
  static const String MISSING_SESSION_TOKEN = "error.server.missing.token";

  /// Unknown server error like timeout, etc
  static const String UNKNOWN_SERVER = "error.server.unknown";

  /// Unknown http method used
  static const String UNKNOWN_HTTP_METHOD = "error.server.unknown.method";

  /// Server did not find the send user name
  static const String UNKNOWN_USERNAME = "error.server.unknown.user";
}

// todo: add translation strings