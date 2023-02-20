import 'package:app/core/enums/required_login_status.dart';
import 'package:app/core/get_it.dart';
import 'package:app/data/datasources/local_data_source.dart';
import 'package:app/domain/entities/client_account.dart';
import 'package:app/domain/repositories/account_repository.dart';
import 'package:app/domain/usecases/account/change/change_account_password.dart';
import 'package:app/domain/usecases/account/change/change_auto_login.dart';
import 'package:app/domain/usecases/account/change/logout_of_account.dart';
import 'package:app/domain/usecases/account/fetch_current_session_token.dart';
import 'package:app/domain/usecases/account/get_auto_login.dart';
import 'package:app/domain/usecases/account/login/create_account.dart';
import 'package:app/domain/usecases/account/login/get_required_login_status.dart';
import 'package:app/domain/usecases/account/login/login_to_account.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared/core/constants/error_codes.dart';
import 'package:shared/core/exceptions/exceptions.dart';
import 'package:shared/domain/entities/session_token.dart';
import 'package:shared/domain/usecases/usecase.dart';

import '../../server/test/helper/server_test_helper.dart' as server; // relative import of the server test helpers, so that
// the real server responses can be used for testing instead of mocks! The server tests should be run before!
import 'helper/app_test_helper.dart';

const int _serverPort = 9192; // also needs to be a different port for each test file. The app tests dont have to care
// about the server errors!

void main() {
  setUp(() async {
    await createCommonTestObjects(serverPort: _serverPort); // init all helper objects
  });

  tearDown(() async {
    await testCleanup();
  });

  group("account use case tests: ", () {
    group("Create Account: ", _testCreateAccount);
    group("Login to Account: ", _testLoginToAccount);
    group("Auto login: ", _testAutoLogin);
    group("Logout of Account: ", _testLogoutOfAccount);
    group("Fetch current Session Token: ", _testFetchCurrentSessionToken);
    group("Change Account Password: ", _testChangeAccountPassword);
  });
}

void _testCreateAccount() {
  test("Creating a new first account", () async {
    await sl<CreateAccount>().call(const CreateAccountParams(username: "test1", password: "password1"));
    final ClientAccount cachedAccount = await sl<AccountRepository>().getAccountAndThrowIfNull();
    await clearAccountCache();
    final ClientAccount storedAccount = await sl<AccountRepository>().getAccountAndThrowIfNull();
    expect(cachedAccount.userName, "test1", reason: "username should match");
    expect(cachedAccount, storedAccount, reason: "accounts should match");
    expect(server.accountRepository.getAccountByUserName("test1"), isNot(null), reason: "server should have account");

    final bool checkAccountProps = cachedAccount.passwordHash.isNotEmpty &&
        cachedAccount.encryptedDataKey.isNotEmpty &&
        cachedAccount.passwordHash != cachedAccount.encryptedDataKey &&
        cachedAccount.sessionToken == null &&
        cachedAccount.isLoggedIn == false &&
        cachedAccount.noteInfoList.isEmpty;
    expect(checkAccountProps, true, reason: "account properties");
  });

  test("Creating another account", () async {
    await sl<CreateAccount>().call(const CreateAccountParams(username: "test1", password: "password1"));
    await sl<CreateAccount>().call(const CreateAccountParams(username: "test2", password: "password2"));
    final ClientAccount cachedAccount = await sl<AccountRepository>().getAccountAndThrowIfNull();
    await clearAccountCache();
    final ClientAccount storedAccount = await sl<AccountRepository>().getAccountAndThrowIfNull();
    expect(cachedAccount.userName, "test2", reason: "username should match");
    expect(cachedAccount, storedAccount, reason: "accounts should match");
    expect(server.accountRepository.getAccountByUserName("test1"), isNot(null), reason: "server should have account 1");
    expect(server.accountRepository.getAccountByUserName("test2"), isNot(null), reason: "and server should have account 2");
  });
}

void _testLoginToAccount() {
  test("Logging in to an account remotely with a wrong password", () async {
    await sl<CreateAccount>().call(const CreateAccountParams(username: "test1", password: "password1"));
    final String passwordHash = (await sl<AccountRepository>().getAccountAndThrowIfNull()).passwordHash;

    expect(() async {
      // this changes the cached account
      await sl<LoginToAccount>().call(const RemoteLoginParams(username: "test1", password: "11111111"));
    }, throwsA(predicate((Object e) => e is ServerException && e.message == ErrorCodes.ACCOUNT_WRONG_PASSWORD)));
    await Future<void>.delayed(const Duration(milliseconds: 100)); // wait for the async expect!

    final ClientAccount? cachedAccount = await sl<AccountRepository>().getAccount();
    final ClientAccount? storedAccount = await sl<AccountRepository>().getAccount(forceLoad: true); // delete cache
    expect(passwordHash, storedAccount?.passwordHash, reason: "the correct hash should get loaded from storage");
    expect(passwordHash, isNot(cachedAccount?.passwordHash), reason: "cached account should have wrong hash");
  });

  test("Logging in to an account remotely with a wrong username", () async {
    await sl<CreateAccount>().call(const CreateAccountParams(username: "test1", password: "password1"));
    expect(() async {
      await sl<LoginToAccount>().call(const RemoteLoginParams(username: "test2", password: "password1"));
    }, throwsA(predicate((Object e) => e is ServerException && e.message == ErrorCodes.SERVER_UNKNOWN_ACCOUNT)));
  });

  test("Logging in to an account locally with a wrong password", () async {
    await sl<CreateAccount>().call(const CreateAccountParams(username: "test1", password: "password1"));
    await sl<LoginToAccount>().call(const RemoteLoginParams(username: "test1", password: "password1"));
    await clearAccountCache();
    expect(() async {
      await sl<LoginToAccount>().call(const LocalLoginParams(password: "password2"));
    }, throwsA(predicate((Object e) => e is ClientException && e.message == ErrorCodes.ACCOUNT_WRONG_PASSWORD)));
  });

  test("Logging in to an account locally when remote was needed", () async {
    await sl<CreateAccount>().call(const CreateAccountParams(username: "test1", password: "password1"));
    expect(() async {
      await sl<LoginToAccount>().call(const LocalLoginParams(password: "password2"));
    }, throwsA(predicate((Object e) => e is ClientException && e.message == ErrorCodes.CLIENT_NO_ACCOUNT)));
  });

  test("Logging in to an account remotely when local was needed", () async {
    await sl<CreateAccount>().call(const CreateAccountParams(username: "test1", password: "password1"));
    await sl<LoginToAccount>().call(const RemoteLoginParams(username: "test1", password: "password1"));
    expect(() async {
      await sl<LoginToAccount>().call(const RemoteLoginParams(username: "test1", password: "password1"));
    }, throwsA(predicate((Object e) => e is ClientException && e.message == ErrorCodes.CLIENT_NO_ACCOUNT)));
  });

  test("login remote with no stored account", () async {
    expect(() async {
      await sl<LoginToAccount>().call(const RemoteLoginParams(username: "test1", password: "password1"));
    }, throwsA(predicate((Object e) => e is ServerException && e.message == ErrorCodes.SERVER_UNKNOWN_ACCOUNT)));
  });

  test("login locally with no stored account", () async {
    expect(() async {
      await sl<LoginToAccount>().call(const LocalLoginParams(password: "password1"));
    }, throwsA(predicate((Object e) => e is ClientException && e.message == ErrorCodes.CLIENT_NO_ACCOUNT)));
  });

  test("Logging in to an account remotely without a valid stored account", () async {
    await sl<CreateAccount>().call(const CreateAccountParams(username: "test1", password: "password1"));
    await sl<AccountRepository>().saveAccount(ClientAccount.defaultValues(userName: "", passwordHash: ""));

    final ClientAccount cachedAccount = await _remoteLogin("test1", "password1");
    expect(cachedAccount.userName, "test1");
  });

  test("Logging in to an account remotely and locally", () async {
    await sl<CreateAccount>().call(const CreateAccountParams(username: "test1", password: "password1"));

    final ClientAccount cachedAccount = await _remoteLogin("test1", "password1"); // first remote login
    await clearAccountCache(); // the decrypted data key should now no longer be stored
    final ClientAccount storedAccount = await _localLogin("password1"); // then local login

    expect(storedAccount, cachedAccount, reason: "accounts should match, data key is not compared");
  });
}

Future<ClientAccount> _remoteLogin(String username, String password) async {
  RequiredLoginStatus loginStatus = await sl<GetRequiredLoginStatus>().call(NoParams());
  expect(loginStatus, RequiredLoginStatus.REMOTE, reason: "before it should require a remote login");

  await sl<LoginToAccount>().call(RemoteLoginParams(username: username, password: password));
  final ClientAccount cachedAccount = await sl<AccountRepository>().getAccountAndThrowIfNull();
  loginStatus = await sl<GetRequiredLoginStatus>().call(NoParams());

  expect(cachedAccount.isSessionTokenStillValid(), true, reason: "should have valid session token");
  expect(cachedAccount.isLoggedIn, true, reason: "should be logged in and have a decrypted data key ready");
  expect(loginStatus, RequiredLoginStatus.NONE, reason: "afterwards it should require no login at all");
  return cachedAccount;
}

Future<ClientAccount> _localLogin(String password) async {
  final ClientAccount storedAccount = await sl<AccountRepository>().getAccountAndThrowIfNull();
  RequiredLoginStatus loginStatus = await sl<GetRequiredLoginStatus>().call(NoParams());
  expect(storedAccount.isLoggedIn, false, reason: "should no longer be logged in");
  expect(loginStatus, RequiredLoginStatus.LOCAL, reason: "now it should require a local login");

  await sl<LoginToAccount>().call(LocalLoginParams(password: password));
  loginStatus = await sl<GetRequiredLoginStatus>().call(NoParams());

  // the changes should also be applied to the account reference without having to load it again
  expect(storedAccount.isLoggedIn, true, reason: "afterwards it should be logged in again");
  expect(storedAccount.isSessionTokenStillValid(), true, reason: "and should have valid session token");
  expect(loginStatus, RequiredLoginStatus.NONE, reason: "and require no login");
  return storedAccount;
}

void _testAutoLogin() {
  test("testing auto login", () async {
    await sl<CreateAccount>().call(const CreateAccountParams(username: "test1", password: "password1"));
    await sl<LoginToAccount>().call(const RemoteLoginParams(username: "test1", password: "password1"));

    bool hasAutoLogin = await sl<GetAutoLogin>().call(NoParams());
    expect(hasAutoLogin, false, reason: "default should be no auto login");

    await sl<ChangeAutoLogin>().call(const ChangeAutoLoginParams(autoLogin: true));
    hasAutoLogin = await sl<GetAutoLogin>().call(NoParams());
    expect(hasAutoLogin, true, reason: "now it should be true");

    await clearAccountCache();
    RequiredLoginStatus loginStatus = await sl<GetRequiredLoginStatus>().call(NoParams());
    expect(loginStatus, RequiredLoginStatus.NONE, reason: "clearing cache should not require a new login");

    await sl<ChangeAutoLogin>().call(const ChangeAutoLoginParams(autoLogin: false));
    await clearAccountCache();
    loginStatus = await sl<GetRequiredLoginStatus>().call(NoParams());
    expect(loginStatus, RequiredLoginStatus.LOCAL, reason: "but after changing it it should require one again");
  });
}

void _testLogoutOfAccount() {
  test("Logout of an account", () async {
    await sl<CreateAccount>().call(const CreateAccountParams(username: "test1", password: "password1"));
    await sl<LoginToAccount>().call(const RemoteLoginParams(username: "test1", password: "password1"));
    await sl<LogoutOfAccount>().call(NoParams());

    final ClientAccount cachedAccount = await sl<AccountRepository>().getAccountAndThrowIfNull();
    final ClientAccount? storedAccount = await sl<AccountRepository>().getAccount(forceLoad: true);
    final RequiredLoginStatus loginStatus = await sl<GetRequiredLoginStatus>().call(NoParams());

    expect(loginStatus, RequiredLoginStatus.REMOTE, reason: "should need remote login");
    expect(cachedAccount.isLoggedIn, false, reason: "and not be logged in");
    expect(cachedAccount.passwordHash.isEmpty, true, reason: "and have no password hash");
    expect(cachedAccount.isSessionTokenStillValid(), false, reason: "and have no valid session token");
    expect(cachedAccount, storedAccount, reason: "accounts should be same");
  });

  test("Login after logout", () async {
    await sl<CreateAccount>().call(const CreateAccountParams(username: "test1", password: "password1"));
    await sl<LoginToAccount>().call(const RemoteLoginParams(username: "test1", password: "password1"));
    await sl<LogoutOfAccount>().call(NoParams());
    await _remoteLogin("test1", "password1");
  });

  test("logout with no account", () async {
    expect(() async {
      await sl<LogoutOfAccount>().call(NoParams());
    }, throwsA(predicate((Object e) => e is ClientException && e.message == ErrorCodes.CLIENT_NO_ACCOUNT)));
  });
}

void _testFetchCurrentSessionToken() {
  test("Getting correct session tokens twice", () async {
    await sl<CreateAccount>().call(const CreateAccountParams(username: "test1", password: "password1"));
    await sl<LoginToAccount>().call(const RemoteLoginParams(username: "test1", password: "password1"));
    final SessionToken? first = await fetchCurrentSessionToken();
    final SessionToken? second = await fetchCurrentSessionToken();
    expect(first?.isStillValid(), true, reason: "should be valid");
    expect(first, second, reason: "should be same");
  });

  test("Getting the same session token from server after needing to login", () async {
    await sl<CreateAccount>().call(const CreateAccountParams(username: "test1", password: "password1"));
    await sl<LoginToAccount>().call(const RemoteLoginParams(username: "test1", password: "password1"));
    final SessionToken? first = await fetchCurrentSessionToken();
    final ClientAccount account = await sl<AccountRepository>().getAccountAndThrowIfNull();
    account.sessionToken = null;
    final SessionToken? second = await fetchCurrentSessionToken();
    expect(first, second, reason: "should be same");
  });

  test("Making the first login from session token", () async {
    await sl<CreateAccount>().call(const CreateAccountParams(username: "test1", password: "password1"));
    final SessionToken? token = await fetchCurrentSessionToken();
    final ClientAccount account = await sl<AccountRepository>().getAccountAndThrowIfNull();
    expect(token?.isStillValid(), true, reason: "should be valid");
    expect(account.isLoggedIn, false, reason: "but account is not logged in yet");
  });

  test("Trying to get session token with an invalid account stored", () async {
    await sl<CreateAccount>().call(const CreateAccountParams(username: "test1", password: "password1"));
    await sl<AccountRepository>().saveAccount(ClientAccount.defaultValues(userName: "invalid", passwordHash: "invalid"));
    expect(() async {
      await fetchCurrentSessionToken();
    }, throwsA(predicate((Object e) => e is ServerException && e.message == ErrorCodes.SERVER_UNKNOWN_ACCOUNT)));
  });

  test("Trying to get session token with no account stored", () async {
    final SessionToken? token = await fetchCurrentSessionToken();
    expect(token, null, reason: "should be null");
  });
}

void _testChangeAccountPassword() {
  test("Trying to change password with no account should not work", () async {
    expect(() async {
      await sl<ChangeAccountPassword>().call(const ChangePasswordParams(newPassword: "newPassword3"));
    }, throwsA(predicate((Object e) => e is ClientException && e.message == ErrorCodes.CLIENT_NO_ACCOUNT)));
  });

  test("Trying to change password without a login should not work", () async {
    await sl<CreateAccount>().call(const CreateAccountParams(username: "test1", password: "password1"));
    expect(() async {
      await sl<ChangeAccountPassword>().call(const ChangePasswordParams(newPassword: "newPassword3"));
    }, throwsA(predicate((Object e) => e is ClientException && e.message == ErrorCodes.ACCOUNT_WRONG_PASSWORD)));
  });

  test("Trying to change password with an invalid username and no session token", () async {
    await sl<CreateAccount>().call(const CreateAccountParams(username: "test1", password: "password1"));
    await sl<LoginToAccount>().call(const RemoteLoginParams(username: "test1", password: "password1"));
    final ClientAccount account = await sl<AccountRepository>().getAccountAndThrowIfNull();
    account.userName = "invalid";
    account.sessionToken = null;
    expect(() async {
      await sl<ChangeAccountPassword>().call(const ChangePasswordParams(newPassword: "newPassword3"));
    }, throwsA(predicate((Object e) => e is ServerException && e.message == ErrorCodes.SERVER_UNKNOWN_ACCOUNT)));
  });

  test("Trying to change password with an invalid password and no session token should throw error", () async {
    await sl<CreateAccount>().call(const CreateAccountParams(username: "test1", password: "password1"));
    await sl<LoginToAccount>().call(const RemoteLoginParams(username: "test1", password: "password1"));
    final ClientAccount account = await sl<AccountRepository>().getAccountAndThrowIfNull();
    account.passwordHash = "invalid";
    account.sessionToken = null;
    expect(() async {
      await sl<ChangeAccountPassword>().call(const ChangePasswordParams(newPassword: "newPassword3"));
    }, throwsA(predicate((Object e) => e is ServerException && e.message == ErrorCodes.ACCOUNT_WRONG_PASSWORD)));
  });

  test("Change password successfully", () async {
    await sl<CreateAccount>().call(const CreateAccountParams(username: "test1", password: "password1"));
    await sl<LoginToAccount>().call(const RemoteLoginParams(username: "test1", password: "password1"));
    final ClientAccount accountBefore = await sl<AccountRepository>().getAccountAndThrowIfNull();
    await clearAccountCache(); //make sure that the account reference is not the same, because the usecases below will
    // change the account session token, etc!
    await sl<LoginToAccount>().call(const LocalLoginParams(password: "password1")); // refresh the decrypted data key in
    // the cache

    await sl<ChangeAccountPassword>().call(const ChangePasswordParams(newPassword: "newPassword3"));
    final ClientAccount accountAfter = await sl<AccountRepository>().getAccountAndThrowIfNull();
    final RequiredLoginStatus loginStatus = await sl<GetRequiredLoginStatus>().call(NoParams());

    expect(accountAfter.isSessionTokenStillValid(), true, reason: "valid session token");
    expect(accountAfter.sessionToken, isNot(accountBefore.sessionToken), reason: "different session token");
    expect(accountAfter.passwordHash, isNot(accountBefore.passwordHash), reason: "different hash");
    expect(accountAfter.encryptedDataKey, isNot(accountBefore.encryptedDataKey), reason: "different enc key");
    expect(accountAfter.decryptedDataKey, accountBefore.decryptedDataKey, reason: "same dec key");
    expect(loginStatus, RequiredLoginStatus.NONE, reason: "should be logged in");
  });

  test("Change password with no session token should also work", () async {
    await sl<CreateAccount>().call(const CreateAccountParams(username: "test1", password: "password1"));
    await sl<LoginToAccount>().call(const RemoteLoginParams(username: "test1", password: "password1"));
    final ClientAccount account = await sl<AccountRepository>().getAccountAndThrowIfNull();
    account.sessionToken = null;
    await sl<ChangeAccountPassword>().call(const ChangePasswordParams(newPassword: "newPassword3"));
    expect(account.isSessionTokenStillValid(), true);
  });

  test("Trying to change password when some other device already changed it should not work", () async {
    await sl<CreateAccount>().call(const CreateAccountParams(username: "test1", password: "invalid"));
    await sl<LoginToAccount>().call(const RemoteLoginParams(username: "test1", password: "invalid"));
    final ClientAccount account = await sl<AccountRepository>().getAccountAndThrowIfNull();
    account.passwordHash = "password1";
    account.sessionToken =
        SessionToken(token: "someOldNowInvalidToken", validTo: DateTime.now().add(const Duration(days: 1)));
    expect(() async {
      await sl<ChangeAccountPassword>().call(const ChangePasswordParams(newPassword: "password1"));
    }, throwsA(predicate((Object e) => e is ServerException && e.message == ErrorCodes.httpStatusWith(401))));
  });

}
