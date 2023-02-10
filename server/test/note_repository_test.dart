import 'package:shared/core/utils/logger/logger.dart';
import 'package:test/test.dart';

import 'helper/test_helpers.dart';

// test for the specific note updating functions.
const int _serverPort = 8193;

void main() {
  Logger.initLogger(Logger()); // should always be the first call in every test

  setUp(() async {
    // will be run for each test!
    await createCommonTestObjects(serverPort: _serverPort); // use global test objects. needs a different server port for
    // each test file!!!

    await initTestHiveAndServer(serverRepository, serverConfigMock); // init hive test data and also start server for
    // each test (this callback will be run before each test)
  });

  tearDown(() async {
    await cleanupTestHiveAndServer(serverRepository, serverConfigMock); // cleanup server and hive test data after every
    // test (this callback will be run after each test)
  });

  //todo: ...
}
