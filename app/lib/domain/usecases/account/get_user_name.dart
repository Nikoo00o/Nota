import 'package:app/domain/entities/client_account.dart';
import 'package:app/domain/repositories/account_repository.dart';
import 'package:shared/domain/usecases/usecase.dart';

/// This returns the username of a saved account and will not perform any checks.
///
/// If no account was stored, then the returned username will be null!
///
class GetUsername extends UseCase<String?, NoParams> {
  final AccountRepository accountRepository;

  const GetUsername({required this.accountRepository});

  @override
  Future<String?> execute(NoParams params) async {
    final ClientAccount? account = await accountRepository.getAccount();
    return account?.username;
  }
}
