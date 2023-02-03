import 'package:shared/services/shared_session_service.dart';

class SessionService extends SharedSessionService {
  @override
  Future<String?> fetchCurrentSessionToken() async {
    //todo: also request new session token if current one is about to expire. return null if no session token was stored
    return "test";
  }
}
