/// The error codes which will be used in exceptions and translated with translation keys
class ErrorCodes {
  /// Only contains the prefix for the server http status code errors which can be send by the server and must be
  /// contained in the translation files like for example "server.http.404".
  /// automatically used during the server communication
  static const String HTTP_STATUS = "error.server.http.";

  /// Returns [HTTP_STATUS] with the connected [httpStatusCode]
  static String httpStatusWith(int httpStatusCode) => "$HTTP_STATUS$httpStatusCode";

  /// The client did not have a session token stored and could not send the request.
  /// automatically used during the server communication
  static const String MISSING_SESSION_TOKEN = "error.server.missing.token";

  /// Unknown server error like timeout, etc. automatically used during the server communication
  static const String UNKNOWN_SERVER = "error.server.unknown";

  /// Unknown http method used. automatically used during the server communication
  static const String UNKNOWN_HTTP_METHOD = "error.server.unknown.method";

  /// A datatype other than Map<String, dynamic>, or String is used for the body data when sending data.
  /// Or a "GET" request is send with body data, or a "PUT", or "POST" request is send without data!
  static const String INVALID_DATA_TYPE = "error.invalid.data.type";

  /// A file could not be read / opened. the translation text should have a param for the filename
  static const String FILE_NOT_FOUND = "error.file.not.found";

  /// Basic error code that can be used for callbacks where the client send request parameter with empty values.
  ///
  /// For empty requests with no key values at all, a http status code will be thrown.
  static const String SERVER_INVALID_REQUEST_VALUES = "error.server.invalid.request.values";

  /// Server already contains a user with that user name
  static const String SERVER_ACCOUNT_ALREADY_EXISTS = "error.server.account.exists";

  /// Server did not find the send user name
  static const String SERVER_UNKNOWN_ACCOUNT = "error.server.unknown.account";

  /// Account password hash did not match the one stored on the server
  static const String SERVER_ACCOUNT_WRONG_PASSWORD = "error.server.account.wrong.password";

  /// The note token for a note transfer was invalid (empty, or not contained in the transfer).
  ///
  /// This can happen if the transfer was cancelled by a different transfer from the server.
  static const String SERVER_INVALID_NOTE_TRANSFER_TOKEN = "error.server.invalid.note.transfer.token";
}

// todo: add translation strings
