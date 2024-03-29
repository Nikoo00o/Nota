import 'package:app/core/config/app_config.dart';
import 'package:app/core/constants/routes.dart';
import 'package:app/domain/entities/client_account.dart';
import 'package:app/domain/repositories/account_repository.dart';
import 'package:app/domain/repositories/app_settings_repository.dart';
import 'package:app/domain/repositories/note_structure_repository.dart';
import 'package:app/presentation/main/dialog_overlay/dialog_overlay_bloc.dart';
import 'package:app/services/dialog_service.dart';
import 'package:app/services/navigation_service.dart';
import 'package:shared/core/constants/error_codes.dart';
import 'package:shared/core/exceptions/exceptions.dart';
import 'package:shared/core/utils/logger/logger.dart';
import 'package:shared/domain/usecases/usecase.dart';

/// This logs the user out of the app and clears the keys and sets the account to null, but keeps the encrypted note data
/// for later use and caches the note info for the account! After this, a remote login is needed!
///
/// Important: because this resets the account, references to the old should be updated afterwards, so they are not used
/// anymore!!! This also calls [AppSettingsRepository.resetAccountBoundSettings]
///
/// This can throw a [ClientException] with [ErrorCodes.CLIENT_NO_ACCOUNT].
///
/// This can automatically navigate to the login page depending on the [LogoutOfAccountParams].
class LogoutOfAccount extends UseCase<void, LogoutOfAccountParams> {
  final AccountRepository accountRepository;
  final AppSettingsRepository appSettingsRepository;
  final NoteStructureRepository noteStructureRepository;
  final NavigationService navigationService;
  final DialogService dialogService;
  final AppConfig appConfig;

  const LogoutOfAccount({
    required this.accountRepository,
    required this.appSettingsRepository,
    required this.noteStructureRepository,
    required this.navigationService,
    required this.appConfig,
    required this.dialogService,
  });

  @override
  Future<void> execute(LogoutOfAccountParams params) async {
    final ClientAccount account = await accountRepository.getAccountAndThrowIfNull();

    // cache note info list for the account and also clear the note info list of the account
    if (account.noteInfoList.isNotEmpty) {
      Logger.verbose("Storing the notes\n${account.noteInfoList}\nfor later use for the account ${account.username}");
      await accountRepository.saveNotesForOldAccount(account.username, account.noteInfoList);
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

    // clear the note structure cache
    await noteStructureRepository.clearStructureCache();

    // reset local app settings that are account bound
    await appSettingsRepository.resetAccountBoundSettings();

    Logger.info("Logged out of the account ${account.username}");
    dialogService.showInfoSnackBar(const ShowInfoSnackBar(textKey: "dialog.logged.out"));

    if (params.navigateToLoginPage) {
      navigationService.navigateTo(Routes.login);
    }
  }
}

class LogoutOfAccountParams {
  final bool navigateToLoginPage;

  const LogoutOfAccountParams({required this.navigateToLoginPage});
}
