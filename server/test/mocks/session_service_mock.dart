import 'package:shared/services/shared_session_service.dart';

class SessionServiceMock extends SharedSessionService {
  /// Used to mock the session token from the app client which will be used for requests
  String sessionTokenOverride = "testSessionToken";

  @override
  Future<String?> fetchCurrentSessionToken() async {
    return sessionTokenOverride;
  }
}
