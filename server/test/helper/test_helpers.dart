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
  noteRepository = NoteRepository(noteDataSource: noteDataSource, serverConfig: serverConfigMock);
  serverRepository = ServerRepository(
    restServer: restServer,
    serverConfig: serverConfigMock,
    accountRepository: accountRepository,
    noteRepository: noteRepository,
  );

  sessionServiceMock = SessionServiceMock();
  restClient = RestClient(config: serverConfigMock, sessionService: sessionServiceMock);

  initialized = true;
}

/// Should be the last call in the [setUp] function of each test.
///
/// Creates a new [Hive] data folder in the specific test data folder and also starts the [ServerRepository].
///
/// The [Hive] data folder will be in testData/serverPort
Future<void> initTestHiveAndServer(ServerRepository serverRepository, ServerConfig serverConfig) async {
  final String testDataPath = getTestResourceFolderPath(serverConfig);
  FileUtils.createDirectory(testDataPath);
  Hive.init(testDataPath);

  final bool started = await serverRepository.runNota(autoRestart: false);
  expect(started, true);
}

/// Should be the last call in the [tearDown] function of each test.
///
/// Stops the [ServerRepository] and deletes the hive temp files
Future<void> cleanupTestHiveAndServer(ServerRepository serverRepository, ServerConfig serverConfig) async {
  final String testDataPath = getTestResourceFolderPath(serverConfig);
  await serverRepository.stopNota();
  await Hive.close();
  FileUtils.deleteDirectory(testDataPath);
}

/// Returns the modified test resource folder for everything except the server key and certificate
String getTestResourceFolderPath(ServerConfig serverConfig) =>
    "${serverConfig.resourceFolderPath}${Platform.pathSeparator}testData${Platform.pathSeparator}${serverConfig.serverPort}";

ServerAccountModel getTestAccount(int testNumber) {
  return ServerAccountModel(
    userName: "userName$testNumber",
    passwordHash: "passwordHash$testNumber",
    sessionToken: null,
    encryptedDataKey: "encryptedDataKey$testNumber",
    noteInfoList: const <NoteInfo>[],
  );
}

Future<void> createTestAccount(int testNumber) async {
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
  return account.copyWith(newSessionToken: Nullable<SessionTokenModel>(response.sessionToken));
}
