import 'dart:async';
import 'dart:io';
import 'dart:math';

import 'package:hive/hive.dart';
import 'package:server/core/config/server_config.dart';
import 'package:server/data/datasources/account_data_source.dart.dart';
import 'package:server/data/datasources/local_data_source.dart';
import 'package:server/data/models/server_account_model.dart';
import 'package:server/data/repositories/server_repository.dart';
import 'package:server/core/network/rest_server.dart';
import 'package:server/domain/entities/server_account.dart';
import 'package:shared/core/constants/endpoints.dart';
import 'package:shared/core/constants/error_codes.dart';
import 'package:shared/core/exceptions/exceptions.dart';
import 'package:shared/core/network/rest_client.dart';
import 'package:shared/core/utils/logger/logger.dart';
import 'package:shared/core/utils/nullable.dart';
import 'package:shared/data/dtos/account/account_change_password_request.dart';
import 'package:shared/data/dtos/account/account_change_password_response.dart';
import 'package:shared/data/dtos/account/account_login_request.dart.dart';
import 'package:shared/data/dtos/account/account_login_response.dart';
import 'package:shared/data/dtos/account/create_account_request.dart';
import 'package:shared/data/models/session_token_model.dart';
import 'package:shared/domain/entities/note_info.dart';
import 'package:shared/domain/entities/session_token.dart';
import 'package:test/test.dart';
import 'helper/test_helpers.dart';
import 'mocks/session_service_mock.dart';

// test for the specific account functions.

const int _serverPort = 8195;

void main() {
  setUp(() async {
    // will be run for each test!
    await createCommonTestObjects(serverPort: _serverPort); // creates the global test objects.
    // IMPORTANT: this needs a different server port for each test file! (this callback will be run before each test)
  });

  tearDown(() async {
    await cleanupTestFilesAndServer(deleteTestFolderAfterwards: true); // cleanup server and hive test data after every test
    // (this callback will be run after each test)
  });

  group("account repository tests: ", () {
    group("Create Accounts: ", _testCreateAccounts);
    group("Login to Accounts: ", _testLoginToAccounts);
    group("Change Password: ", _testChangePassword);
  });
}

Future<void> _createMultipleTestAccounts(int amount) async {
  for (int i = 0; i < amount; ++i) {
    await createTestAccount(i);
  }
}

void _testCreateAccounts() {
  test("throw an exception on sending a wrong account token", () async {
    expect(() async {
      await restClient.sendRequest(
        endpoint: Endpoints.ACCOUNT_CREATE,
        bodyData: const CreateAccountRequest(
          createAccountToken: "123",
          userName: "123",
          passwordHash: "123",
          encryptedDataKey: "123",
        ).toJson(),
      );
    }, throwsA((Object e) => e is ServerException && e.message == ErrorCodes.httpStatusWith(HttpStatus.unauthorized)));
  });

  test("throw an exception on sending an empty account token", () async {
    expect(() async {
      await restClient.sendRequest(
        endpoint: Endpoints.ACCOUNT_CREATE,
        bodyData: const CreateAccountRequest(
          createAccountToken: "",
          userName: "123",
          passwordHash: "123",
          encryptedDataKey: "123",
        ).toJson(),
      );
    }, throwsA((Object e) => e is ServerException && e.message == ErrorCodes.httpStatusWith(HttpStatus.unauthorized)));
  });

  test("throw an exception on sending empty request values", () async {
    expect(() async {
      await restClient.sendRequest(
        endpoint: Endpoints.ACCOUNT_CREATE,
        bodyData: CreateAccountRequest(
          createAccountToken: serverConfigMock.createAccountToken,
          userName: "",
          passwordHash: "",
          encryptedDataKey: "",
        ).toJson(),
      );
    }, throwsA((Object e) => e is ServerException && e.message == ErrorCodes.SERVER_INVALID_REQUEST_VALUES));
  });

  test("create a new account testUser1 successfully which should be returned from the local data source", () async {
    await createTestAccount(0);
    final ServerAccountModel? account = await localDataSource.loadAccount(getTestAccount(0).userName);
    expect(account, getTestAccount(0), reason: "first account should match");
    final ServerAccount? sameAccount = await accountRepository.getAccountByUserName(getTestAccount(0).userName);
    expect(account, sameAccount, reason: "second account should be the same");
  });

  test("throw an exception on creating another account with the same name", () async {
    await createTestAccount(0);
    expect(() async {
      await createTestAccount(0);
    }, throwsA((Object e) => e is ServerException && e.message == ErrorCodes.SERVER_ACCOUNT_ALREADY_EXISTS));
  });
}

void _testLoginToAccounts() {
  setUp(() async {
    await _createMultipleTestAccounts(3); // run before all login tests
  });

  test("throw an exception on sending a wrong request dto", () async {
    expect(() async {
      await restClient.sendRequest(
        endpoint: Endpoints.ACCOUNT_LOGIN,
        bodyData: const AccountChangePasswordRequest(newPasswordHash: "", newEncryptedDataKey: "").toJson(),
      );
    }, throwsA((Object e) => e is ServerException && e.message == ErrorCodes.httpStatusWith(400)));
  });

  test("throw an exception on sending empty request values", () async {
    expect(() async {
      await restClient.sendRequest(
        endpoint: Endpoints.ACCOUNT_LOGIN,
        bodyData: const AccountLoginRequest(userName: "", passwordHash: "").toJson(),
      );
    }, throwsA((Object e) => e is ServerException && e.message == ErrorCodes.SERVER_INVALID_REQUEST_VALUES));
  });

  test("throw an exception on logging in with an unknown username", () async {
    expect(() async {
      await restClient.sendRequest(
        endpoint: Endpoints.ACCOUNT_LOGIN,
        bodyData: const AccountLoginRequest(userName: "unknownUsername", passwordHash: "unknownPassword").toJson(),
      );
    }, throwsA((Object e) => e is ServerException && e.message == ErrorCodes.SERVER_UNKNOWN_ACCOUNT));
  });

  test("throw an exception on logging in with an invalid password hash", () async {
    expect(() async {
      await restClient.sendRequest(
        endpoint: Endpoints.ACCOUNT_LOGIN,
        bodyData: AccountLoginRequest(userName: getTestAccount(0).userName, passwordHash: "unknownPassword").toJson(),
      );
    }, throwsA((Object e) => e is ServerException && e.message == ErrorCodes.SERVER_ACCOUNT_WRONG_PASSWORD));
  });

  group("Session Token: ", _testSessionTokens);
}

void _testSessionTokens() {
  test("a valid login request should return a login response with the correct session token", () async {
    ServerAccountModel? account = await localDataSource.loadAccount(getTestAccount(0).userName);
    expect(account, isNot(null));
    account!.sessionToken = await accountRepository.createNewSessionToken();
    await localDataSource.saveAccount(account); // update the account on the server with a concrete session token

    final AccountLoginResponse response = await loginToTestAccount(0);
    expect(account.sessionToken, response.sessionToken);
  });

  test("the session token should stay the same between 2 different login requests to the same account", () async {
    serverConfigMock.sessionTokenMaxLifetimeOverride = const Duration(milliseconds: 500);
    serverConfigMock.sessionTokenRefreshAfterRemainingTimeOverride = const Duration(milliseconds: 250);
    final AccountLoginResponse response1 = await loginToTestAccount(0);
    await Future<void>.delayed(const Duration(milliseconds: 10));
    final AccountLoginResponse otherResponse1 = await loginToTestAccount(1);
    expect(response1.sessionToken, isNot(otherResponse1.sessionToken));
    final AccountLoginResponse response2 = await loginToTestAccount(0);
    expect(response1.sessionToken, response2.sessionToken);
    final AccountLoginResponse otherResponse2 = await loginToTestAccount(1);
    expect(otherResponse1.sessionToken, otherResponse2.sessionToken);
  });

  test("the session token should get refreshed when its max lifetime is over", () async {
    serverConfigMock.sessionTokenMaxLifetimeOverride = const Duration(milliseconds: 40);
    serverConfigMock.sessionTokenRefreshAfterRemainingTimeOverride = const Duration(milliseconds: 1);
    final AccountLoginResponse response1 = await loginToTestAccount(0);
    await Future<void>.delayed(const Duration(milliseconds: 80));
    final AccountLoginResponse response2 = await loginToTestAccount(0);
    expect(response1.sessionToken, isNot(response2.sessionToken));
  });

  test("the session token should also get refreshed when its remaining refresh time is reached", () async {
    serverConfigMock.sessionTokenMaxLifetimeOverride = const Duration(milliseconds: 500);
    serverConfigMock.sessionTokenRefreshAfterRemainingTimeOverride = const Duration(milliseconds: 460);
    final AccountLoginResponse response1 = await loginToTestAccount(0);
    await Future<void>.delayed(const Duration(milliseconds: 80));
    final AccountLoginResponse response2 = await loginToTestAccount(0);
    expect(response1.sessionToken, isNot(response2.sessionToken));
  });

  test("after login the account should be able to be accessed by userName from the cache and contain a valid session token",
      () async {
    await loginToTestAccount(0);
    final ServerAccount? account = await accountRepository.getAccountByUserName(getTestAccount(0).userName);
    expect(
      account,
      predicate((ServerAccount? account) =>
          account != null && account.userName == getTestAccount(0).userName && account.isSessionTokenStillValid()),
    );
  });

  test(
      "after login the account should be able to be accessed by session token from the cache and contain the same session "
      "token", () async {
    final AccountLoginResponse response = await loginToTestAccount(0);
    final ServerAccount? account = await accountRepository.getAccountBySessionToken(response.sessionToken.token);
    expect(
      account,
      predicate((ServerAccount? account) =>
          account != null &&
          account.userName == getTestAccount(0).userName &&
          account.sessionToken == response.sessionToken),
    );
  });

  test("resetting all sessions should invalidate the session token from the storage", () async {
    final AccountLoginResponse response = await loginToTestAccount(0);
    await accountRepository.resetAllSessionTokens();
    final ServerAccount? account = await accountRepository.getAccountBySessionToken(response.sessionToken.token);
    expect(account, predicate((ServerAccount? account) => account == null));
  });

  test("the auto session token clear should not remove valid session tokens from the storage", () async {
    serverConfigMock.sessionTokenMaxLifetimeOverride = const Duration(milliseconds: 500);
    serverConfigMock.sessionTokenRefreshAfterRemainingTimeOverride = const Duration(milliseconds: 100);
    serverRepository.resetSessionCleanupTimer(const Duration(milliseconds: 40));
    final AccountLoginResponse response1 = await loginToTestAccount(0);
    await Future<void>.delayed(const Duration(milliseconds: 80));
    await null;
    final AccountLoginResponse response2 = await loginToTestAccount(0);
    expect(response1.sessionToken, response2.sessionToken);
    await Future<void>.delayed(const Duration(milliseconds: 80));
    await null;
    final ServerAccount? account = await accountRepository.getAccountByUserName(getTestAccount(0).userName);
    expect(response1.sessionToken, account?.sessionToken);
  });

  test("but the auto session token clear should remove invalid session tokens from the storage", () async {
    serverConfigMock.sessionTokenMaxLifetimeOverride = const Duration(milliseconds: 30);
    serverConfigMock.sessionTokenRefreshAfterRemainingTimeOverride = const Duration(milliseconds: 1);
    serverRepository.resetSessionCleanupTimer(const Duration(milliseconds: 40));
    final AccountLoginResponse response1 = await loginToTestAccount(0);
    await Future<void>.delayed(const Duration(milliseconds: 80));
    final AccountLoginResponse response2 = await loginToTestAccount(0);
    expect(response1.sessionToken, isNot(response2.sessionToken), reason: "Both responses should contain a different token");
    await Future<void>.delayed(const Duration(milliseconds: 80));
    final ServerAccount? account = await accountRepository.getAccountByUserName(getTestAccount(0).userName);
    expect(response2.sessionToken, isNot(account?.sessionToken), reason: "The account should contain a different token");
    final ServerAccount? noAccount = await accountRepository.getAccountBySessionToken(response1.sessionToken.token);
    expect(noAccount, null);
  });

  test("after the \"refresh remaining time\" a valid session token should be redirected", () async {
    serverConfigMock.sessionTokenMaxLifetimeOverride = const Duration(milliseconds: 120);
    serverConfigMock.sessionTokenRefreshAfterRemainingTimeOverride = const Duration(milliseconds: 80);
    final AccountLoginResponse response1 = await loginToTestAccount(0);
    await Future<void>.delayed(const Duration(milliseconds: 80));
    final AccountLoginResponse response2 = await loginToTestAccount(0);
    expect(response1.sessionToken, isNot(response2.sessionToken), reason: "session tokens are different");

    final ServerAccount? account1 = await accountRepository.getAccountBySessionToken(response1.sessionToken.token);
    final ServerAccount? account2 = await accountRepository.getAccountBySessionToken(response2.sessionToken.token);
    expect(account1, account2, reason: "both session tokens should get the same account");
    expect(response2.sessionToken, account1?.sessionToken, reason: "account still only the new session token");
  });

  test("but after it expired, the redirect token should also be removed", () async {
    serverConfigMock.sessionTokenMaxLifetimeOverride = const Duration(milliseconds: 120);
    serverConfigMock.sessionTokenRefreshAfterRemainingTimeOverride = const Duration(milliseconds: 80);
    final AccountLoginResponse response1 = await loginToTestAccount(0);
    await Future<void>.delayed(const Duration(milliseconds: 80));
    final AccountLoginResponse response2 = await loginToTestAccount(0);
    await Future<void>.delayed(const Duration(milliseconds: 80));

    final ServerAccount? account1 = await accountRepository.getAccountBySessionToken(response1.sessionToken.token);
    final ServerAccount? account2 = await accountRepository.getAccountBySessionToken(response2.sessionToken.token);
    expect(account1, null, reason: "first account should be invalid");
    expect(account2, isNot(null), reason: "second one should be valid");
  });
}

String getChangedPasswordHash(int testNumber) => "${getTestAccount(testNumber).passwordHash}_changed";

String getChangedEncryptedKey(int testNumber) => "${getTestAccount(testNumber).encryptedDataKey}_changed";

Future<AccountChangePasswordResponse> _changePasswordOfTestAccount(int testNumber) async {
  final Map<String, dynamic> json = await restClient.sendJsonRequest(
    endpoint: Endpoints.ACCOUNT_CHANGE_PASSWORD,
    bodyData: AccountChangePasswordRequest(
      newPasswordHash: getChangedPasswordHash(testNumber),
      newEncryptedDataKey: getChangedEncryptedKey(testNumber),
    ).toJson(),
  );
  return AccountChangePasswordResponse.fromJson(json);
}

void _testChangePassword() {
  test("changing the password after login with an invalid session token should throw an exception", () async {
    await createTestAccount(0);
    await loginToTestAccount(0);

    sessionServiceMock.sessionTokenOverride = "invalid_session_token";

    expect(() async {
      await _changePasswordOfTestAccount(0);
    }, throwsA((Object e) => e is ServerException && e.message == ErrorCodes.httpStatusWith(HttpStatus.unauthorized)));
  });

  test("accessing an old session token after changing passwords should throw an exception", () async {
    await createTestAccount(0);
    final AccountLoginResponse loginResponse = await loginToTestAccount(0);

    sessionServiceMock.sessionTokenOverride = loginResponse.sessionToken.token;
    await _changePasswordOfTestAccount(0);

    final ServerAccount? noAccount = await accountRepository.getAccountBySessionToken(loginResponse.sessionToken.token);
    expect(noAccount, null);
  });

  test("accessing the new session token after changing password should work", () async {
    await createTestAccount(0);
    final AccountLoginResponse loginResponse = await loginToTestAccount(0);

    sessionServiceMock.sessionTokenOverride = loginResponse.sessionToken.token;
    final AccountChangePasswordResponse changePasswordResponse = await _changePasswordOfTestAccount(0);

    final ServerAccount? changedAccount =
        await accountRepository.getAccountBySessionToken(changePasswordResponse.sessionToken.token);
    expect(
      changedAccount,
      predicate((ServerAccount? account) =>
          account != null &&
          account.userName == getTestAccount(0).userName &&
          account.encryptedDataKey == "${getTestAccount(0).encryptedDataKey}_changed"),
    );
  });

  test("after changing passwords, old redirects should also not be valid anymore", () async {
    serverConfigMock.sessionTokenMaxLifetimeOverride = const Duration(milliseconds: 120);
    serverConfigMock.sessionTokenRefreshAfterRemainingTimeOverride = const Duration(milliseconds: 80);
    await createTestAccount(0);
    final AccountLoginResponse response1 = await loginToTestAccount(0);
    await Future<void>.delayed(const Duration(milliseconds: 80));
    await loginToTestAccount(0); // refresh token, so a redirect gets added for the [account1] below
    final ServerAccount? account1 = await accountRepository.getAccountBySessionToken(response1.sessionToken.token);

    sessionServiceMock.sessionTokenOverride = response1.sessionToken.token; // change password with redirected token
    await _changePasswordOfTestAccount(0);

    final ServerAccount? account2 = await accountRepository.getAccountBySessionToken(response1.sessionToken.token);
    expect(account1, isNot(account2), reason: "Accounts are not Equal");
    expect(account2, null, reason: "Second account is null"); // first account should exist and second one not
  });
}
