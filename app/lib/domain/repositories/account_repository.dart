import 'package:app/data/datasources/remote_account_data_source.dart';
import 'package:app/domain/entities/client_account.dart';
import 'package:shared/core/constants/error_codes.dart';
import 'package:shared/core/exceptions/exceptions.dart';

abstract class AccountRepository {
  const AccountRepository();

  /// Returns the current account either from the cache, or the storage.
  /// This can return null if no account is stored.
  ///
  /// The [ClientAccount] can be modified for the other functions!
  Future<ClientAccount?> getAccount();

  /// Returns the [getAccount] if its not null, or otherwise throws a [ClientException] with [ErrorCodes.CLIENT_NO_ACCOUNT]
  Future<ClientAccount> getAccountAndThrowIfNull();

  /// Saves the [account] to the storage and also overwrites the cache.
  Future<void> saveAccount(ClientAccount account);

  /// This will use the currently cached account and create it on the server.
  /// This can throw the exceptions of [RemoteAccountDataSource.createAccountRequest]
  /// And also a [ClientException] with [ErrorCodes.CLIENT_NO_ACCOUNT]
  Future<void> createNewAccount();

  /// Tries to login to the current cached account.
  /// This might update the session token of the cached account and returns it.
  /// This can throw the exceptions of [RemoteAccountDataSource.loginRequest]
  /// And also a [ClientException] with [ErrorCodes.CLIENT_NO_ACCOUNT]
  Future<ClientAccount> login();

  /// Should be called after changing the cached account's passwordHash and encryptedDataKey while the cached account is
  /// logged in.
  /// This will update the server side and also invalidate all session tokens.
  /// It also updates the session token of the cached account and returns it.
  /// This can throw the exceptions of [RemoteAccountDataSource.changePasswordRequest]
  /// And also a [ClientException] with [ErrorCodes.CLIENT_NO_ACCOUNT]
  Future<ClientAccount> updatePasswordOnServer();
}
