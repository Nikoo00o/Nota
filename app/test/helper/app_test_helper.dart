import 'package:app/core/config/app_config.dart';
import 'package:app/core/get_it.dart';
import 'package:app/core/utils/security_utils_extension.dart';
import 'package:app/data/datasources/local_data_source.dart';
import 'package:app/data/repositories/account_repository_impl.dart';
import 'package:app/domain/entities/client_account.dart';
import 'package:app/domain/repositories/account_repository.dart';
import 'package:app/services/dialog_service.dart';
import 'package:shared/core/enums/log_level.dart';
import 'package:shared/core/utils/logger/logger.dart';

import '../../../server/test/helper/server_test_helper.dart' as server; // relative import of the server test helpers, so
// that the real server responses can be used for testing instead of mocks! The server tests should be run before!
import '../mocks/app_config_mock.dart';
import '../mocks/argon_wrapper_mock.dart';
import '../mocks/dialog_service_mock.dart';
import '../mocks/local_data_source_mock.dart';

late DialogServiceMock dialogServiceMock;

/// The [serverPort] also needs to be unique across the app and server tests. Afterwards you can replace more app
/// implementations with mocks!
Future<void> createCommonTestObjects({required int serverPort}) async {
  await server.createCommonTestObjects(serverPort: serverPort); // init the server test helper objects
  await initializeGetIt(); // init the app singletons
  Logger.initLogger(Logger(logLevel: LogLevel.VERBOSE)); // reset logger to the default dart console prints
  SecurityUtilsExtension.replaceArgonWrapper(ArgonWrapperMock()); // pure dart hashing mock

  sl.allowReassignment = true; // replace some implementations with the mocks!
  sl.registerLazySingleton<LocalDataSource>(() => LocalDataSourceMock()); //always replace the local data source!

  final AppConfigMock appConfigMock = AppConfigMock(); // setup the mock app config
  appConfigMock.serverPortOverride = serverPort;
  appConfigMock.serverHostnameOverride = "https://127.0.0.1";
  sl.registerSingleton<AppConfig>(appConfigMock);

  dialogServiceMock = DialogServiceMock();
  sl.registerSingleton<DialogService>(dialogServiceMock);
}

Future<void> testCleanup() async {
  await server.cleanupTestFilesAndServer(deleteTestFolderAfterwards: true); // cleanup server
  await sl.reset(); // cleanup app singletons
}

/// Makes it so that the account is reloaded from the mock local data source the next time in the [AccountRepository]!
Future<ClientAccount?> clearAccountCache() async => sl<AccountRepository>().getAccount(forceLoad: true);
