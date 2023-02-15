import 'package:server/data/repositories/account_repository.dart';
import 'package:server/domain/entities/server_account.dart';
import 'package:shared/domain/usecases/usecase.dart';

/// Should return a matching account if the session token is valid and otherwise null.
///
/// Will also remove no longer valid session tokens and also add loaded accounts to the cache.
///
/// The authenticated account can also be accessed from the [RestCallbackParams] in http callbacks that use [Endpoints]
/// which need the session token!
/// If an account would be null for one of those callbacks, the callbacks would return an error automatically.
class FetchAuthenticatedAccount extends UseCase<ServerAccount?, FetchAuthenticatedAccountParams> {
  final AccountRepository accountRepository;

  const FetchAuthenticatedAccount({required this.accountRepository});

  @override
  Future<ServerAccount?> execute(FetchAuthenticatedAccountParams params) async {
    return accountRepository.getAccountBySessionToken(params.sessionToken);
  }
}

class FetchAuthenticatedAccountParams {
  final String sessionToken;

  const FetchAuthenticatedAccountParams({required this.sessionToken});
}
