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
import 'package:shared/data/dtos/account/account_login_request.dart.dart';
import 'package:shared/data/dtos/account/account_login_response.dart';
import 'package:shared/data/dtos/account/create_account_request.dart';
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

void _testLoginToAccounts() {
//todo: implement
  test("TODO: implement", () async {
    await restClient.sendRequest(
      endpoint: Endpoints.ACCOUNT_CREATE,
      bodyData: createTestUser1.toJson(),
    );
    final Map<String, dynamic> json = await restClient.sendRequest(
      endpoint: Endpoints.ACCOUNT_LOGIN,
      bodyData: AccountLoginRequest(userName: createTestUser1.userName, passwordHash: createTestUser1.passwordHash).toJson(),
    );
    final AccountLoginResponse response = AccountLoginResponse.fromJson(json);

    print(response.sessionToken); // expect same as stored. then request session token again and expect same one. then
    // invalidate session token and expect new one, etc...
  });
}
