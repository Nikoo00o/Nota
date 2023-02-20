import 'package:app/core/enums/required_login_status.dart';
import 'package:app/core/get_it.dart';
import 'package:app/data/datasources/local_data_source.dart';
import 'package:app/domain/entities/client_account.dart';
import 'package:app/domain/repositories/account_repository.dart';
import 'package:app/domain/usecases/account/login/create_account.dart';
import 'package:app/domain/usecases/account/login/get_required_login_status.dart';
import 'package:app/domain/usecases/account/login/login_to_account.dart';
import 'package:flutter_test/flutter_test.dart';
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

    expect(
        cachedAccount.passwordHash.isNotEmpty &&
            cachedAccount.encryptedDataKey.isNotEmpty &&
            cachedAccount.passwordHash != cachedAccount.encryptedDataKey &&
            cachedAccount.sessionToken == null &&
            cachedAccount.isLoggedIn == false &&
            cachedAccount.noteInfoList.isEmpty,
        true,
        reason: "account properties");
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
  test("Logging in to an account remotely and locally", () async {
    await sl<CreateAccount>().call(const CreateAccountParams(username: "test1", password: "password1"));

    final ClientAccount cachedAccount = await _remoteLogin("test1", "password1"); // first remote login
    await clearAccountCache(); // the decrypted data key should now no longer be stored
    final ClientAccount storedAccount = await _localLogin("password1"); // then local login

    expect(storedAccount, cachedAccount, reason: "accounts should match, data key is not compared");
  });

  test("Logging in to an account remotely without a valid stored account", () async {
    await sl<CreateAccount>().call(const CreateAccountParams(username: "test1", password: "password1"));
    await sl<AccountRepository>().saveAccount(ClientAccount.defaultValues(userName: "", passwordHash: ""));

    final ClientAccount cachedAccount = await _remoteLogin("test1", "password1");
    expect(cachedAccount.userName, "test1");
  });

  // tests: wrong password. wrong combination of local / remote. local login with no valid account, etc 
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

void _testLogoutOfAccount() {}

void _testFetchCurrentSessionToken() {}

void _testChangeAccountPassword() {}
