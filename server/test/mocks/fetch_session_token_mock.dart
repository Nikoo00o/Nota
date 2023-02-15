import 'package:shared/domain/entities/session_token.dart';
import 'package:shared/domain/usecases/shared_fetch_current_session_token.dart';
import 'package:shared/domain/usecases/usecase.dart';

class FetchCurrentSessionTokenMock extends SharedFetchCurrentSessionToken {
  /// Used to mock the session token from the app client which will be used for requests
  SessionToken? sessionTokenOverride =
      SessionToken(token: "testSessionToken", validTo: DateTime.now().add(const Duration(days: 1)));

  @override
  Future<SessionToken?> execute(NoParams _) async {
    return sessionTokenOverride;
  }

  void setBasicSessionToken(String token) =>
      sessionTokenOverride = SessionToken(token: token, validTo: DateTime.now().add(const Duration(days: 1)));
}
