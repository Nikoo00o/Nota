import 'dart:convert';
import 'package:app/core/config/app_config.dart';
import 'package:app/core/utils/security_utils_extension.dart';
import 'package:app/domain/entities/client_account.dart';
import 'package:app/domain/repositories/account_repository.dart';
import 'package:app/domain/usecases/account/login/get_required_login_status.dart';
import 'package:shared/core/constants/error_codes.dart';
import 'package:shared/core/exceptions/exceptions.dart';
import 'package:shared/core/utils/logger/logger.dart';
import 'package:shared/domain/usecases/usecase.dart';

/// This logs the user into the app and decrypts the [ClientAccount.decryptedDataKey] and stores it in memory, or also in
/// the storage if [ClientAccount.storeDecryptedDataKey] is set.
///
/// The login can either be only local inside of the app, or remote to the server depending on if the [LoginParams]
/// are [RemoteLoginParams], or [LocalLoginParams].
/// First call [GetRequiredLoginStatus] to determine the correct login status!
///
/// A login with [RemoteLoginParams] can throw the exceptions of [AccountRepository.login] and already updates the session
/// token and encrypted data key of the client.
///
/// A login with [LocalLoginParams] needs a stored account and can throw a [ClientException] with
/// [ErrorCodes.ACCOUNT_WRONG_PASSWORD], or [ErrorCodes.CLIENT_NO_ACCOUNT].
///
///
/// Without the [LocalLoginParams], offline editing would not be possible!
class LoginToAccount extends UseCase<void, LoginParams> {
  final AccountRepository accountRepository;
  final AppConfig appConfig;

  const LoginToAccount({required this.accountRepository, required this.appConfig});

  @override
  Future<void> execute(LoginParams params) async {
    // get the new password hash for comparison and the new user key for decrypting the encrypted data key
    final String passwordHash = await SecurityUtilsExtension.hashStringSecure(params.password, appConfig.passwordHashSalt);
    final String userKey = await SecurityUtilsExtension.hashStringSecure(params.password, appConfig.userKeySalt);

    // get the correct account depending on the params
    ClientAccount account = await _getMatchingAccount(params, passwordHash);

    // login, or compare password hash
    if (params is RemoteLoginParams) {
      account = await accountRepository.login(); //login and update the account (updates session token and enc data key)
    } else if (params is LocalLoginParams) {
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

    // save the account (and if the [ClientAccount.storeDecryptedDataKey] is set, then also the decrypted data key)
    await accountRepository.saveAccount(account);

    Logger.info("Logged in ${params.runtimeType} to the account: $account");
  }

  /// For remote login, the username and [passwordHash] will be set to the account.
  /// A newly created account for remote login will also be stored locally.
  Future<ClientAccount> _getMatchingAccount(LoginParams params, String passwordHash) async {
    if (params is RemoteLoginParams) {
      ClientAccount? account = await accountRepository.getAccount();
      if (account == null) {
        Logger.debug("There was no account stored before");
        account = ClientAccount.defaultValues(userName: params.username, passwordHash: passwordHash);
        await accountRepository.saveAccount(account);
      } else {
        account.userName = params.username;
        account.passwordHash = passwordHash;
      }

      return account;
    } else if (params is LocalLoginParams) {
      return accountRepository.getAccountAndThrowIfNull();
    }
    throw UnimplementedError();
  }
}

abstract class LoginParams {
  /// This is the plain text password and no hash, etc!
  final String password;

  const LoginParams({required this.password});
}

class RemoteLoginParams extends LoginParams {
  /// The username which is needed for a login request to the server
  final String username;

  const RemoteLoginParams({required super.password, required this.username});
}

class LocalLoginParams extends LoginParams {
  const LocalLoginParams({required super.password});
}
