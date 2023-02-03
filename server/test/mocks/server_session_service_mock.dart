import 'package:shared/services/abstract_session_service.dart';

class ServerSessionServiceMock extends AbstractSessionService {
  @override
  Future<String?> fetchCurrentSessionToken() async {
    return "test";
  }
}
