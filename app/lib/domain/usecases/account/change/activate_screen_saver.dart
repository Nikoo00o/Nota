import 'package:app/core/config/app_config.dart';
import 'package:app/core/constants/routes.dart';
import 'package:app/domain/entities/client_account.dart';
import 'package:app/domain/repositories/account_repository.dart';
import 'package:app/domain/usecases/account/change/logout_of_account.dart';
import 'package:app/services/navigation_service.dart';
import 'package:shared/core/constants/error_codes.dart';
import 'package:shared/core/exceptions/exceptions.dart';
import 'package:shared/core/utils/logger/logger.dart';
import 'package:shared/domain/usecases/usecase.dart';

/// This is similar to the [LogoutOfAccount] use case, but this one here only clears the accounts decrypted data key if
/// the [ClientAccount.storeDecryptedDataKey] is false and then it will also navigate to the login page.
///
/// So afterwards the account will need a new local login.
///
/// This will ignore any exceptions and just do nothing in that case.
///
/// It is called on reopening the app again from the background.
class ActivateScreenSaver extends UseCase<void, NoParams> {
  final AccountRepository accountRepository;
  final NavigationService navigationService;

  const ActivateScreenSaver({required this.accountRepository, required this.navigationService});

  @override
  Future<void> execute(NoParams params) async {
    // this use case is so simple and similar to the logout use case, that there will not be a test for it for now.
    final ClientAccount? account = await accountRepository.getAccount();
    if (account != null && account.storeDecryptedDataKey == false) {
      account.clearDecryptedDataKey();
      await accountRepository.saveAccount(account);
      Logger.info("Activated screen saver");
      navigationService.navigateTo(Routes.login);
    }
  }
}
