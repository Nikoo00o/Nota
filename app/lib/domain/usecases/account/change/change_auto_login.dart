import 'package:app/domain/entities/client_account.dart';
import 'package:app/domain/repositories/account_repository.dart';
import 'package:shared/core/constants/error_codes.dart';
import 'package:shared/core/exceptions/exceptions.dart';
import 'package:shared/core/utils/logger/logger.dart';
import 'package:shared/domain/usecases/usecase.dart';

/// Just changes the accounts config value [ClientAccount.storeDecryptedDataKey] and saves the account to storage again.
///
/// This can throw a [ClientException] with [ErrorCodes.CLIENT_NO_ACCOUNT]
class ChangeAutoLogin extends UseCase<void, GetAutoLoginParams> {
  final AccountRepository accountRepository;

  const ChangeAutoLogin({required this.accountRepository});

  @override
  Future<void> execute(GetAutoLoginParams params) async {
    final ClientAccount account = await accountRepository.getAccountAndThrowIfNull();
    account.storeDecryptedDataKey = params.autoLogin;
    await accountRepository.saveAccount(account);
    Logger.info("Changed auto login to ${params.autoLogin}");
  }
}

class GetAutoLoginParams {
  final bool autoLogin;

  const GetAutoLoginParams({required this.autoLogin});
}
