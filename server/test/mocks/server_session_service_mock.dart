import 'package:shared/services/shared_session_service.dart';

class ServerSessionServiceMock extends SharedSessionService {
  @override
  Future<String?> fetchCurrentSessionToken() async {
    return "test";
  }
}
