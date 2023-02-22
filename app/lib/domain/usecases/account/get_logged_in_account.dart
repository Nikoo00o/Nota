import 'package:app/domain/entities/client_account.dart';
import 'package:app/domain/repositories/account_repository.dart';
import 'package:app/domain/usecases/account/save_account.dart';
import 'package:shared/core/constants/error_codes.dart';
import 'package:shared/core/exceptions/exceptions.dart';
import 'package:shared/domain/usecases/usecase.dart';

/// This returns the current logged in account (as a reference), or throws an exception if there is no cached account, or
/// if the keys are not available.
/// 
/// It can be used in other use cases, so that they don't have to use the account repository themselves if they only want
/// to read data from the account!
///
/// If the members of the account are changed, these changes should be saved to storage afterwards by calling [SaveAccount]!
///
/// This can throw a [ClientException] with [ErrorCodes.CLIENT_NO_ACCOUNT] if there is no stored account.
///
/// This can also throw a [ServerException] if another device changed the password before, or a [ClientException] or if the
/// decrypted data key is not available. Both will have the error code [ErrorCodes.ACCOUNT_WRONG_PASSWORD].
///
/// This has to be called every time an account is logged out and logged in again to update the reference!
class GetLoggedInAccount extends UseCase<ClientAccount, NoParams> {
  final AccountRepository accountRepository;

  const GetLoggedInAccount({required this.accountRepository});

  @override
  Future<ClientAccount> execute(NoParams params) async {
    final ClientAccount account = await accountRepository.getAccountAndThrowIfNull();
    if (account.isLoggedIn == false) {
      throw const ClientException(message: ErrorCodes.ACCOUNT_WRONG_PASSWORD); // data key is not available
    }
    return account;
  }
}
