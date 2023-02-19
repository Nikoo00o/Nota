import 'package:app/core/config/app_config.dart';
import 'package:app/domain/entities/client_account.dart';
import 'package:app/domain/repositories/account_repository.dart';
import 'package:shared/core/utils/logger/logger.dart';
import 'package:shared/data/datasources/rest_client.dart';
import 'package:shared/domain/entities/session_token.dart';
import 'package:shared/domain/usecases/shared_fetch_current_session_token.dart';
import 'package:shared/domain/usecases/usecase.dart';

/// This use case should return the current session token and also refresh it if its about to expire.
///
/// Otherwise null should be returned.
///
/// This use case will be used inside of the [RestClient] for http requests that need an authenticated account!
class FetchCurrentSessionToken extends SharedFetchCurrentSessionToken {
  final AccountRepository accountRepository;

  final AppConfig appConfig;

  FetchCurrentSessionToken({required this.accountRepository, required this.appConfig});

  @override
  Future<SessionToken?> execute(NoParams params) async {
    ClientAccount? account = await accountRepository.getAccount();
    if (account == null) {
      Logger.error("Error, could not fetch a session token, because no account is stored");
      return null;
    }
    if (account.isSessionTokenValidFor(appConfig.sessionTokenRefreshAfterRemainingTime) == false) {
      Logger.info("Refreshing session token...");
      account = await accountRepository.login();
      await accountRepository.saveAccount(account);
    }
    Logger.debug("Fetched session token ${account.sessionToken}");
    return account.sessionToken;
  }
}
