import 'dart:async';
import 'dart:convert';
import 'package:server/data/models/server_account_model.dart';
import 'package:shared/core/constants/endpoints.dart';
import 'package:shared/core/constants/error_codes.dart';
import 'package:shared/core/constants/rest_json_parameter.dart';
import 'package:shared/core/enums/note_transfer_status.dart';
import 'package:shared/core/exceptions/exceptions.dart';
import 'package:shared/core/utils/logger/logger.dart';
import 'package:shared/data/dtos/account/account_change_password_request.dart';
import 'package:shared/data/dtos/account/account_change_password_response.dart';
import 'package:shared/data/dtos/account/account_login_request.dart.dart';
import 'package:shared/data/dtos/account/account_login_response.dart';
import 'package:shared/data/dtos/notes/finish_note_request.dart';
import 'package:shared/data/dtos/notes/start_note_transfer_request.dart';
import 'package:shared/data/dtos/notes/start_note_transfer_response.dart';
import 'package:shared/data/models/note_info_model.dart';
import 'package:shared/data/models/note_update_model.dart';
import 'package:shared/domain/entities/response_data.dart';
import 'package:test/test.dart';
import 'helper/server_test_helper.dart';

// test for a combination of other tests. This tests the workflow which the app would follow

const int _serverPort = 8295;

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

  test("integration test", _integrationTest); // only one test, because the tests need to be in order
}

late ServerAccountModel _account1;
late ServerAccountModel _account2;
late ServerAccountModel _account3;

Future<void> _integrationTest() async {
  await _accountTests();
  await _noteTests();
}

Future<void> _accountTests() async {
  Logger.info("create accounts");
  _account1 = await createAndLoginToTestAccount(1);
  _account2 = await createAndLoginToTestAccount(2);

  Logger.info("login to one again again");
  final AccountLoginResponse login = await _loginToAccount(_account1);
  expect(login.sessionToken, _account1.sessionToken);
  expect(_account1.sessionToken, isNot(_account2.sessionToken));

  Logger.info("change password of one account");
  _account2.passwordHash = "changed";
  final AccountChangePasswordResponse changePw = await _changePasswordOfTestAccount(_account2);
  final AccountLoginResponse login2 = await _loginToAccount(_account2);
  expect(changePw.sessionToken, login2.sessionToken);
  expect(changePw.sessionToken, isNot(_account2.sessionToken));
  _account2.sessionToken = changePw.sessionToken;

  Logger.info("create a third account");
  _account3 = await createAndLoginToTestAccount(3);
  expect(_account3.sessionToken, isNot(_account2.sessionToken));
  expect(_account3.sessionToken, isNot(_account1.sessionToken));
}

Future<void> _noteTests() async {
  await _firstTransfer();
  Logger.info("restarting server and loading data from files");
  await cleanupTestFilesAndServer(deleteTestFolderAfterwards: false);
  await createCommonTestObjects(serverPort: _serverPort);
  await _secondTransfer();
  await _thirdTransfer();
  await _fourthTransfer();
}

Future<void> _firstTransfer() async {
  _account1.noteInfoList = <NoteInfoModel>[
    NoteInfoModel(id: -1, encFileName: "c1_1", lastEdited: _now.subtract(const Duration(days: 5))),
  ];

  _account2.noteInfoList = <NoteInfoModel>[
    NoteInfoModel(id: -1, encFileName: "c2_1", lastEdited: _now.subtract(const Duration(days: 5))),
  ];

  Logger.info("starting first transfers to add some notes to the server");
  final StartNoteTransferResponse transfer1 = await _startTransfer(_account1);
  final StartNoteTransferResponse transfer2 = await _startTransfer(_account2);
  final StartNoteTransferResponse invalidTransfer = await _startTransfer(_account1);
  final StartNoteTransferResponse emptyTransfer = await _startTransfer(_account3);
  final StartNoteTransferResponse cancelledTransfer = await _startTransfer(_account3);

  expect(transfer1.noteUpdates.length, 1);
  expect(transfer1.noteUpdates.length, 1);
  expect(transfer1.noteUpdates.first.noteTransferStatus, NoteTransferStatus.SERVER_NEEDS_NEW);
  expect(transfer2.noteUpdates.first.noteTransferStatus, NoteTransferStatus.SERVER_NEEDS_NEW);
  expect(transfer1.noteUpdates.first.serverId, 1);
  expect(transfer2.noteUpdates.first.serverId, 2);
  expect(invalidTransfer.noteUpdates.first.serverId, 3);
  expect(transfer1.transferToken, isNot(transfer2.transferToken));
  expect(transfer1.transferToken, isNot(invalidTransfer.transferToken));
  expect(transfer1.noteUpdates.first.newEncFileName, invalidTransfer.noteUpdates.first.newEncFileName);
  expect(emptyTransfer.noteUpdates.isEmpty, true);

  Logger.info("uploading notes");
  await _upload(_account1, transfer1.transferToken, transfer1.noteUpdates.first.serverId, utf8.encode("c1_1_text"));
  await _upload(_account2, transfer2.transferToken, transfer2.noteUpdates.first.serverId, utf8.encode("c2_1_text"));
  await _upload(
      _account1, invalidTransfer.transferToken, invalidTransfer.noteUpdates.first.serverId, utf8.encode("INVALID"));

  expect(() async {
    await _upload(_account3, emptyTransfer.transferToken, 1, utf8.encode("ignored"));
  }, throwsA((Object e) => e is ServerException && e.message == ErrorCodes.SERVER_INVALID_REQUEST_VALUES));
  await Future<void>.delayed(const Duration(milliseconds: 25));

  Logger.info("finishing transfers");
  await _finishTransfer(_account1, transfer1.transferToken, shouldCancel: false);
  await _finishTransfer(_account2, transfer2.transferToken, shouldCancel: false);

  expect(() async {
    await _finishTransfer(_account1, invalidTransfer.transferToken, shouldCancel: false); // already cancelled by transfer1
  }, throwsA((Object e) => e is ServerException && e.message == ErrorCodes.SERVER_INVALID_NOTE_TRANSFER_TOKEN));
  await Future<void>.delayed(const Duration(milliseconds: 25));

  await _finishTransfer(_account3, cancelledTransfer.transferToken, shouldCancel: true); // should not affect others
  await _finishTransfer(_account3, emptyTransfer.transferToken, shouldCancel: false);

  expect(() async {
    await _finishTransfer(_account3, emptyTransfer.transferToken, shouldCancel: false); //cancelled from last finish call
  }, throwsA((Object e) => e is ServerException && e.message == ErrorCodes.SERVER_INVALID_NOTE_TRANSFER_TOKEN));
  await Future<void>.delayed(const Duration(milliseconds: 25));

  Logger.info("updating client ids");
  _account1.noteInfoList[0] = NoteInfoModel(
      id: transfer1.noteUpdates.first.serverId,
      encFileName: "c1_1_changed",
      lastEdited: _account1.noteInfoList.first.lastEdited.subtract(const Duration(days: 1)));
  _account2.noteInfoList[0] = NoteInfoModel(
      id: transfer2.noteUpdates.first.serverId,
      encFileName: "c2_1_changed",
      lastEdited: _account2.noteInfoList.first.lastEdited.add(const Duration(days: 1)));
}

Future<void> _secondTransfer() async {
  _account1.noteInfoList.add(NoteInfoModel(id: -2, encFileName: "c1_2", lastEdited: _now.subtract(const Duration(days: 5))));

  _account2.noteInfoList.add(NoteInfoModel(id: -3, encFileName: "c2_2", lastEdited: _now.subtract(const Duration(days: 5))));

  Logger.info("starting second transfers to change some notes");

  final StartNoteTransferResponse transfer1 = await _startTransfer(_account1);
  final StartNoteTransferResponse transfer2 = await _startTransfer(_account2);
  expect(transfer1.noteUpdates.length, 2);
  expect(transfer1.noteUpdates.length, 2);

  expect(transfer1.noteUpdates.first.noteTransferStatus, NoteTransferStatus.CLIENT_NEEDS_UPDATE);
  expect(transfer1.noteUpdates[1].noteTransferStatus, NoteTransferStatus.SERVER_NEEDS_NEW);
  expect(transfer1.noteUpdates.first.newEncFileName, "c1_1");
  expect(transfer1.noteUpdates[1].newEncFileName, "c1_2");
  expect(transfer1.noteUpdates.first.serverId, 1);
  expect(transfer1.noteUpdates[1].serverId, 4);

  expect(transfer2.noteUpdates.first.noteTransferStatus, NoteTransferStatus.SERVER_NEEDS_UPDATE);
  expect(transfer2.noteUpdates[1].noteTransferStatus, NoteTransferStatus.SERVER_NEEDS_NEW);
  expect(transfer2.noteUpdates.first.newEncFileName, "c2_1_changed");
  expect(transfer2.noteUpdates[1].newEncFileName, "c2_2");
  expect(transfer2.noteUpdates.first.serverId, 2);
  expect(transfer2.noteUpdates[1].serverId, 5);

  Logger.info("downloading note");
  final List<int> bytes = await _download(_account1, transfer1.transferToken, transfer1.noteUpdates.first.serverId);
  expect(utf8.decode(bytes), "c1_1_text");

  Logger.info("uploading notes");
  await _upload(_account1, transfer1.transferToken, transfer1.noteUpdates[1].serverId, utf8.encode("c1_2_text"));

  await _upload(_account2, transfer2.transferToken, transfer2.noteUpdates.first.serverId, utf8.encode("c2_1_changed_text"));
  await _upload(_account2, transfer2.transferToken, transfer2.noteUpdates[1].serverId, utf8.encode("c2_2_text"));

  Logger.info("finishing transfers");
  await _finishTransfer(_account1, transfer1.transferToken, shouldCancel: false);
  await _finishTransfer(_account2, transfer2.transferToken, shouldCancel: false);
}

Future<void> _thirdTransfer() async {
  _account1.noteInfoList.clear();
  _account2.noteInfoList.clear();

  Logger.info("starting third transfer to download all notes again");
  final StartNoteTransferResponse transfer1 = await _startTransfer(_account1);
  final StartNoteTransferResponse transfer2 = await _startTransfer(_account2);
  transfer1.noteUpdates.forEach(_expectClientNeedsNew);
  transfer2.noteUpdates.forEach(_expectClientNeedsNew);

  Logger.info("downloading note");
  final List<int> bytes1 = await _download(_account1, transfer1.transferToken, transfer1.noteUpdates.first.serverId);
  final List<int> bytes2 = await _download(_account1, transfer1.transferToken, transfer1.noteUpdates[1].serverId);
  expect(utf8.decode(bytes1), "c1_1_text");
  expect(utf8.decode(bytes2), "c1_2_text");

  final List<int> bytes3 = await _download(_account2, transfer2.transferToken, transfer2.noteUpdates.first.serverId);
  final List<int> bytes4 = await _download(_account2, transfer2.transferToken, transfer2.noteUpdates[1].serverId);
  expect(utf8.decode(bytes3), "c2_1_changed_text");
  expect(utf8.decode(bytes4), "c2_2_text");

  Logger.info("finishing transfers and add notes");
  await _finishTransfer(_account1, transfer1.transferToken, shouldCancel: false);
  await _finishTransfer(_account2, transfer2.transferToken, shouldCancel: false);
  _addNotes(_account1, transfer1.noteUpdates);
  _addNotes(_account2, transfer2.noteUpdates);
}

Future<void> _fourthTransfer() async {
  Logger.info("starting third transfer which should do nothing");
  final StartNoteTransferResponse transfer1 = await _startTransfer(_account1);
  final StartNoteTransferResponse transfer2 = await _startTransfer(_account2);

  expect(transfer1.noteUpdates.isEmpty, true);
  expect(transfer2.noteUpdates.isEmpty, true);

  Logger.info("finishing transfers");
  await _finishTransfer(_account1, transfer1.transferToken, shouldCancel: false);
  await _finishTransfer(_account2, transfer2.transferToken, shouldCancel: false);
}

void _addNotes(ServerAccountModel account, List<NoteUpdateModel> noteUpdates) {
  for (final NoteUpdateModel noteUpdate in noteUpdates) {
    account.noteInfoList.add(NoteInfoModel(
      id: noteUpdate.serverId,
      encFileName: noteUpdate.newEncFileName ?? "",
      lastEdited: noteUpdate.newLastEdited,
    ));
  }
}

void _expectClientNeedsNew(NoteUpdateModel noteUpdate) {
  expect(noteUpdate.noteTransferStatus, NoteTransferStatus.CLIENT_NEEDS_NEW);
}

DateTime _now = DateTime.now();

Future<AccountChangePasswordResponse> _changePasswordOfTestAccount(ServerAccountModel accountWithChangedPassword) async {
  fetchCurrentSessionTokenMock.sessionTokenOverride = accountWithChangedPassword.sessionToken!;
  final Map<String, dynamic> json = await restClient.sendJsonRequest(
    endpoint: Endpoints.ACCOUNT_CHANGE_PASSWORD,
    bodyData: AccountChangePasswordRequest(
      newPasswordHash: accountWithChangedPassword.passwordHash,
      newEncryptedDataKey: accountWithChangedPassword.encryptedDataKey,
    ).toJson(),
  );
  return AccountChangePasswordResponse.fromJson(json);
}

Future<AccountLoginResponse> _loginToAccount(ServerAccountModel account) async {
  final Map<String, dynamic> json = await restClient.sendJsonRequest(
    endpoint: Endpoints.ACCOUNT_LOGIN,
    bodyData: AccountLoginRequest(
      username: account.username,
      passwordHash: account.passwordHash,
      createAccountToken: serverConfigMock.createAccountToken,
    ).toJson(),
  );
  return AccountLoginResponse.fromJson(json);
}

Future<StartNoteTransferResponse> _startTransfer(ServerAccountModel account) async {
  fetchCurrentSessionTokenMock.sessionTokenOverride = account.sessionToken!;
  final ResponseData data = await restClient.sendRequest(
    endpoint: Endpoints.NOTE_TRANSFER_START,
    bodyData: StartNoteTransferRequest(clientNotes: List<NoteInfoModel>.from(account.noteInfoList)).toJson(),
  );
  return StartNoteTransferResponse.fromJson(data.json!);
}

Future<void> _upload(ServerAccountModel account, String? transferToken, int? serverId, List<int>? bytes) async {
  fetchCurrentSessionTokenMock.sessionTokenOverride = account.sessionToken!;
  final Map<String, String> queryParams = <String, String>{};
  if (transferToken != null) {
    queryParams[RestJsonParameter.TRANSFER_TOKEN] = transferToken;
  }
  if (serverId != null) {
    queryParams[RestJsonParameter.TRANSFER_NOTE_ID] = serverId.toString();
  }
  await restClient.sendRequest(
    endpoint: Endpoints.NOTE_UPLOAD,
    queryParams: queryParams,
    bodyData: bytes,
  );
}

Future<void> _finishTransfer(ServerAccountModel account, String? transferToken, {required bool shouldCancel}) async {
  fetchCurrentSessionTokenMock.sessionTokenOverride = account.sessionToken!;
  final Map<String, String> queryParams = <String, String>{};
  if (transferToken != null) {
    queryParams[RestJsonParameter.TRANSFER_TOKEN] = transferToken;
  }
  await restClient.sendRequest(
    endpoint: Endpoints.NOTE_TRANSFER_FINISH,
    queryParams: queryParams,
    bodyData: FinishNoteTransferRequest(shouldCancel: shouldCancel).toJson(),
  );
}

Future<List<int>> _download(ServerAccountModel account, String? transferToken, int? serverId) async {
  fetchCurrentSessionTokenMock.sessionTokenOverride = account.sessionToken!;
  final Map<String, String> queryParams = <String, String>{};
  if (transferToken != null) {
    queryParams[RestJsonParameter.TRANSFER_TOKEN] = transferToken;
  }
  if (serverId != null) {
    queryParams[RestJsonParameter.TRANSFER_NOTE_ID] = serverId.toString();
  }
  final ResponseData response = await restClient.sendRequest(
    endpoint: Endpoints.NOTE_DOWNLOAD,
    queryParams: queryParams,
  );
  return response.bytes!;
}
