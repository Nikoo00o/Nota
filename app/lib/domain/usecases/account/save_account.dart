import 'package:app/domain/entities/client_account.dart';
import 'package:app/domain/repositories/account_repository.dart';
import 'package:app/domain/usecases/account/get_logged_in_account.dart';
import 'package:shared/core/constants/error_codes.dart';
import 'package:shared/core/exceptions/exceptions.dart';
import 'package:shared/domain/usecases/usecase.dart';

/// This saves the current cached account of the [AccountRepository] to the storage and it should be called after
/// modifying members of an account which was returned from [GetLoggedInAccount]!
///
/// This can throw a [ClientException] with [ErrorCodes.CLIENT_NO_ACCOUNT] if there is no cached account.
class SaveAccount extends UseCase<void, NoParams> {
  final AccountRepository accountRepository;

  const SaveAccount({required this.accountRepository});

  @override
  Future<void> execute(NoParams params) async {
    final ClientAccount account = await accountRepository.getAccountAndThrowIfNull();
    await accountRepository.saveAccount(account);
  }
}
