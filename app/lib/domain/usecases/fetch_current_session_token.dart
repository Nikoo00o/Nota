import 'package:shared/domain/entities/session_token.dart';
import 'package:shared/domain/usecases/shared_fetch_current_session_token.dart';
import 'package:shared/domain/usecases/usecase.dart';

/// This use case should return the current session token and also refresh it if its about to expire.
///
/// Otherwise null should be returned.
///
/// This use case will be used inside of the [RestClient]
class FetchCurrentSessionToken extends SharedFetchCurrentSessionToken {
  @override
  Future<SessionToken?> execute(NoParams params) async {
    //todo: also request new session token if current one is about to expire. return null if no session token was stored.
    // maybe just use delegate the call to the account repository here
    return SessionToken(token: "test", validTo: DateTime.now().add(const Duration(days: 1)));
  }
}
