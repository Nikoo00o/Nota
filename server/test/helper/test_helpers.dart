import 'dart:io';

import 'package:hive/hive.dart';
import 'package:server/core/config/server_config.dart';
import 'package:server/data/datasources/account_data_source.dart.dart';
import 'package:server/data/datasources/local_data_source.dart';
import 'package:server/data/datasources/note_data_source.dart';
import 'package:server/data/models/server_account_model.dart';
import 'package:server/data/repositories/account_repository.dart';
import 'package:server/data/repositories/note_repository.dart';
import 'package:server/data/repositories/server_repository.dart';
import 'package:server/core/network/rest_server.dart';
import 'package:shared/core/constants/endpoints.dart';
import 'package:shared/core/network/rest_client.dart';
import 'package:shared/core/utils/file_utils.dart';
import 'package:shared/core/utils/logger/logger.dart';
import 'package:shared/core/utils/nullable.dart';
import 'package:shared/data/dtos/account/account_change_password_request.dart';
import 'package:shared/data/dtos/account/account_change_password_response.dart';
import 'package:shared/data/dtos/account/account_login_request.dart.dart';
import 'package:shared/data/dtos/account/account_login_response.dart';
import 'package:shared/data/dtos/account/create_account_request.dart';
import 'package:shared/data/models/session_token_model.dart';
import 'package:shared/domain/entities/note_info.dart';
import 'package:test/expect.dart';

import '../mocks/rest_server_mock.dart';
import '../mocks/server_config_mock.dart';
import '../mocks/session_service_mock.dart';

// Helper methods for the tests that are used by multiple tests. mostly used for initialisation!

late ServerConfigMock serverConfigMock;
late RestServerMock restServer;
late LocalDataSource localDataSource;
late AccountDataSource accountDataSource;
late NoteDataSource noteDataSource;
late ServerRepository serverRepository;
late AccountRepository accountRepository;
late NoteRepository noteRepository;
late SessionServiceMock sessionServiceMock;
late RestClient restClient;
bool initialized = false;

/// Should be the first call in the [setUp] function of each test.
///
/// Is used to create common used repositories, data sources, etc as global objects so they dont have to be created in
/// each test! Is an alternative to getIt.
///
/// Also cleans up for old tests.
///
/// the [serverPort] must be different for each test file, so that they can be run at the same time!
///
/// The [serverPort] also gets used to assign different test data folders to each test file!
Future<void> createCommonTestObjects({required int serverPort}) async {
  if (initialized) {
    //cleanup for old test:
    await restServer.stop();
  }

  serverConfigMock = ServerConfigMock(serverPortOverride: serverPort);
  restServer = RestServerMock();

  localDataSource = LocalDataSourceImpl(serverConfig: serverConfigMock);
  accountDataSource = AccountDataSource(serverConfig: serverConfigMock, localDataSource: localDataSource);
  noteDataSource = NoteDataSource(serverConfig: serverConfigMock, localDataSource: localDataSource);

  accountRepository = AccountRepository(accountDataSource: accountDataSource, serverConfig: serverConfigMock);
  noteRepository = NoteRepository(
    noteDataSource: noteDataSource,
    serverConfig: serverConfigMock,
    accountRepository: accountRepository,
  );
  serverRepository = ServerRepository(
    restServer: restServer,
    serverConfig: serverConfigMock,
    accountRepository: accountRepository,
    noteRepository: noteRepository,
  );

  sessionServiceMock = SessionServiceMock();
  restClient = RestClient(config: serverConfigMock, sessionService: sessionServiceMock);

  initialized = true;

  await _setup();
}

Future<void> _setup() async {
  Logger.initLogger(Logger()); // the logger must always be initialized first

  // modifies the resource path to depend on the test port, so its unique for each test
  final String baseTestPath = FileUtils.getLocalFilePath("test${Platform.pathSeparator}data");
  serverConfigMock.resourceFolderPathOverride = "$baseTestPath${Platform.pathSeparator}${serverConfigMock.serverPort}";

  await localDataSource.init(); // create the required folders and init the database
  await noteDataSource.init();

  // copy the test certificate files into the specific test folder
  FileUtils.copyFile(
    "$baseTestPath${Platform.pathSeparator}key.pem",
    "${serverConfigMock.resourceFolderPath}${Platform.pathSeparator}key.pem",
  );
  FileUtils.copyFile(
    "$baseTestPath${Platform.pathSeparator}certificate.pem",
    "${serverConfigMock.resourceFolderPath}${Platform.pathSeparator}certificate.pem",
  );

  final bool started = await serverRepository.runNota(autoRestart: false);
  expect(started, true); // start the server and expect it to run

  FileUtils.getLocalFilePath("notaRes");
}

/// Should be the last call in the [tearDown] function of each test.
///
/// Stops the [ServerRepository] and deletes the hive temp files.
///
/// You can set [deleteTestFolderAfterwards] to false if you want to inspect some test files after one single test, or if
/// you want to test the persistence of the server.
Future<void> cleanupTestFilesAndServer({required bool deleteTestFolderAfterwards}) async {
  await serverRepository.stopNota();
  await Hive.close();
  if (deleteTestFolderAfterwards) {
    FileUtils.deleteDirectory(serverConfigMock.resourceFolderPath);
  }
}

ServerAccountModel getTestAccount(int testNumber) {
  return ServerAccountModel(
    userName: "userName$testNumber",
    passwordHash: "passwordHash$testNumber",
    sessionToken: null,
    encryptedDataKey: "encryptedDataKey$testNumber",
    noteInfoList: const <NoteInfo>[],
  );
}

Future<ServerAccountModel> createTestAccount(int testNumber) async {
  final ServerAccountModel account = getTestAccount(testNumber);
  await restClient.sendRequest(
    endpoint: Endpoints.ACCOUNT_CREATE,
    bodyData: CreateAccountRequest(
      createAccountToken: serverConfigMock.createAccountToken,
      userName: account.userName,
      passwordHash: account.passwordHash,
      encryptedDataKey: account.encryptedDataKey,
    ).toJson(),
  );
  return account;
}

Future<AccountLoginResponse> loginToTestAccount(int testNumber) async {
  final Map<String, dynamic> json = await restClient.sendJsonRequest(
    endpoint: Endpoints.ACCOUNT_LOGIN,
    bodyData: AccountLoginRequest(
      userName: getTestAccount(testNumber).userName,
      passwordHash: getTestAccount(testNumber).passwordHash,
    ).toJson(),
  );
  return AccountLoginResponse.fromJson(json);
}

Future<ServerAccountModel> createAndLoginToTestAccount(int testNumber) async {
  final ServerAccountModel account = getTestAccount(testNumber);
  await createTestAccount(testNumber);
  final AccountLoginResponse response = await loginToTestAccount(testNumber);
  account.sessionToken = response.sessionToken;
  return account;
}
