import 'dart:io';
import 'package:server/core/config/server_config.dart';
import 'package:server/data/datasources/account_data_source.dart.dart';
import 'package:server/data/models/server_account_model.dart';
import 'package:server/domain/entities/network/rest_callback_params.dart';
import 'package:server/domain/entities/network/rest_callback_result.dart';
import 'package:server/domain/entities/server_account.dart';
import 'package:shared/core/constants/endpoints.dart';
import 'package:shared/core/constants/error_codes.dart';
import 'package:shared/core/utils/logger/logger.dart';
import 'package:shared/data/dtos/account/account_change_password_request.dart';
import 'package:shared/data/dtos/account/account_change_password_response.dart';
import 'package:shared/data/dtos/account/account_login_request.dart.dart';
import 'package:shared/data/dtos/account/account_login_response.dart';
import 'package:shared/data/dtos/account/create_account_request.dart';
import 'package:shared/data/models/session_token_model.dart';
import 'package:shared/domain/entities/note_info.dart';
import 'package:shared/domain/entities/session_token.dart';
import 'package:synchronized/synchronized.dart';

/// Manages and synchronizes the account operations on the server by using the [AccountDataSource].
///
/// No Other Repository, or DataSource should access the accounts from the [AccountDataSource] directly!!!
///
/// The attached account will always be provided in the http callbacks and otherwise this repository also has helper
/// methods to get other accounts!
class AccountRepository {
  final AccountDataSource accountDataSource;
  final ServerConfig serverConfig;

  /// Used to synchronize all methods that access the account data so that they are executed one after the other and not
  /// at the same time! (even tho this dart server runs on a single thread, the async methods could still be executed at
  /// the same time with a different order of the inner calls of the methods!)
  final Lock _lock = Lock();

  AccountRepository({required this.accountDataSource, required this.serverConfig});

  /// Returns cached, or stored account and also updates the cache.
  ///
  /// Also makes sure that the base64 encoded session token is not already contained in the cached accounts.
  Future<ServerAccount?> getAccountByUsername(String username) async {
    return _lock.synchronized(() async => accountDataSource.getAccountByUsername(username));
  }

  /// Should return a matching account if the session token is valid and otherwise null.
  ///
  /// Will also remove no longer valid session tokens and also add loaded accounts to the cache.
  ///
  /// The authenticated account can also be accessed from the [RestCallbackParams] in http callbacks that use [Endpoints]
  /// which need the session token!
  /// If an account would be null for one of those callbacks, the callbacks would return an error automatically.
  Future<ServerAccount?> getAccountBySessionToken(String sessionToken) async {
    return _lock.synchronized(() async => accountDataSource.getAccountBySessionToken(sessionToken));
  }

  /// Updates a stored and cached account with the new [account] parameter.
  ///
  /// Is used for when the accounts note list is modified in the note repository, etc
  Future<void> storeAccount(ServerAccount account) async {
    await _lock.synchronized(() async => accountDataSource.storeAccount(account));
  }

  /// Creates a new random session token that is valid for [ServerConfig.sessionTokenMaxLifetime] from now on.
  ///
  /// Also makes sure that the base64 encoded session token is not already contained in the cached accounts
  Future<SessionToken> createNewSessionToken() async {
    return _lock.synchronized(accountDataSource.createNewSessionToken);
  }

  /// resets all sessions for all accounts. modifies the local stored accounts and clears the cached accounts.
  ///
  /// can take a bit of time
  Future<void> resetAllSessionTokens() async {
    await _lock.synchronized(accountDataSource.resetAllSessionTokens);
  }

  /// Removes the cached accounts which no longer have a valid session token and also update THOSE accounts in the local
  /// storage
  Future<void> clearOldSessions() async {
    await _lock.synchronized(accountDataSource.clearOldSessions);
  }

  /// Should return a matching account if the session token is valid and otherwise null.
  ///
  /// The returned account will be provided to the http request callbacks to authenticate the user.
  ///
  /// The authenticated account can also be accessed from the [RestCallbackParams] in callbacks that use [Endpoints] which
  /// need the session token!
  /// If an account would be null for one of those callbacks, the callbacks would return an error automatically.
  ///
  /// Will also remove no longer valid session tokens and also add loaded accounts to the cache.
  Future<ServerAccount?> handleAuthenticateSessionToken(String sessionToken) async {
    return _lock.synchronized(() async => accountDataSource.getAccountBySessionToken(sessionToken));
  }

  /// Returns http status code 401 if the createAccountToken was invalid.
  /// Returns [ErrorCodes.SERVER_ACCOUNT_ALREADY_EXISTS] if the username already exists.
  /// Returns [ErrorCodes.SERVER_INVALID_REQUEST_VALUES] if the request parameter are empty.
  ///
  /// Creates a new account on the server and returns [HttpStatus.ok]
  Future<RestCallbackResult> handleCreateAccountRequest(RestCallbackParams params) async {
    return _lock.synchronized(() async {
      final CreateAccountRequest request = CreateAccountRequest.fromJson(params.jsonBody!);
      if (request.username.isEmpty || request.passwordHash.isEmpty || request.encryptedDataKey.isEmpty) {
        Logger.error("Error creating account, because the request is empty: ${request.username}");
        return RestCallbackResult.withErrorCode(ErrorCodes.SERVER_INVALID_REQUEST_VALUES);
      }

      if (request.createAccountToken != serverConfig.createAccountToken) {
        Logger.error("Error creating account, because the account token is invalid: ${request.username}");
        return RestCallbackResult(statusCode: HttpStatus.unauthorized);
      }

      final ServerAccountModel? oldAccount = await accountDataSource.getAccountByUsername(request.username);
      if (oldAccount != null) {
        Logger.error("Error creating account, because it already exists: ${request.username}");
        return RestCallbackResult.withErrorCode(ErrorCodes.SERVER_ACCOUNT_ALREADY_EXISTS);
      }

      await accountDataSource.storeAccount(ServerAccountModel(
        username: request.username,
        passwordHash: request.passwordHash,
        sessionToken: null,
        noteInfoList: const <NoteInfo>[],
        encryptedDataKey: request.encryptedDataKey,
      ));
      Logger.info("Created new Account: ${request.username}");
      return RestCallbackResult(statusCode: HttpStatus.ok);
    });
  }

  /// Returns [ErrorCodes.SERVER_UNKNOWN_ACCOUNT] if the username was not found.
  /// Returns [ErrorCodes.ACCOUNT_WRONG_PASSWORD] if the password hash was invalid.
  /// Returns [ErrorCodes.SERVER_INVALID_REQUEST_VALUES] if the request parameter are empty.
  Future<RestCallbackResult> handleLoginToAccountRequest(RestCallbackParams params) async {
    return _lock.synchronized(() async {
      final AccountLoginRequest request = AccountLoginRequest.fromJson(params.jsonBody!);
      if (request.username.isEmpty || request.passwordHash.isEmpty) {
        Logger.error("Error logging in to account, because the request is empty: ${request.username}");
        return RestCallbackResult.withErrorCode(ErrorCodes.SERVER_INVALID_REQUEST_VALUES);
      }

      if (request.createAccountToken != serverConfig.createAccountToken) {
        Logger.error("Error logging in to account, because the account token is invalid: ${request.username}");
        return RestCallbackResult(statusCode: HttpStatus.unauthorized);
      }

      ServerAccountModel? account = await accountDataSource.getAccountByUsername(request.username); // get account

      if (account == null) {
        Logger.error("Error logging in to account, because the username was not found: ${request.username}");
        return RestCallbackResult.withErrorCode(ErrorCodes.SERVER_UNKNOWN_ACCOUNT);
      } else if (account.passwordHash != request.passwordHash) {
        Logger.error("Error logging in to account, because the password was incorrect: ${request.username}");
        return RestCallbackResult.withErrorCode(ErrorCodes.ACCOUNT_WRONG_PASSWORD);
      }

      account = await accountDataSource.refreshSessionToken(account, forceRegenerate: false); // make sure session token is
      // updated

      final AccountLoginResponse response = AccountLoginResponse(
        sessionToken: SessionTokenModel.fromSessionToken(account.sessionToken!),
        encryptedDataKey: account.encryptedDataKey,
      );

      Logger.info("Logged into account: ${request.username} with the session token: ${account.sessionToken}");
      return RestCallbackResult.withResponse(response);
    });
  }

  /// Returns [ErrorCodes.SERVER_INVALID_REQUEST_VALUES] if the request parameter are empty.
  Future<RestCallbackResult> handleChangeAccountPasswordRequest(RestCallbackParams params) async {
    return _lock.synchronized(() async {
      // the attached account will always be a server account
      ServerAccountModel account = ServerAccountModel.fromServerAccount(params.authenticatedAccount as ServerAccount);

      final AccountChangePasswordRequest request = AccountChangePasswordRequest.fromJson(params.jsonBody!);
      if (request.newPasswordHash.isEmpty || request.newEncryptedDataKey.isEmpty) {
        Logger.error("Error changing password for account, because the request is empty: ${account.username}");
        return RestCallbackResult.withErrorCode(ErrorCodes.SERVER_INVALID_REQUEST_VALUES);
      }
      
      account.passwordHash = request.newPasswordHash;
      account.encryptedDataKey = request.newEncryptedDataKey;
      account = await accountDataSource.refreshSessionToken(account, forceRegenerate: true); // completely remove the old
      // token with no redirect

      final AccountChangePasswordResponse response = AccountChangePasswordResponse(
        sessionToken: SessionTokenModel.fromSessionToken(account.sessionToken!),
      );
      Logger.info("Changed the password for the account ${account.username}");
      return RestCallbackResult.withResponse(response);
    });
  }
}
