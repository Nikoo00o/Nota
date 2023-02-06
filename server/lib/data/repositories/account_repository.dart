import 'dart:io';
import 'package:server/data/datasources/account_data_source.dart.dart';
import 'package:server/domain/entities/server_account.dart';
import 'package:server/network/rest_callback.dart';
import 'package:shared/core/constants/endpoints.dart';
import 'package:shared/core/constants/error_codes.dart';
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

  /// Used to synchronize all methods that access the account data so that they are executed one after the other and not
  /// at the same time! (even tho this dart server runs on a single thread, the async methods could still be executed at
  /// the same time with a different order of the inner calls of the methods!)
  final Lock _lock = Lock();

  AccountRepository({required this.accountDataSource});

  /// Returns cached, or stored account and also updates the cache.
  ///
  /// Also makes sure that the base64 encoded session token is not already contained in the cached accounts.
  Future<ServerAccount?> getAccountByUserName(String userName) async {
    return _lock.synchronized(() async => accountDataSource.getAccountByUsername(userName));
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
  ///
  /// Creates a new account on the server and returns [HttpStatus.ok]
  Future<RestCallbackResult> handleCreateAccountRequest(RestCallbackParams params) async {
    return _lock.synchronized(() async => accountDataSource.handleCreateAccountRequest(params));
  }

  /// Returns [ErrorCodes.SERVER_UNKNOWN_ACCOUNT] if the username was not found.
  /// Returns [ErrorCodes.SERVER_ACCOUNT_WRONG_PASSWORD] if the password hash was invalid.
  Future<RestCallbackResult> handleLoginToAccountRequest(RestCallbackParams params) async {
    return _lock.synchronized(() async => accountDataSource.handleLoginToAccountRequest(params));
  }

  ///
  Future<RestCallbackResult> handleChangeAccountPasswordRequest(RestCallbackParams params) async {
    //todo: document comments
    return _lock.synchronized(() async => accountDataSource.handleChangeAccountPasswordRequest(params));
  }

  /// Creates a new random session token that is valid for [serverConfig.sessionTokenMaxLifetime] from now on.
  ///
  /// Also makes sure that the base64 encoded session token is not already contained in the cached accounts
  Future<SessionToken> createNewSessionToken() async {
    return _lock.synchronized(accountDataSource.createNewSessionToken);
  }

  /// resets all sessions for all accounts. modifies the local stored accounts and clears the cached accounts.
  ///
  /// can take a bit of time
  Future<void> resetAllSessionTokens() async {
    return _lock.synchronized(accountDataSource.resetAllSessionTokens);
  }

  /// Removes the cached accounts which no longer have a valid session token and also update THOSE accounts in the local
  /// storage
  Future<void> clearOldSessions() async {
    return _lock.synchronized(accountDataSource.clearOldSessions);
  }
}
