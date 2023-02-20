import 'package:app/core/get_it.dart';
import 'package:app/data/datasources/local_data_source.dart';
import 'package:app/domain/entities/client_account.dart';
import 'package:app/domain/repositories/account_repository.dart';
import 'package:app/domain/usecases/account/login/create_account.dart';
import 'package:flutter_test/flutter_test.dart';

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
    await sl<CreateAccount>().execute(const CreateAccountParams(username: "test1", password: "password1"));
    final ClientAccount account = await sl<AccountRepository>().getAccountAndThrowIfNull();
    print(account);

  });
}

void _testLoginToAccount() {}

void _testLogoutOfAccount() {}

void _testFetchCurrentSessionToken() {}

void _testChangeAccountPassword() {}
