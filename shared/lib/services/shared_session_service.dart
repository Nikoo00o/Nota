import 'package:shared/core/network/rest_client.dart';

/// Base class for the session service of the app. is also used in the server tests because of the session token
abstract class SharedSessionService {
  /// This method should return the current session token and also refresh it if its about to expire.
  ///
  /// Otherwise null should be returned.
  ///
  /// This method will be used inside of the [RestClient]
  Future<String?> fetchCurrentSessionToken();
}
