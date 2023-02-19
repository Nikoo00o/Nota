import 'dart:convert';
import 'dart:typed_data';

import 'package:app/core/config/app_config.dart';
import 'package:app/core/utils/security_utils_extension.dart';
import 'package:app/domain/entities/client_account.dart';
import 'package:app/domain/repositories/account_repository.dart';
import 'package:shared/core/constants/error_codes.dart';
import 'package:shared/core/exceptions/exceptions.dart';
import 'package:shared/core/utils/logger/logger.dart';
import 'package:shared/domain/usecases/usecase.dart';

/// This changes the password of the account (password hash, user key and encrypted data key) and also refreshes the
/// session token and invalidates all old session tokens.
///
/// Important: other devices will now get a [ServerException] with [ErrorCodes.ACCOUNT_WRONG_PASSWORD] when trying to login.
///
/// This can throw a [ClientException] with [ErrorCodes.CLIENT_NO_ACCOUNT].
///
/// This can also throw a [ServerException] if another device changed the password before, or a [ClientException] or if the
/// decrypted data key is not available. Both will have the error code [ErrorCodes.ACCOUNT_WRONG_PASSWORD].
///
/// Otherwise it can also throw those of [AccountRepository.updatePasswordOnServer]
class ChangeAccountPassword extends UseCase<void, ChangePasswordParams> {
  final AccountRepository accountRepository;
  final AppConfig appConfig;

  const ChangeAccountPassword({required this.accountRepository, required this.appConfig});

  @override
  Future<void> execute(ChangePasswordParams params) async {
    final ClientAccount account = await accountRepository.getAccountAndThrowIfNull();

    if (account.isLoggedIn == false) {
      throw const ClientException(message: ErrorCodes.ACCOUNT_WRONG_PASSWORD); // data key is not available
    }

    // create the new base64 encoded user keys
    final String newPasswordHash =
        await SecurityUtilsExtension.hashStringSecure(params.newPassword, appConfig.passwordHashSalt);
    final String newUserKey = await SecurityUtilsExtension.hashStringSecure(params.newPassword, appConfig.userKeySalt);

    // create the new encrypted data key bytes from the old plain data key bytes and the new user key
    final Uint8List newEncryptedDataKeyBytes = await SecurityUtilsExtension.encryptBytesAsync(
      account.decryptedDataKey!,
      base64Decode(newUserKey),
    );

    // change the password on the server and also update the keys of the account
    await accountRepository.updatePasswordOnServer(
      newEncryptedDataKey: base64UrlEncode(newEncryptedDataKeyBytes),
      newPasswordHash: newPasswordHash,
    );

    // save the account
    await accountRepository.saveAccount(account);
    Logger.info("Changed password of $account");
  }
}

class ChangePasswordParams {
  /// The new plain text password (not hash, etc)
  final String newPassword;

  const ChangePasswordParams({required this.newPassword});
}
