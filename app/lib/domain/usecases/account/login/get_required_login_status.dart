import 'package:app/core/enums/required_login_status.dart';
import 'package:app/domain/entities/client_account.dart';
import 'package:app/domain/repositories/account_repository.dart';
import 'package:shared/core/utils/logger/logger.dart';
import 'package:shared/domain/usecases/usecase.dart';

/// This returns how the login page should be displayed.
class GetRequiredLoginStatus extends UseCase<RequiredLoginStatus, NoParams> {
  final AccountRepository accountRepository;

  const GetRequiredLoginStatus({required this.accountRepository});

  @override
  Future<RequiredLoginStatus> execute(NoParams params) async {
    final ClientAccount? account = await accountRepository.getAccount();
    late final RequiredLoginStatus status;
    if (account?.needsServerSideLogin ?? true) {
      assert((account?.isLoggedIn ?? false) == false, "account is never logged in if it needs a server side login");
      status = RequiredLoginStatus.REMOTE;
    } else if (account?.isLoggedIn ?? false) {
      status = RequiredLoginStatus.NONE;
    } else {
      assert(account != null, "account is never null here");
      status = RequiredLoginStatus.LOCAL;
    }
    Logger.info("Got login status: $status");
    return status;
  }
}
