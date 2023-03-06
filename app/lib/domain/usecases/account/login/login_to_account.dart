import 'dart:convert';
import 'package:app/core/config/app_config.dart';
import 'package:app/core/enums/required_login_status.dart';
import 'package:app/core/utils/security_utils_extension.dart';
import 'package:app/domain/entities/client_account.dart';
import 'package:app/domain/repositories/account_repository.dart';
import 'package:app/domain/usecases/account/login/get_required_login_status.dart';
import 'package:shared/core/constants/error_codes.dart';
import 'package:shared/core/exceptions/exceptions.dart';
import 'package:shared/core/utils/logger/logger.dart';
import 'package:shared/domain/entities/note_info.dart';
import 'package:shared/domain/usecases/usecase.dart';

/// This logs the user into the app and decrypts the [ClientAccount.decryptedDataKey] and stores it in memory, or also in
/// the storage if [ClientAccount.storeDecryptedDataKey] is set.
///
/// The login can either be only local inside of the app, or remote to the server depending on if the [LoginToAccountParams]
/// are [LoginToAccountParamsRemote], or [LoginToAccountParamsLocal].
/// First call [GetRequiredLoginStatus] to determine the correct login status!
///
/// A login with [LoginToAccountParamsRemote] can throw the exceptions of [AccountRepository.login] and already updates
/// the session token and encrypted data key of the client.
///
/// A login with [LoginToAccountParamsLocal] needs a stored account and can throw a [ClientException] with
/// [ErrorCodes.ACCOUNT_WRONG_PASSWORD], or [ErrorCodes.CLIENT_NO_ACCOUNT] if the wrong [LoginToAccountParams] are used,
/// or if no account is stored.
///
///
/// Without the [LoginToAccountParamsLocal], offline editing would not be possible!
///
/// This also restores old note info lists stored on the device if multiple accounts are used!
///
/// Input validation of the params is done by the bloc!
class LoginToAccount extends UseCase<void, LoginToAccountParams> {
  final AccountRepository accountRepository;
  final AppConfig appConfig;
  final GetRequiredLoginStatus getRequiredLoginStatus;

  const LoginToAccount({required this.accountRepository, required this.appConfig, required this.getRequiredLoginStatus});

  @override
  Future<void> execute(LoginToAccountParams params) async {
    // get the new password hash for comparison and the new user key for decrypting the encrypted data key
    final String passwordHash = await SecurityUtilsExtension.hashStringSecure(params.password, appConfig.passwordHashSalt);
    final String userKey = await SecurityUtilsExtension.hashStringSecure(params.password, appConfig.userKeySalt);

    // get the correct account depending on the params. throws error if [params] is not one of the sub classes. also
    // creates the account if not already exists. also sets username and password hash to params
    ClientAccount account = await _getMatchingAccount(params, passwordHash);

    final RequiredLoginStatus loginStatus = await getRequiredLoginStatus(const NoParams());
    // login, or compare password hash
    if (params is LoginToAccountParamsRemote) {
      if (loginStatus != RequiredLoginStatus.REMOTE) {
        throw const ClientException(message: ErrorCodes.CLIENT_NO_ACCOUNT);
      }
      account = await accountRepository.login(); //login and update the account (updates session token and enc data key)
    } else if (params is LoginToAccountParamsLocal) {
      if (loginStatus != RequiredLoginStatus.LOCAL) {
        throw const ClientException(message: ErrorCodes.CLIENT_NO_ACCOUNT);
      }
      if (account.passwordHash != passwordHash) {
        throw const ClientException(message: ErrorCodes.ACCOUNT_WRONG_PASSWORD);
      }
    }

    // decrypt the data key and cache it
    account.decryptedDataKey = await SecurityUtilsExtension.decryptBytesAsync(
      base64Decode(account.encryptedDataKey),
      base64Decode(userKey),
    );

    // update the accounts login status
    account.needsServerSideLogin = false;

    if (params is LoginToAccountParamsRemote) {
      await _tryToReuseNotes(account); // see if the account had some notes cached that should be used
    }

    // save the account (and if the [ClientAccount.storeDecryptedDataKey] is set, then also the decrypted data key)
    await accountRepository.saveAccount(account);

    Logger.info("Logged in ${params.runtimeType} to the account: $account");
  }

  Future<void> _tryToReuseNotes(ClientAccount account) async {
    final List<NoteInfo>? oldNotes = await accountRepository.getOldNotesForAccount(account.userName);
    if (oldNotes != null) {
      account.noteInfoList = oldNotes;
      Logger.verbose("Loaded previous notes\n$oldNotes\nfor the new account ${account.userName}");
    }
  }

  /// For remote login, the username and [passwordHash] will be set to the account.
  /// A newly created account for remote login will also be stored locally.
  Future<ClientAccount> _getMatchingAccount(LoginToAccountParams params, String passwordHash) async {
    if (params is LoginToAccountParamsRemote) {
      ClientAccount? account = await accountRepository.getAccount();
      if (account == null) {
        Logger.warn("There was no account stored before the login");
        account = ClientAccount.defaultValues(userName: params.username, passwordHash: passwordHash);
        await accountRepository.saveAccount(account);
      } else {
        account.userName = params.username;
        account.passwordHash = passwordHash;
      }

      return account;
    } else if (params is LoginToAccountParamsLocal) {
      return accountRepository.getAccountAndThrowIfNull();
    }
    throw UnimplementedError();
  }
}

abstract class LoginToAccountParams {
  /// This is the plain text password and no hash, etc!
  final String password;

  const LoginToAccountParams({required this.password});
}

class LoginToAccountParamsRemote extends LoginToAccountParams {
  /// The username which is needed for a login request to the server
  final String username;

  const LoginToAccountParamsRemote({required super.password, required this.username});
}

class LoginToAccountParamsLocal extends LoginToAccountParams {
  const LoginToAccountParamsLocal({required super.password});
}
