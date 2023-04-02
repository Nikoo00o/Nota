import 'package:app/data/datasources/remote_account_data_source.dart';
import 'package:app/domain/entities/client_account.dart';
import 'package:app/domain/usecases/account/inner/fetch_current_session_token.dart';
import 'package:shared/core/constants/error_codes.dart';
import 'package:shared/core/exceptions/exceptions.dart';
import 'package:shared/domain/entities/note_info.dart';

/// Most of the Requests also directly modify the cached account!
abstract class AccountRepository {
  const AccountRepository();

  /// Returns the current account either from the cache, or the storage.
  /// This can return null if no account is stored.
  ///
  /// The [ClientAccount] can be modified for the other functions!
  ///
  /// If [forceLoad] is true, the cached account will be replaced and this might clear the decrypted data key depending on
  /// the saved bool!!!
  Future<ClientAccount?> getAccount({bool forceLoad = false});

  /// Returns the [getAccount] if its not null, or otherwise throws a [ClientException] with [ErrorCodes.CLIENT_NO_ACCOUNT]
  Future<ClientAccount> getAccountAndThrowIfNull();

  /// Saves the [account] to the storage and also overwrites the cache.
  /// This should be used after each update to the account if the change should be persisted!
  Future<void> saveAccount(ClientAccount? account);

  /// This will use the currently cached account and create it on the server.
  /// This can throw the exceptions of [RemoteAccountDataSource.createAccountRequest]
  /// And also a [ClientException] with [ErrorCodes.CLIENT_NO_ACCOUNT]
  Future<void> createNewAccount();

  /// Tries to login to the current cached account.
  /// This might update the session token of the cached account and returns it.
  /// This can throw the exceptions of [RemoteAccountDataSource.loginRequest]
  /// And also a [ClientException] with [ErrorCodes.CLIENT_NO_ACCOUNT]
  Future<ClientAccount> login();

  /// The currently cached account must be logged in before calling this.
  /// This will update the server side and also invalidate all session tokens.
  /// It also updates the session token of the cached account and returns it.
  /// This can throw the exceptions of [RemoteAccountDataSource.changePasswordRequest]
  /// And also a [ClientException] with [ErrorCodes.CLIENT_NO_ACCOUNT]
  ///
  /// The params [newPasswordHash] and [newEncryptedDataKey] are needed, because the own old keys of the account are used
  /// for the login if the session token was no longer valid of [FetchCurrentSessionToken].
  /// The keys of the account will also be updated!
  Future<ClientAccount> updatePasswordOnServer({required String newPasswordHash, required String newEncryptedDataKey});

  /// Returns the old notes from the account, or null if none were stored
  Future<List<NoteInfo>?> getOldNotesForAccount(String username);

  /// Saves the old notes for the account, so that they can be reused
  Future<void> saveNotesForOldAccount(String username, List<NoteInfo> notes);
}
