import 'package:app/core/config/app_config.dart';
import 'package:app/domain/entities/client_account.dart';
import 'package:app/domain/repositories/account_repository.dart';
import 'package:shared/core/constants/error_codes.dart';
import 'package:shared/core/exceptions/exceptions.dart';
import 'package:shared/core/utils/logger/logger.dart';
import 'package:shared/domain/usecases/usecase.dart';

/// This logs the user out of the app and clears the keys and sets the account to null, but keeps the encrypted note data
/// for later use and caches the note info for the account!
///
/// This can throw a [ClientException] with [ErrorCodes.CLIENT_NO_ACCOUNT]
class LogoutOfAccount extends UseCase<void, NoParams> {
  final AccountRepository accountRepository;
  final AppConfig appConfig;

  const LogoutOfAccount({required this.accountRepository, required this.appConfig});

  @override
  Future<void> execute(NoParams params) async {
    final ClientAccount account = await accountRepository.getAccountAndThrowIfNull();

    // cache note info list for the account
    if (account.noteInfoList.isNotEmpty) {
      Logger.verbose("Storing the notes\n${account.noteInfoList}\nfor later use for the account ${account.userName}");
      await accountRepository.saveNotesForOldAccount(account.userName, account.noteInfoList);
      account.noteInfoList.clear();
    }

    // for security reasons, clear the saved user keys and also the session token in memory (because the reference could
    // still be used somewhere)
    account.clearDecryptedDataKey();
    account.passwordHash = "";
    account.sessionToken = null;
    // also update accounts login status
    account.needsServerSideLogin = true;

    // clear the cached and stored account
    await accountRepository.saveAccount(null);

    Logger.info("Logged out of the account ${account.userName}");
  }
}
