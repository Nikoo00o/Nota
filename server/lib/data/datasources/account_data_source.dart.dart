import 'dart:io';
import 'package:server/config/server_config.dart';
import 'package:server/data/datasources/local_data_source.dart';
import 'package:server/data/models/server_account_model.dart';
import 'package:server/domain/entities/server_account.dart';
import 'package:server/network/rest_callback.dart';
import 'package:shared/core/config/shared_config.dart';
import 'package:shared/core/constants/endpoints.dart';
import 'package:shared/core/constants/error_codes.dart';
import 'package:shared/core/utils/logger/logger.dart';
import 'package:shared/core/utils/nullable.dart';
import 'package:shared/core/utils/string_utils.dart';
import 'package:shared/data/dtos/account/account_login_request.dart.dart';
import 'package:shared/data/dtos/account/account_login_response.dart';
import 'package:shared/data/dtos/account/create_account_request.dart';
import 'package:shared/data/models/session_token_model.dart';
import 'package:shared/domain/entities/note_info.dart';
import 'package:shared/domain/entities/session_token.dart';

/// Manages the account operations on the server
class AccountDataSource {
  final ServerConfig serverConfig;
  final LocalDataSource localDataSource;

  /// A local cache of the server accounts loaded in memory which can be accessed with the session token.
  /// This may not contain all server accounts!
  final Map<String, ServerAccountModel> _cachedSessionTokenAccounts = <String, ServerAccountModel>{};

  AccountDataSource({required this.serverConfig, required this.localDataSource});

  /// Should return a matching account if the session token is valid and otherwise null.
  ///
  /// The returned account will be used in the http request callbacks to authenticate the user.
  ///
  /// The authenticated account can also be accessed from the [RestCallbackParams] in callbacks that use [Endpoints] which
  /// need the session token!
  /// If an account would be null for one of those callbacks, the callbacks would return an error automatically.
  ///
  /// Will also remove no longer valid session tokens and also add loaded accounts to the cache.
  Future<ServerAccount?> authenticateSessionToken(String sessionToken) async {
    if (sessionToken.isEmpty) {
      return null;
    }
    ServerAccountModel? account;
    bool wasLoadedFromStorage = false;

    if (_cachedSessionTokenAccounts.containsKey(sessionToken)) {
      // check cached accounts
      account = _cachedSessionTokenAccounts[sessionToken]!;
    } else {
      // check stored accounts
      for (final String userName in await localDataSource.getAllAccountUserNames()) {
        final ServerAccountModel? tempAccount = await localDataSource.loadAccount(userName);
        if (tempAccount?.containsSessionToken(sessionToken) ?? false) {
          account = tempAccount;
          wasLoadedFromStorage = true;
          break;
        }
      }
    }

    if (account != null) {
      // if an account was found (cached, or stored)
      final bool isSessionTokenStillValid = account.isSessionTokenValidFor(const Duration(milliseconds: 1));
      final bool isSessionTokenEqual = account.sessionToken?.token == sessionToken;
      if (isSessionTokenStillValid == false || isSessionTokenEqual == false) {
        // check if the session token is still valid and if it really matches and otherwise remove the account from the
        // cache and update it in the local storage to not have a session token anymore.
        _cachedSessionTokenAccounts.remove(sessionToken);
        account = account.copyWith(newSessionToken: const Nullable<SessionToken>(null));
        await localDataSource.saveAccount(account);
      } else if (wasLoadedFromStorage) {
        // but if the account contains a valid session token and was loaded from storage, then cache it
        _cachedSessionTokenAccounts[sessionToken] = account;
      }
    }

    return account;
  }

  /// Returns http status code 401 if the createAccountToken was invalid.
  /// Returns [ErrorCodes.SERVER_ACCOUNT_ALREADY_EXISTS] if the username already exists.
  ///
  /// Creates a new account on the server and returns [HttpStatus.ok]
  Future<RestCallbackResult> handleCreateAccountRequest(RestCallbackParams params) async {
    final CreateAccountRequest request = CreateAccountRequest.fromJson(params.data!);
    if (request.userName.isEmpty || request.passwordHash.isEmpty || request.encryptedDataKey.isEmpty) {
      Logger.error("Error creating account, because the request is empty: ${request.userName}");
      return RestCallbackResult.withErrorCode(ErrorCodes.SERVER_EMPTY_REQUEST_VALUES);
    }

    if (request.createAccountToken != serverConfig.createAccountToken) {
      Logger.error("Error creating account, because the account token is invalid: ${request.userName}");
      return RestCallbackResult(statusCode: HttpStatus.unauthorized);
    }

    final ServerAccountModel? oldAccount = await localDataSource.loadAccount(request.userName);
    if (oldAccount != null) {
      Logger.error("Error creating account, because it already exists: ${request.userName}");
      return RestCallbackResult.withErrorCode(ErrorCodes.SERVER_ACCOUNT_ALREADY_EXISTS);
    }

    await localDataSource.saveAccount(ServerAccountModel(
      userName: request.userName,
      passwordHash: request.passwordHash,
      sessionToken: null,
      noteInfoList: const <NoteInfo>[],
      encryptedDataKey: request.encryptedDataKey,
    ));
    Logger.info("Created new Account: ${request.userName}");
    return RestCallbackResult(statusCode: HttpStatus.ok);
  }

  /// Returns [ErrorCodes.SERVER_UNKNOWN_ACCOUNT] if the username was not found.
  /// Returns [ErrorCodes.SERVER_ACCOUNT_WRONG_PASSWORD] if the password hash was invalid.
  Future<RestCallbackResult> handleLoginToAccountRequest(RestCallbackParams params) async {
    final AccountLoginRequest request = AccountLoginRequest.fromJson(params.data!);
    if (request.userName.isEmpty || request.passwordHash.isEmpty) {
      Logger.error("Error logging in to account, because the request is empty: ${request.userName}");
      return RestCallbackResult.withErrorCode(ErrorCodes.SERVER_EMPTY_REQUEST_VALUES);
    }

    ServerAccountModel? account = await _loadAccountByUserName(request.userName); // get account

    if (account == null) {
      Logger.error("Error logging in to account, because the userName was not found: ${request.userName}");
      return RestCallbackResult.withErrorCode(ErrorCodes.SERVER_UNKNOWN_ACCOUNT);
    } else if (account.passwordHash != request.passwordHash) {
      Logger.error("Error logging in to account, because the password was incorrect: ${request.userName}");
      return RestCallbackResult.withErrorCode(ErrorCodes.SERVER_ACCOUNT_WRONG_PASSWORD);
    }

    account = await _refreshSessionToken(account); // make sure session token is updated

    final AccountLoginResponse response = AccountLoginResponse(
      sessionToken: SessionTokenModel.fromSessionToken(account.sessionToken!),
      encryptedDataKey: account.encryptedDataKey,
    );

    Logger.info("Logged into account: ${request.userName} with the session token: ${account.sessionToken}");
    return RestCallbackResult.withResponse(response);
  }

  Future<RestCallbackResult> handleChangeAccountPasswordRequest(RestCallbackParams params) async {
    //todo: implement
    throw UnimplementedError();
  }

  /// Creates a new random session token that is valid for [serverConfig.sessionTokenMaxLifetime] from now on.
  ///
  /// Also makes sure that the base64 encoded session token is not already contained in the cached accounts
  SessionTokenModel createNewSessionToken() {
    late String sessionToken;
    do {
      sessionToken = getRandomBytesAsBase64String(SharedConfig.keyBytes);
    } while (_cachedSessionTokenAccounts.containsKey(sessionToken)); // chance is almost non existent, but create new
    // session tokens as long as it is already contained in the cached accounts

    return SessionTokenModel(
      token: sessionToken,
      validTo: DateTime.now().add(serverConfig.sessionTokenMaxLifetime),
    );
  }

  /// resets all sessions for all accounts. modifies the local stored accounts and clears the cached accounts.
  ///
  /// can take a bit of time
  Future<void> resetAllSessionTokens() async {
    _cachedSessionTokenAccounts.clear();
    final List<String> userNames = await localDataSource.getAllAccountUserNames();
    for (final String userName in userNames) {
      ServerAccountModel? account = await localDataSource.loadAccount(userName);
      if (account != null && account.sessionToken != null) {
        account = account.copyWith(newSessionToken: const Nullable<SessionToken>(null));
        await localDataSource.saveAccount(account);
      }
    }
  }

  /// Returns cached, or stored account.
  ///
  /// Also makes sure that the base64 encoded session token is not already contained in the cached accounts.
  Future<ServerAccountModel?> _loadAccountByUserName(String userName) async {
    for (final ServerAccountModel account in _cachedSessionTokenAccounts.values) {
      if (account.userName == userName) {
        return account; // return cached account
      }
    }
    final ServerAccountModel? account = await localDataSource.loadAccount(userName); // return stored account
    if (account != null && account.isSessionTokenValidFor(const Duration(milliseconds: 1))) {
      final String sessionToken = account.sessionToken!.token;
      if (_cachedSessionTokenAccounts.containsKey(sessionToken)) {
        return account.copyWith(newSessionToken: const Nullable<SessionToken>(null)); // chance is almost non existent,
        // but if the session token is already contained in a different account, then make sure this account will have its
        // own deleted when loading it from storage
      } else {
        _cachedSessionTokenAccounts[sessionToken] = account;
      }
    }
    return account;
  }

  /// refreshes the session token with a new lifetime if its life time is about to expire in the next few minutes.
  /// also updates the stored and cached account if the session token was updated!
  Future<ServerAccountModel> _refreshSessionToken(ServerAccountModel oldAccount) async {
    ServerAccountModel newAccount = oldAccount;
    if (oldAccount.isSessionTokenValidFor(serverConfig.sessionTokenRefreshAfterRemainingTime) == false) {
      // create new account with new session token
      newAccount = oldAccount.copyWith(newSessionToken: Nullable<SessionTokenModel>(createNewSessionToken()));

      // remove the old account with the old session token from the cache
      _cachedSessionTokenAccounts.remove(oldAccount.sessionToken?.token);

      // save the new account in cache and update it in local storage
      _cachedSessionTokenAccounts[newAccount.sessionToken!.token] = newAccount;
      await localDataSource.saveAccount(newAccount);
      Logger.debug("Updated the session token for ${oldAccount.userName} from "
          "${oldAccount.sessionToken} to ${newAccount.sessionToken}");
    }
    return newAccount;
  }
}
