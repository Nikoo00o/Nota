import 'dart:convert';
import 'dart:typed_data';

import 'package:app/core/config/app_config.dart';
import 'package:app/core/utils/security_utils_extension.dart';
import 'package:app/domain/entities/client_account.dart';
import 'package:app/domain/repositories/account_repository.dart';
import 'package:app/domain/repositories/biometrics_repository.dart';
import 'package:app/domain/usecases/account/get_logged_in_account.dart';
import 'package:shared/core/constants/error_codes.dart';
import 'package:shared/core/exceptions/exceptions.dart';
import 'package:shared/core/utils/logger/logger.dart';
import 'package:shared/domain/usecases/usecase.dart';

/// This changes the password of the account (password hash, user key and encrypted data key) and also refreshes the
/// session token and invalidates all old session tokens.
///
/// Important: other devices will now get a [ServerException] with [ErrorCodes.ACCOUNT_WRONG_PASSWORD] when trying to login.
///
/// This can throw the exceptions of [GetLoggedInAccount].
///
/// Otherwise it can also throw those of [AccountRepository.updatePasswordOnServer]
class ChangeAccountPassword extends UseCase<void, ChangePasswordParams> {
  final AccountRepository accountRepository;
  final AppConfig appConfig;
  final GetLoggedInAccount getLoggedInAccount;
  final BiometricsRepository biometricsRepository;

  const ChangeAccountPassword({
    required this.accountRepository,
    required this.appConfig,
    required this.getLoggedInAccount,
    required this.biometricsRepository,
  });

  @override
  Future<void> execute(ChangePasswordParams params) async {
    final ClientAccount account = await getLoggedInAccount.call(const NoParams());

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

    await biometricsRepository.cacheUserKey(newUserKey); // if biometrics are enabled, update cached key!

    Logger.info("Changed password of $account");
  }
}

class ChangePasswordParams {
  /// The new plain text password (not hash, etc)
  final String newPassword;

  const ChangePasswordParams({required this.newPassword});
}
