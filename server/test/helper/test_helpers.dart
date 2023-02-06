import 'dart:io';

import 'package:hive/hive.dart';
import 'package:server/config/server_config.dart';
import 'package:server/data/datasources/account_data_source.dart.dart';
import 'package:server/data/datasources/local_data_source.dart';
import 'package:server/data/repositories/account_repository.dart';
import 'package:server/data/repositories/server_repository.dart';
import 'package:server/network/rest_server.dart';
import 'package:shared/core/network/rest_client.dart';
import 'package:shared/core/utils/file_utils.dart';
import 'package:shared/core/utils/logger/logger.dart';
import 'package:test/expect.dart';

import '../mocks/rest_server_mock.dart';
import '../mocks/server_config_mock.dart';
import '../mocks/session_service_mock.dart';

// Helper methods for the tests that are used by multiple tests. mostly used for initialisation!

late ServerConfigMock serverConfigMock;
late RestServerMock restServer;
late LocalDataSource localDataSource;
late AccountDataSource accountDataSource;
late ServerRepository serverRepository;
late AccountRepository accountRepository;
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

  accountRepository = AccountRepository(accountDataSource: accountDataSource);
  serverRepository = ServerRepository(
    restServer: restServer,
    serverConfig: serverConfigMock,
    accountRepository: accountRepository,
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
  await Hive.close();
  deleteDirectory(testDataPath);
  createDirectory(testDataPath);
  Hive.init(testDataPath);

  final bool started = await serverRepository.runNota(autoRestart: false);
  expect(started, true);
}

/// Returns the modified test resource folder for everything except the server key and certificate
String getTestResourceFolderPath(ServerConfig serverConfig) =>
    "${serverConfig.resourceFolderPath}${Platform.pathSeparator}testData${Platform.pathSeparator}${serverConfig.serverPort}";
