import 'package:app/domain/entities/client_account.dart';
import 'package:app/domain/repositories/account_repository.dart';
import 'package:shared/core/constants/error_codes.dart';
import 'package:shared/core/exceptions/exceptions.dart';
import 'package:shared/domain/usecases/usecase.dart';

/// Just returns the accounts server synchronized config value [ClientAccount.storeDecryptedDataKey].
///
/// If this returns false, then the user needs to log in to the app again with his password on restarting the app.
///
/// This can throw a [ClientException] with [ErrorCodes.CLIENT_NO_ACCOUNT]
class GetAutoLogin extends UseCase<bool, NoParams> {
  final AccountRepository accountRepository;

  const GetAutoLogin({required this.accountRepository});

  @override
  Future<bool> execute(NoParams params) async {
    final ClientAccount account = await accountRepository.getAccountAndThrowIfNull();
    return account.storeDecryptedDataKey;
  }
}
