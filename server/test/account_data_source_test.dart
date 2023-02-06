import 'dart:io';
import 'dart:math';

import 'package:hive/hive.dart';
import 'package:server/config/server_config.dart';
import 'package:server/data/datasources/account_data_source.dart.dart';
import 'package:server/data/datasources/local_data_source.dart';
import 'package:server/data/models/server_account_model.dart';
import 'package:server/data/repositories/server_repository.dart';
import 'package:server/network/rest_server.dart';
import 'package:shared/core/constants/endpoints.dart';
import 'package:shared/core/constants/error_codes.dart';
import 'package:shared/core/exceptions/exceptions.dart';
import 'package:shared/core/network/rest_client.dart';
import 'package:shared/core/utils/logger/logger.dart';
import 'package:shared/core/utils/nullable.dart';
import 'package:shared/data/dtos/account/account_login_request.dart.dart';
import 'package:shared/data/dtos/account/account_login_response.dart';
import 'package:shared/data/dtos/account/create_account_request.dart';
import 'package:shared/data/models/session_token_model.dart';
import 'package:shared/domain/entities/note_info.dart';
import 'package:shared/domain/entities/session_token.dart';
import 'package:test/test.dart';
import 'helper/test_helpers.dart';
import 'mocks/session_service_mock.dart';

// test for the specific account functions
const int _serverPort = 8193;

void main() {
  Logger.initLogger(Logger()); // should always be the first call in every test

  setUp(() async {
    await createCommonTestObjects(serverPort: _serverPort); // use global test objects. needs a different server port for
    // each test file!!!

    await initTestHiveAndServer(serverRepository, serverConfigMock); // init hive test data and also start server for
    // each test (this callback will be run before each test)
  });

  group("account data source tests: ", () {
    group("Create Accounts", _testCreateAccounts);
    group("Login to Accounts", _testLoginToAccounts);
  });
}

/// Must be a getter, because it uses [serverConfigMock] which will only be initialized inside of the [setUp] call
CreateAccountRequest get createTestUser1 {
  return CreateAccountRequest(
    createAccountToken: serverConfigMock.createAccountToken,
    userName: "testUser1",
    passwordHash: "testPassword1",
    encryptedDataKey: "testEncryptedKey1",
  );
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
    }, throwsA((Object e) => e is ServerException && e.message == ErrorCodes.SERVER_EMPTY_REQUEST_VALUES));
  });

  test("create a new account testUser1 successfully", () async {
    await restClient.sendRequest(
      endpoint: Endpoints.ACCOUNT_CREATE,
      bodyData: createTestUser1.toJson(),
    );
    final ServerAccountModel? account = await localDataSource.loadAccount(createTestUser1.userName);
    expect(
      account,
      predicate((ServerAccountModel? account) =>
          account != null &&
          account.userName == createTestUser1.userName &&
          account.passwordHash == createTestUser1.passwordHash &&
          account.encryptedDataKey == createTestUser1.encryptedDataKey),
    );
  });

  test("throw an exception on creating another account with the same name", () async {
    await restClient.sendRequest(
      endpoint: Endpoints.ACCOUNT_CREATE,
      bodyData: createTestUser1.toJson(),
    );
    expect(() async {
      await restClient.sendRequest(
        endpoint: Endpoints.ACCOUNT_CREATE,
        bodyData: createTestUser1.toJson(),
      );
    }, throwsA((Object e) => e is ServerException && e.message == ErrorCodes.SERVER_ACCOUNT_ALREADY_EXISTS));
  });
}

ServerAccountModel _getTestAccount(int testNumber) {
  return ServerAccountModel(
    userName: "userName$testNumber",
    passwordHash: "passwordHash$testNumber",
    sessionToken: null,
    encryptedDataKey: "encryptedDataKey$testNumber",
    noteInfoList: const <NoteInfo>[],
  );
}

Future<void> _createTestAccounts(int amount) async {
  for (int i = 0; i < amount; ++i) {
    final ServerAccountModel account = _getTestAccount(i);
    await restClient.sendRequest(
      endpoint: Endpoints.ACCOUNT_CREATE,
      bodyData: CreateAccountRequest(
        createAccountToken: serverConfigMock.createAccountToken,
        userName: account.userName,
        passwordHash: account.passwordHash,
        encryptedDataKey: account.encryptedDataKey,
      ).toJson(),
    );
  }
}

Future<AccountLoginResponse> _loginToTestAccount(int testNumber) async {
  final Map<String, dynamic> json = await restClient.sendRequest(
    endpoint: Endpoints.ACCOUNT_LOGIN,
    bodyData: AccountLoginRequest(
      userName: _getTestAccount(testNumber).userName,
      passwordHash: _getTestAccount(testNumber).passwordHash,
    ).toJson(),
  );
  return AccountLoginResponse.fromJson(json);
}

void _testLoginToAccounts() {
  setUp(() async {
    await _createTestAccounts(3); // run before all login tests
  });

  test("throw an exception on sending empty request values", () async {
    expect(() async {
      await restClient.sendRequest(
        endpoint: Endpoints.ACCOUNT_LOGIN,
        bodyData: const AccountLoginRequest(userName: "", passwordHash: "").toJson(),
      );
    }, throwsA((Object e) => e is ServerException && e.message == ErrorCodes.SERVER_EMPTY_REQUEST_VALUES));
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
        bodyData: AccountLoginRequest(userName: _getTestAccount(0).userName, passwordHash: "unknownPassword").toJson(),
      );
    }, throwsA((Object e) => e is ServerException && e.message == ErrorCodes.SERVER_ACCOUNT_WRONG_PASSWORD));
  });

  test("a valid login request should return a login response with the correct session token", () async {
    ServerAccountModel? account = await localDataSource.loadAccount(_getTestAccount(0).userName);
    expect(account, isNot(null));
    account = account!.copyWith(newSessionToken: Nullable<SessionToken>(accountDataSource.createNewSessionToken()));
    await localDataSource.saveAccount(account); // update the account on the server with a concrete session token

    final AccountLoginResponse response = await _loginToTestAccount(0);
    expect(account.sessionToken, response.sessionToken);
  });

  test("the session token should stay the same between 2 different login requests", () async {
    final AccountLoginResponse response1 = await _loginToTestAccount(0);
    final AccountLoginResponse response2 = await _loginToTestAccount(0);
    expect(response1.sessionToken, response2.sessionToken);
  });
}
