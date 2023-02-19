import 'dart:convert';
import 'dart:typed_data';

import 'package:app/core/config/app_config.dart';
import 'package:app/core/utils/security_utils_extension.dart';
import 'package:app/domain/entities/client_account.dart';
import 'package:app/domain/repositories/account_repository.dart';
import 'package:shared/core/config/shared_config.dart';
import 'package:shared/core/utils/logger/logger.dart';
import 'package:shared/core/utils/string_utils.dart';
import 'package:shared/domain/usecases/usecase.dart';

/// This creates a new account in the storage and on the server.
/// It can throw the exceptions of [AccountRepository.createNewAccount]
class CreateAccount extends UseCase<void, CreateAccountParams> {
  final AccountRepository accountRepository;
  final AppConfig appConfig;

  const CreateAccount({required this.accountRepository, required this.appConfig});

  @override
  Future<void> execute(CreateAccountParams params) async {
    // create the base64 encoded user keys
    final String passwordHash = await SecurityUtilsExtension.hashStringSecure(params.password, appConfig.passwordHashSalt);
    final String userKey = await SecurityUtilsExtension.hashStringSecure(params.password, appConfig.userKeySalt);

    // the plain data key is encrypted with the user key
    final Uint8List plainDataKeyBytes = StringUtils.getRandomBytes(SharedConfig.keyBytes);
    final Uint8List encryptedDataKeyBytes = await SecurityUtilsExtension.encryptBytesAsync(
      plainDataKeyBytes,
      base64Decode(userKey),
    );

    ClientAccount? account = await accountRepository.getAccount();

    // update the account with the new values, or create a new one
    if (account != null) {
      assert(account.isLoggedIn == false && account.needsServerSideLogin == true, "A stored account is always logged out");
      account.userName = params.username;
      account.passwordHash = passwordHash;
    } else {
      Logger.debug("There was no account stored before");
      account = ClientAccount.defaultValues(userName: params.username, passwordHash: passwordHash);
    }

    // set the encrypted data key base64 encoded
    account.encryptedDataKey = base64UrlEncode(encryptedDataKeyBytes);

    // save the account
    await accountRepository.saveAccount(account);

    // create the account on the server
    await accountRepository.createNewAccount();

    Logger.info("Created new account: $account");
  }
}

class CreateAccountParams {
  final String username;

  /// This is the plain text password and no hash, etc!
  final String password;

  const CreateAccountParams({required this.username, required this.password});
}
