import 'package:app/core/config/app_config.dart';
import 'package:app/domain/entities/client_account.dart';
import 'package:app/domain/repositories/account_repository.dart';
import 'package:shared/core/constants/error_codes.dart';
import 'package:shared/core/exceptions/exceptions.dart';
import 'package:shared/core/utils/logger/logger.dart';
import 'package:shared/domain/usecases/usecase.dart';

/// This logs the user out of the app and clears the keys, but keeps the encrypted note data for later use
///
/// This can throw a [ClientException] with [ErrorCodes.CLIENT_NO_ACCOUNT]
class LogoutOfAccount extends UseCase<void, NoParams> {
  final AccountRepository accountRepository;
  final AppConfig appConfig;

  const LogoutOfAccount({required this.accountRepository, required this.appConfig});

  @override
  Future<void> execute(NoParams params) async {
    final ClientAccount account = await accountRepository.getAccountAndThrowIfNull();

    // update accounts login status
    account.needsServerSideLogin = true;

    // for security reasons, clear the saved user keys and also the session token
    account.clearDecryptedDataKey();
    account.passwordHash = "";
    account.sessionToken = null;

    // save the account
    await accountRepository.saveAccount(account);

    Logger.info("Logged out of the account: $account");
  }
}
