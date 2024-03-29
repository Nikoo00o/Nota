import 'dart:convert';
import 'package:app/core/config/app_config.dart';
import 'package:app/core/enums/required_login_status.dart';
import 'package:app/core/utils/security_utils_extension.dart';
import 'package:app/domain/entities/client_account.dart';
import 'package:app/domain/repositories/account_repository.dart';
import 'package:app/domain/repositories/biometrics_repository.dart';
import 'package:app/domain/usecases/account/login/get_required_login_status.dart';
import 'package:app/domain/usecases/note_transfer/transfer_notes.dart';
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
/// This can also throw [ErrorCodes.INVALID_PARAMS] if the params are empty!
///
/// Without the [LoginToAccountParamsLocal], offline editing would not be possible!
///
/// This also restores old note info lists stored on the device if multiple accounts are used! Otherwise this will fetch
/// the notes from the server once. So this calls [TransferNotes] and can throw the exceptions of it!
///
/// Input validation of the params is done by the bloc!
///
/// This always returns true except for if [LoginToAccountParamsBiometric] is used and that fails!
class LoginToAccount extends UseCase<bool, LoginToAccountParams> {
  final AccountRepository accountRepository;
  final AppConfig appConfig;
  final GetRequiredLoginStatus getRequiredLoginStatus;
  final TransferNotes transferNotes;
  final BiometricsRepository biometricsRepository;

  const LoginToAccount({
    required this.accountRepository,
    required this.appConfig,
    required this.getRequiredLoginStatus,
    required this.transferNotes,
    required this.biometricsRepository,
  });

  @override
  Future<bool> execute(LoginToAccountParams params) async {
    // get the new password hash for comparison and the new user key for decrypting the encrypted data key
    final String passwordHash =
        await SecurityUtilsExtension.hashStringSecure(params.password, appConfig.passwordHashSalt);
    String userKey = await SecurityUtilsExtension.hashStringSecure(params.password, appConfig.userKeySalt);

    // get the correct account depending on the params. throws error if [params] is not one of the sub classes. also
    // creates the account if not already exists. also sets username and password hash to params
    ClientAccount account = await _getMatchingAccount(params, passwordHash);
    if (params is LoginToAccountParamsBiometric) {
      final (bool success, String newKey) = await biometricsRepository.authenticate();
      if (success) {
        userKey = newKey; // only override user key and the rest is the same
      } else {
        return false; // only case this returns false is if biometric login fails and password should be used instead!
      }
    } else {
      await _checkForErrors(params, account, passwordHash); // only check errors for non biometric login
    }

    try {
      if (params is LoginToAccountParamsRemote) {
        account = await accountRepository.login(); // login to server and update the account (updates session token
        // and enc data key)
      }

      // decrypt the data key and cache it
      account.decryptedDataKey = await SecurityUtilsExtension.decryptBytesAsync(
        base64Decode(account.encryptedDataKey),
        base64Decode(userKey),
      );

      // update the accounts login status
      account.needsServerSideLogin = false;

      if (params is LoginToAccountParamsRemote && params.reuseOldNotes) {
        await _tryToReuseNotes(account); // see if the account had some notes cached that should be used, or otherwise
        // get server notes
      }

      // save the account (and if the [ClientAccount.storeDecryptedDataKey] is set, then also the decrypted data key)
      await accountRepository.saveAccount(account);

      if (biometricsRepository.hasKey == false) {
        await biometricsRepository.cacheUserKey(userKey); // if biometrics are enabled, cache key on first login
      }

      Logger.info("Logged in ${params.runtimeType} to the account: $account");
    } catch (_) {
      await accountRepository.getAccount(forceLoad: true); // reload cached account on error
      rethrow;
    }
    return true;
  }

  Future<void> _checkForErrors(LoginToAccountParams params, ClientAccount account, String passwordHash) async {
    final RequiredLoginStatus loginStatus = await getRequiredLoginStatus(const NoParams());
    if (params.password.isEmpty) {
      Logger.error("password empty");
      throw const ClientException(message: ErrorCodes.INVALID_PARAMS);
    }
    if (params is LoginToAccountParamsRemote) {
      if (params.username.isEmpty) {
        Logger.error("username empty");
        throw const ClientException(message: ErrorCodes.INVALID_PARAMS);
      }
      if (loginStatus != RequiredLoginStatus.REMOTE) {
        Logger.error("required no remote login");
        throw const ClientException(message: ErrorCodes.CLIENT_NO_ACCOUNT);
      }
    } else if (params is LoginToAccountParamsLocal) {
      if (loginStatus != RequiredLoginStatus.LOCAL) {
        Logger.error("required no local login");
        throw const ClientException(message: ErrorCodes.CLIENT_NO_ACCOUNT);
      }
      if (account.passwordHash != passwordHash) {
        Logger.error("password hash wrong"); // compare entered password to stored password hash
        throw const ClientException(message: ErrorCodes.ACCOUNT_WRONG_PASSWORD);
      }
    }
  }

  Future<void> _tryToReuseNotes(ClientAccount account) async {
    final List<NoteInfo>? oldNotes = await accountRepository.getOldNotesForAccount(account.username);
    if (oldNotes != null && oldNotes.isNotEmpty) {
      Logger.verbose("Loaded previous notes\n$oldNotes\nfor the new account ${account.username}");
      try {
        await SecurityUtilsExtension.decryptStringAsync2(oldNotes.first.encFileName, account.decryptedDataKey!);
        account.noteInfoList = oldNotes;
        return; // dont load server notes if previous notes were loaded
      } catch (_) {
        Logger.warn("could not load previous notes for the account ${account.username}");
      }
    }
    Logger.verbose("Loading server notes the first time for ${account.username}");
    await transferNotes.call(const NoParams());
  }

  /// For remote login, the username and [passwordHash] will be set to the account.
  /// A newly created account for remote login will also be stored locally.
  Future<ClientAccount> _getMatchingAccount(LoginToAccountParams params, String passwordHash) async {
    if (params is LoginToAccountParamsRemote) {
      ClientAccount? account = await accountRepository.getAccount();
      if (account == null) {
        Logger.warn("There was no account stored before the login");
        account = ClientAccount.defaultValues(username: params.username, passwordHash: passwordHash);
        await accountRepository.saveAccount(account);
      } else {
        account.username = params.username;
        account.passwordHash = passwordHash;
      }
      return account;
    } else if (params is LoginToAccountParamsLocal || params is LoginToAccountParamsBiometric) {
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

  /// If old notes from previous locally stored accounts should be loaded, or if the notes of the server should already be
  /// fetched once
  final bool reuseOldNotes;

  const LoginToAccountParamsRemote({required super.password, required this.username, required this.reuseOldNotes});
}

class LoginToAccountParamsLocal extends LoginToAccountParams {
  const LoginToAccountParamsLocal({required super.password});
}

class LoginToAccountParamsBiometric extends LoginToAccountParams {
  const LoginToAccountParamsBiometric() : super(password: "");
}
