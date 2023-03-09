import 'dart:io';
import 'package:server/core/config/server_config.dart';
import 'package:server/data/datasources/local_data_source.dart';
import 'package:server/data/models/server_account_model.dart';
import 'package:server/data/repositories/account_repository.dart';
import 'package:server/domain/entities/server_account.dart';
import 'package:server/domain/entities/network/rest_callback.dart';
import 'package:server/domain/entities/network/session_token_redirect.dart';
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

/// This should only be used by the [AccountRepository].
class AccountDataSource {
  final ServerConfig serverConfig;
  final LocalDataSource localDataSource;

  /// A local cache of the server accounts loaded in memory which can be accessed with the session token.
  /// This may not contain all server accounts! The Key is the session token of the [ServerAccountModel]
  final Map<String, ServerAccountModel> _cachedSessionTokenAccounts = <String, ServerAccountModel>{};

  /// A cache of the session token redirects for the old session tokens that got replaced, but still have some time left!
  /// The key is the old session token from the account.
  final Map<String, SessionTokenRedirect> _sessionTokenRedirects = <String, SessionTokenRedirect>{};

  AccountDataSource({required this.serverConfig, required this.localDataSource});

  /// Should return a matching account if the session token is valid and otherwise null.
  ///
  /// Will also remove invalid session tokens and also add loaded accounts to the cache.
  ///
  /// Will also use the redirect session tokens if an old, but still valid session token is used
  Future<ServerAccount?> getAccountBySessionToken(String sessionTokenParam) async {
    if (sessionTokenParam.isEmpty) {
      return null;
    }
    ServerAccountModel? account;
    bool wasLoadedFromStorage = false;
    // also accept redirected session tokens
    final String sessionToken = _convertSessionTokenRedirect(sessionTokenParam);

    if (_cachedSessionTokenAccounts.containsKey(sessionToken)) {
      // check cached accounts
      account = _cachedSessionTokenAccounts[sessionToken]!;
    } else {
      // check stored accounts
      for (final String username in await localDataSource.getAllAccountUserNames()) {
        final ServerAccountModel? tempAccount = await localDataSource.loadAccount(username);
        if (tempAccount?.containsSessionToken(sessionToken) ?? false) {
          account = tempAccount;
          wasLoadedFromStorage = true;
          break;
        }
      }
    }

    if (account != null) {
      // if an account was found (cached, or stored)
      final bool isSessionTokenStillValid = account.isSessionTokenStillValid();
      final bool isSessionTokenEqual = account.sessionToken?.token == sessionToken;
      if (isSessionTokenStillValid == false || isSessionTokenEqual == false) {
        // check if the session token is still valid and if it really matches and otherwise remove the account from the
        // cache and update it in the local storage to not have a session token anymore.
        _cachedSessionTokenAccounts.remove(sessionToken);
        account.sessionToken = null;
        await localDataSource.saveAccount(account);
      } else if (wasLoadedFromStorage) {
        // but if the account contains a valid session token and was loaded from storage, then cache it
        _cachedSessionTokenAccounts[sessionToken] = account;
      }
    }

    return account;
  }

  /// Returns cached, or stored account and also laods the account into the cache.
  ///
  /// Also makes sure that the base64 encoded session token is not already contained in the cached accounts.
  ///
  /// Does not modify the session token if its invalid except when its duplicated.
  Future<ServerAccountModel?> getAccountByUsername(String username) async {
    for (final ServerAccountModel account in _cachedSessionTokenAccounts.values) {
      if (account.username == username) {
        return account; // return cached account
      }
    }
    final ServerAccountModel? account = await localDataSource.loadAccount(username); // return stored account
    if (account != null && account.isSessionTokenStillValid()) {
      final String sessionToken = account.sessionToken!.token;
      if (_cachedSessionTokenAccounts.containsKey(sessionToken)) {
        return account..sessionToken = null; // chance is almost non existent,  but if the session token is already
        // contained in a different account, then make sure this account will have its  own deleted when loading it from
        // storage
      } else {
        _cachedSessionTokenAccounts[sessionToken] = account;
      }
    }
    return account;
  }

  /// Updates a stored and cached account with the new [account] parameter (if they contain the session token, or username
  /// as keys).
  ///
  /// Is used for when the accounts note list is modified in the note repository, etc.
  ///
  /// This method does not modify anything and also does not refresh the session token
  Future<void> storeAccount(ServerAccount account) async {
    final ServerAccountModel accountModel = ServerAccountModel.fromServerAccount(account);
    if (_cachedSessionTokenAccounts.containsKey(accountModel.sessionToken?.token)) {
      _cachedSessionTokenAccounts[accountModel.sessionToken!.token] = accountModel;
    }
    await localDataSource.saveAccount(accountModel);
  }

  /// Creates a new random session token that is valid for [serverConfig.sessionTokenMaxLifetime] from now on.
  ///
  /// Also makes sure that the base64 encoded session token is not already contained in the cached accounts
  SessionTokenModel createNewSessionToken() {
    late String sessionToken;
    do {
      sessionToken = StringUtils.getRandomBytesAsBase64String(SharedConfig.keyBytes);
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
    Logger.debug("Clearing all session tokens");
    _cachedSessionTokenAccounts.clear();
    final List<String> usernames = await localDataSource.getAllAccountUserNames();
    for (final String username in usernames) {
      final ServerAccountModel? account = await localDataSource.loadAccount(username);
      if (account != null && account.sessionToken != null) {
        account.sessionToken = null;
        await localDataSource.saveAccount(account);
      }
    }
  }

  /// Removes the cached accounts which no longer have a valid session token and also update THOSE accounts in the local
  /// storage.
  /// Also removes the cached session account redirects which are no longer valid
  Future<void> clearOldSessions() async {
    Logger.debug("clearing old sessions");
    final List<ServerAccountModel> accountsToUpdate = <ServerAccountModel>[];

    _cachedSessionTokenAccounts.removeWhere((String sessionToken, ServerAccountModel account) {
      // remove cached account and mark it for updating to local storage with no session token
      final bool remove = account.isSessionTokenStillValid() == false;
      if (remove) {
        accountsToUpdate.add(account);
      }
      return remove;
    });

    for (final ServerAccountModel account in accountsToUpdate) {
      await localDataSource.saveAccount(account..sessionToken = null);
    }

    _sessionTokenRedirects.removeWhere((String sessionToken, SessionTokenRedirect redirect) {
      // also remove the session token redirects for which the old session token is no longer valid
      return redirect.from.isStillValid() == false;
    });
  }

  /// refreshes the session token with a new lifetime if its life time is about to expire in the next few minutes.
  /// also updates the stored and cached account if the session token was updated!
  ///
  /// If [forceRegenerate] is true, then a new session token will be regenerated even if the old one is still valid and
  /// also no redirect will be added (and old ones will be removed)! Otherwise a redirect from the old session token of the
  /// [account] will get added to the new session token!
  Future<ServerAccountModel> refreshSessionToken(ServerAccountModel account, {required bool forceRegenerate}) async {
    if (account.isSessionTokenValidFor(serverConfig.sessionTokenRefreshAfterRemainingTime) == false || forceRegenerate) {
      final SessionToken? oldSessionToken = account.sessionToken;
      final SessionToken newSessionToken = createNewSessionToken(); //create new session token
      account.sessionToken = newSessionToken;

      if (forceRegenerate == false) {
        Logger.verbose("Added session token redirect from $oldSessionToken\nto $newSessionToken");
        _addSessionTokenRedirect(oldSessionToken, newSessionToken);
      } else {
        _removeSessionTokenRedirectTo(oldSessionToken);
      }

      // remove the old account with the old session token from the account cache
      _cachedSessionTokenAccounts.remove(oldSessionToken?.token);

      // save the new account in cache and update it in local storage
      _cachedSessionTokenAccounts[newSessionToken.token] = account;
      await localDataSource.saveAccount(account);
      Logger.debug("Updated the session token for ${account.username} from $oldSessionToken\nto $newSessionToken");
    }
    return account;
  }

  /// add redirect from the old session token to the new session token if the old session token is still valid on
  /// refreshing the session token
  void _addSessionTokenRedirect(SessionToken? oldSessionToken, SessionToken newSessionToken) {
    if (oldSessionToken != null && oldSessionToken.isStillValid()) {
      _sessionTokenRedirects[oldSessionToken.token] = SessionTokenRedirect(from: oldSessionToken, to: newSessionToken);
    }
  }

  /// Removes the redirects from other still valid session tokens to the session token
  void _removeSessionTokenRedirectTo(SessionToken? targetSessionToken) {
    _sessionTokenRedirects.removeWhere((String _, SessionTokenRedirect tokens) => tokens.to == targetSessionToken);
  }

  /// If the [sessionToken] is an old token that is still valid and contained in the session token redirects, then the
  /// redirected token will be returned. Otherwise the token itself will be returned
  String _convertSessionTokenRedirect(String sessionToken) {
    if (_sessionTokenRedirects.containsKey(sessionToken)) {
      final SessionTokenRedirect redirect = _sessionTokenRedirects[sessionToken]!;
      if (redirect.isStillValid()) {
        return redirect.to.token;
      } else {
        _sessionTokenRedirects.remove(sessionToken);
      }
    }
    return sessionToken;
  }
}
