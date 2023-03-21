import 'dart:convert';
import 'dart:typed_data';

import 'package:app/core/config/app_config.dart';
import 'package:app/core/get_it.dart';
import 'package:app/core/utils/security_utils_extension.dart';
import 'package:app/data/datasources/local_data_source.dart';
import 'package:app/domain/entities/client_account.dart';
import 'package:app/domain/repositories/account_repository.dart';
import 'package:app/domain/usecases/account/get_logged_in_account.dart';
import 'package:app/domain/usecases/account/login/create_account.dart';
import 'package:app/domain/usecases/account/login/login_to_account.dart';
import 'package:app/domain/usecases/note_transfer/inner/store_note_encrypted.dart';
import 'package:app/services/dialog_service.dart';
import 'package:shared/core/enums/log_level.dart';
import 'package:shared/data/datasources/rest_client.dart';
import 'package:shared/domain/usecases/usecase.dart';

import '../../../server/test/helper/server_test_helper.dart' as server; // relative import of the server test helpers, so
// that the real server responses can be used for testing instead of mocks! The server tests should be run before!
import '../mocks/app_config_mock.dart';
import '../mocks/argon_wrapper_mock.dart';
import '../mocks/dialog_service_mock.dart';
import '../mocks/local_data_source_mock.dart';

late DialogServiceMock dialogServiceMock;

/// The [serverPort] also needs to be unique across the app and server tests. Afterwards you can replace more app
/// implementations with mocks!
///
/// You can also set a new default [logLevel] in this method params for all tests.
Future<void> createCommonTestObjects({required int serverPort, LogLevel logLevel = LogLevel.VERBOSE}) async {
  await server.createCommonTestObjects(serverPort: serverPort, logLevel: logLevel); // init the server test helper objects
  // this will also init the dart console logger

  await initializeGetIt(); // init the app singletons
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
  sl<RestClient>().close();
  await server.cleanupTestFilesAndServer(deleteTestFolderAfterwards: true); // cleanup server
  await sl.reset(); // cleanup app singletons
}

/// Makes it so that the account is reloaded from the mock local data source the next time in the [AccountRepository]!
Future<ClientAccount?> clearAccountCache() async => sl<AccountRepository>().getAccount(forceLoad: true);

/// Also creates the account and logs in to the account and returns the account
Future<ClientAccount> createAndLoginToTestAccount({bool reuseOldNotes = false}) async {
  await sl<CreateAccount>().call(const CreateAccountParams(username: "test1", password: "password1"));
  return loginToTestAccount(reuseOldNotes: reuseOldNotes);
}

Future<ClientAccount> loginToTestAccount({bool reuseOldNotes = false}) async {
  await sl<LoginToAccount>()
      .call(LoginToAccountParamsRemote(username: "test1", password: "password1", reuseOldNotes: reuseOldNotes));
  final ClientAccount account = await sl<GetLoggedInAccount>().call(const NoParams());
  return account;
}

/// For recent the notes are ordered as followed:
///
/// fourth
///
/// a_third
///
/// second (in dir2)
///
/// second(in dir1)
///
/// first.
///
///
/// For root the notes are ordered like:
///
/// dir1
///
/// ------ a_third
///
/// ------ dir3
///
/// ------ -------- fourth
///
/// ------ second
///
/// dir2
///
/// ------ second
///
/// first.
Future<void> createSomeTestNotes() async {
  int counter = -1;
  final Uint8List content = Uint8List.fromList(utf8.encode("123"));
  await sl<StoreNoteEncrypted>()
      .call(CreateNoteEncryptedParams(noteId: counter--, decryptedName: "first", decryptedContent: content));
  await Future<void>.delayed(const Duration(milliseconds: 10));
  await sl<StoreNoteEncrypted>()
      .call(CreateNoteEncryptedParams(noteId: counter--, decryptedName: "dir1/second", decryptedContent: content));
  await Future<void>.delayed(const Duration(milliseconds: 10));
  await sl<StoreNoteEncrypted>()
      .call(CreateNoteEncryptedParams(noteId: counter--, decryptedName: "dir2/second", decryptedContent: content));
  await Future<void>.delayed(const Duration(milliseconds: 10));
  await sl<StoreNoteEncrypted>()
      .call(CreateNoteEncryptedParams(noteId: counter--, decryptedName: "dir1/a_third", decryptedContent: content));
  await Future<void>.delayed(const Duration(milliseconds: 10));
  await sl<StoreNoteEncrypted>()
      .call(CreateNoteEncryptedParams(noteId: counter--, decryptedName: "dir1/dir3/fourth", decryptedContent: content));

  await sl<LocalDataSource>().setClientNoteCounter(counter); // important: update counter
}
