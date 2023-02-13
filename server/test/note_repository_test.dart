import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:server/data/models/server_account_model.dart';
import 'package:server/domain/entities/server_account.dart';
import 'package:shared/core/constants/endpoints.dart';
import 'package:shared/core/constants/error_codes.dart';
import 'package:shared/core/constants/rest_json_parameter.dart';
import 'package:shared/core/enums/note_transfer_status.dart';
import 'package:shared/core/exceptions/exceptions.dart';
import 'package:shared/core/network/response_data.dart';
import 'package:shared/core/utils/logger/logger.dart';
import 'package:shared/data/dtos/notes/finish_note_request.dart';
import 'package:shared/data/dtos/notes/start_note_transfer_request.dart';
import 'package:shared/data/dtos/notes/start_note_transfer_response.dart';
import 'package:shared/data/models/note_info_model.dart';
import 'package:shared/data/models/note_update_model.dart';
import 'package:shared/domain/entities/note_info.dart';
import 'package:shared/domain/entities/note_update.dart';
import 'package:test/test.dart';

import 'helper/test_helpers.dart';

// test for the specific note updating functions. These tests here can not cover every single permutation of possible user
// actions!

late ServerAccountModel _account;

const int _serverPort = 8193;

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

  group("note repository tests: ", () {
    group("calls without authentication: ", _testAuthentication);
    group("start transfer: ", _testStartTransfer);
    group("upload note: ", _testUploadNote);
    group("finish transfer: ", _testFinishTransfer);
  });

  //todo: download and start need to be tested again at the end when finish and upload is executed and added some files!
}

/// initializes the account to use for the tests
Future<void> _initAccount() async {
  _account = await createAndLoginToTestAccount(0);
  sessionServiceMock.sessionTokenOverride = _account.sessionToken!.token;
}

void _testAuthentication() {
  test("throw unauthorized exception when accessing note transfer start with no account", () async {
    expect(() async {
      await restClient.sendRequest(
        endpoint: Endpoints.NOTE_TRANSFER_START,
        bodyData: <String, dynamic>{},
      );
    }, throwsA((Object e) => e is ServerException && e.message == ErrorCodes.httpStatusWith(HttpStatus.unauthorized)));
  });

  test("throw unauthorized exception when accessing note download with no account", () async {
    expect(() async {
      await restClient.sendRequest(
        endpoint: Endpoints.NOTE_DOWNLOAD,
      );
    }, throwsA((Object e) => e is ServerException && e.message == ErrorCodes.httpStatusWith(HttpStatus.unauthorized)));
  });

  test("throw unauthorized exception when accessing note upload with no account", () async {
    expect(() async {
      await restClient.sendRequest(
        endpoint: Endpoints.NOTE_UPLOAD,
        bodyData: <String, dynamic>{},
      );
    }, throwsA((Object e) => e is ServerException && e.message == ErrorCodes.httpStatusWith(HttpStatus.unauthorized)));
  });

  test("throw unauthorized exception when accessing note transfer finish with no account", () async {
    expect(() async {
      await restClient.sendRequest(
        endpoint: Endpoints.NOTE_TRANSFER_FINISH,
        bodyData: <String, dynamic>{},
      );
    }, throwsA((Object e) => e is ServerException && e.message == ErrorCodes.httpStatusWith(HttpStatus.unauthorized)));
  });

  test("throw unauthorized exception when accessing note download with no transfer token", () async {
    expect(() async {
      await _initAccount(); // create an account to use
      await restClient.sendRequest(
        endpoint: Endpoints.NOTE_DOWNLOAD,
      );
    }, throwsA((Object e) => e is ServerException && e.message == ErrorCodes.SERVER_INVALID_NOTE_TRANSFER_TOKEN));
  });

  test("throw unauthorized exception when accessing note upload with no transfer token", () async {
    expect(() async {
      await _initAccount(); // create an account to use
      await restClient.sendRequest(
        endpoint: Endpoints.NOTE_UPLOAD,
        bodyData: <int>[1, 2, 3, 4],
      );
    }, throwsA((Object e) => e is ServerException && e.message == ErrorCodes.SERVER_INVALID_NOTE_TRANSFER_TOKEN));
  });

  test("throw unauthorized exception when accessing note transfer finish with no transfer token", () async {
    expect(() async {
      await _initAccount(); // create an account to use
      await restClient.sendRequest(
        endpoint: Endpoints.NOTE_TRANSFER_FINISH,
        bodyData: <String, dynamic>{},
      );
    }, throwsA((Object e) => e is ServerException && e.message == ErrorCodes.SERVER_INVALID_NOTE_TRANSFER_TOKEN));
  });

  test("throw unauthorized exception when accessing note download with an empty transfer token", () async {
    expect(() async {
      await _initAccount(); // create an account to use
      await restClient.sendRequest(
        endpoint: Endpoints.NOTE_DOWNLOAD,
        queryParams: <String, String>{RestJsonParameter.TRANSFER_TOKEN: ""},
      );
    }, throwsA((Object e) => e is ServerException && e.message == ErrorCodes.SERVER_INVALID_NOTE_TRANSFER_TOKEN));
  });

  test("throw unauthorized exception when accessing note upload with an empty transfer token", () async {
    expect(() async {
      await _initAccount(); // create an account to use
      await restClient.sendRequest(
        endpoint: Endpoints.NOTE_UPLOAD,
        queryParams: <String, String>{RestJsonParameter.TRANSFER_TOKEN: ""},
        bodyData: <int>[1, 2, 3, 4],
      );
    }, throwsA((Object e) => e is ServerException && e.message == ErrorCodes.SERVER_INVALID_NOTE_TRANSFER_TOKEN));
  });

  test("throw unauthorized exception when accessing note transfer finish with an empty transfer token", () async {
    expect(() async {
      await _initAccount(); // create an account to use
      await restClient.sendRequest(
        endpoint: Endpoints.NOTE_TRANSFER_FINISH,
        queryParams: <String, String>{RestJsonParameter.TRANSFER_TOKEN: ""},
        bodyData: <String, dynamic>{},
      );
    }, throwsA((Object e) => e is ServerException && e.message == ErrorCodes.SERVER_INVALID_NOTE_TRANSFER_TOKEN));
  });
}

void _testStartTransfer() {
  setUp(() async {
    await _initAccount(); // create an account to use
  });

  test("An empty start transfer should just return the correct transfer token with an empty list", () async {
    final StartNoteTransferResponse response = await _startTransfer(<NoteInfoModel>[]);
    expect(response.transferToken.isEmpty, false, reason: "token not empty");
    expect(response.noteUpdates.isEmpty, true, reason: "transfers empty");
    expect(noteRepository.getReadOnlyNoteTransfers().isEmpty, false, reason: "server transfers not empty");
  });

  test("Client and server notes should get compared and match the prepared note update list ", () async {
    final List<NoteUpdate> noteUpdates = await noteRepository.compareClientAndServerNotes(_clientList1, _serverList1);
    expect(jsonEncode(List<NoteUpdateModel>.from(noteUpdates)), jsonEncode(_updateList1));
  });

  test("A start request with a client id should return the correct update", () async {
    final StartNoteTransferResponse response =
        await _startTransfer(<NoteInfoModel>[NoteInfoModel(id: -1, encFileName: "c1", lastEdited: _now)]);
    final NoteUpdateModel matchingUpdate = NoteUpdateModel(
        clientId: -1,
        serverId: 1,
        newEncFileName: "c1",
        newLastEdited: _now,
        noteTransferStatus: NoteTransferStatus.SERVER_NEEDS_NEW);

    expect(response.transferToken.isEmpty, false, reason: "token not empty");
    expect(jsonEncode(response.noteUpdates), jsonEncode(<NoteUpdateModel>[matchingUpdate]), reason: "update matches");
  });

  test("A start request with a server id that is not contained in the server account should throw an exception", () async {
    expect(() async {
      await _startTransfer(<NoteInfoModel>[NoteInfoModel(id: 1, encFileName: "c1", lastEdited: _now)]);
    }, throwsA((Object e) => e is ServerException && e.message == ErrorCodes.SERVER_INVALID_REQUEST_VALUES));
  });
}

void _testUploadNote() {
  setUp(() async {
    await _initAccount(); // create an account to use
  });

  test("An upload request with an invalid transfer token should throw an exception ", () async {
    await _startTransfer(<NoteInfoModel>[NoteInfoModel(id: -1, encFileName: "c1", lastEdited: _now)]);
    expect(() async {
      await _upload("_invalid_token_912830958891023905980129803895099182", -1, <int>[1, 2]);
    }, throwsA((Object e) => e is ServerException && e.message == ErrorCodes.SERVER_INVALID_NOTE_TRANSFER_TOKEN));
  });

  test("An upload request with no bytes should throw an exception ", () async {
    final StartNoteTransferResponse response =
        await _startTransfer(<NoteInfoModel>[NoteInfoModel(id: -1, encFileName: "c1", lastEdited: _now)]);
    expect(() async {
      await _upload(response.transferToken, -1, null);
    }, throwsA((Object e) => e is ServerException && e.message == ErrorCodes.SERVER_INVALID_REQUEST_VALUES));
  });

  test("An upload request with empty bytes should throw an exception ", () async {
    final StartNoteTransferResponse response =
        await _startTransfer(<NoteInfoModel>[NoteInfoModel(id: -1, encFileName: "c1", lastEdited: _now)]);
    expect(() async {
      await _upload(response.transferToken, -1, <int>[]);
    }, throwsA((Object e) => e is ServerException && e.message == ErrorCodes.SERVER_INVALID_REQUEST_VALUES));
  });

  test("An upload request with no client id should throw an exception ", () async {
    final StartNoteTransferResponse response =
        await _startTransfer(<NoteInfoModel>[NoteInfoModel(id: -1, encFileName: "c1", lastEdited: _now)]);
    expect(() async {
      await _upload(response.transferToken, null, <int>[1, 2]);
    }, throwsA((Object e) => e is ServerException && e.message == ErrorCodes.SERVER_INVALID_REQUEST_VALUES));
  });

  test("An upload request with a client id should throw an exception ", () async {
    final StartNoteTransferResponse response =
        await _startTransfer(<NoteInfoModel>[NoteInfoModel(id: -1, encFileName: "c1", lastEdited: _now)]);
    expect(() async {
      await _upload(response.transferToken, -1, <int>[1, 2]);
    }, throwsA((Object e) => e is ServerException && e.message == ErrorCodes.SERVER_INVALID_REQUEST_VALUES));
  });

  test("An upload request with an invalid server id should throw an exception ", () async {
    final StartNoteTransferResponse response =
        await _startTransfer(<NoteInfoModel>[NoteInfoModel(id: -1, encFileName: "c1", lastEdited: _now)]);
    expect(() async {
      await _upload(response.transferToken, 1010, <int>[1, 2]);
    }, throwsA((Object e) => e is ServerException && e.message == ErrorCodes.SERVER_INVALID_REQUEST_VALUES));
  });

  test("An upload request with correct values should not instantly create a file", () async {
    final StartNoteTransferResponse response =
        await _startTransfer(<NoteInfoModel>[NoteInfoModel(id: -1, encFileName: "c1", lastEdited: _now)]);
    expect(response.noteUpdates.first.serverId, 1, reason: "note transfer should have serverId 1");
    await _upload(response.transferToken, 1, <int>[1, 2, 3, 4, 5]);
    expect(() async {
      await noteDataSource.loadNoteData(1);
    }, throwsA((Object e) => e is ServerException && e.message == ErrorCodes.FILE_NOT_FOUND));
  });

  test("An upload request with correct values should succeed twice", () async {
    final StartNoteTransferResponse response =
        await _startTransfer(<NoteInfoModel>[NoteInfoModel(id: -1, encFileName: "c1", lastEdited: _now)]);
    expect(response.noteUpdates.first.serverId, 1, reason: "note transfer should have serverId 1");
    final List<int> bytes = <int>[1, 2, 3, 4, 5];

    await _upload(response.transferToken, 1, bytes);
    await _upload(response.transferToken, 1, bytes); //should not change anything
    await noteDataSource.replaceNoteDataWithTempData(1, response.transferToken);
    final List<int> newBytes = await noteDataSource.loadNoteData(1);
    expect(jsonEncode(bytes), jsonEncode(newBytes), reason: "uploaded bytes should match");
  });
}

void _testFinishTransfer() {
  setUp(() async {
    await _initAccount(); // create an account to use
  });

  test("A finish request with an invalid transfer token should throw an exception ", () async {
    await _startTransfer(<NoteInfoModel>[NoteInfoModel(id: -1, encFileName: "c1", lastEdited: _now)]);
    expect(() async {
      await _finishTransfer("_invalid_token_912830958891023905980129803895099182", shouldCancel: false);
    }, throwsA((Object e) => e is ServerException && e.message == ErrorCodes.SERVER_INVALID_NOTE_TRANSFER_TOKEN));
  });

  test("A finish request with correct values should succeed", () async {
    final StartNoteTransferResponse response =
        await _startTransfer(<NoteInfoModel>[NoteInfoModel(id: -1, encFileName: "c1", lastEdited: _now)]);
    final List<int> bytes = <int>[1, 2, 3, 4, 5];
    await _upload(response.transferToken, 1, bytes);

    await _finishTransfer(response.transferToken, shouldCancel: false);

    final ServerAccount? account = await accountRepository.getAccountBySessionToken(sessionServiceMock.sessionTokenOverride);
    expect(account?.noteInfoList.length, 1, reason: "server account should have 1 note");
    expect(account?.noteInfoList.first, NoteInfoModel(id: 1, encFileName: "c1", lastEdited: _now),
        reason: "note info should match");

    final List<int> newBytes = await noteDataSource.loadNoteData(1);
    expect(jsonEncode(bytes), jsonEncode(newBytes), reason: "uploaded bytes should match");
  });

  test("A finish request with no bytes should also succeed", () async {
    final StartNoteTransferResponse response =
        await _startTransfer(<NoteInfoModel>[NoteInfoModel(id: -1, encFileName: "c1", lastEdited: _now)]);
    await _finishTransfer(response.transferToken, shouldCancel: false);

    final ServerAccount? account = await accountRepository.getAccountBySessionToken(sessionServiceMock.sessionTokenOverride);
    expect(account?.noteInfoList.length, 1, reason: "server account should have 1 note");
    expect(account?.noteInfoList.first, NoteInfoModel(id: 1, encFileName: "c1", lastEdited: _now),
        reason: "note info should match");
    expect(() async {
      await noteDataSource.loadNoteData(1);
    }, throwsA((Object e) => e is ServerException && e.message == ErrorCodes.FILE_NOT_FOUND), reason: "file not found");
  });

  test("A finish request with no changes should also succeed", () async {
    final StartNoteTransferResponse response = await _startTransfer(<NoteInfoModel>[]);
    await _finishTransfer(response.transferToken, shouldCancel: false);

    final ServerAccount? account = await accountRepository.getAccountBySessionToken(sessionServiceMock.sessionTokenOverride);
    expect(account?.noteInfoList.length, 0, reason: "server account should have no notes");
    expect(() async {
      await noteDataSource.loadNoteData(1);
    }, throwsA((Object e) => e is ServerException && e.message == ErrorCodes.FILE_NOT_FOUND), reason: "file not found");
  });

  test("A cancelled finish request should not change anything", () async {
    final StartNoteTransferResponse response =
        await _startTransfer(<NoteInfoModel>[NoteInfoModel(id: -1, encFileName: "c1", lastEdited: _now)]);
    final List<int> bytes = <int>[1, 2, 3, 4, 5];
    await _upload(response.transferToken, 1, bytes);
    await _finishTransfer(response.transferToken, shouldCancel: true);

    final ServerAccount? account = await accountRepository.getAccountBySessionToken(sessionServiceMock.sessionTokenOverride);
    expect(account?.noteInfoList.length, 0, reason: "server account should have 0 notes");
    expect(() async {
      await noteDataSource.loadNoteData(1);
    }, throwsA((Object e) => e is ServerException && e.message == ErrorCodes.FILE_NOT_FOUND), reason: "file not found");
  });

  test("A finish request should cancel a different transfer", () async {
    final StartNoteTransferResponse transfer1 =
        await _startTransfer(<NoteInfoModel>[NoteInfoModel(id: -1, encFileName: "c2", lastEdited: _now)]);
    final StartNoteTransferResponse transfer2 =
        await _startTransfer(<NoteInfoModel>[NoteInfoModel(id: -1, encFileName: "c3", lastEdited: _now)]);
    expect(transfer2.noteUpdates.length, 1, reason: "only one note update");
    expect(transfer2.noteUpdates.first.serverId, 2, reason: "serverId should be unique, so 2");

    final List<int> bytes = <int>[1, 2, 3, 4, 5];
    await _upload(transfer1.transferToken, transfer1.noteUpdates.first.serverId, bytes);
    await _upload(transfer2.transferToken, transfer2.noteUpdates.first.serverId, bytes.sublist(1));

    await _finishTransfer(transfer1.transferToken, shouldCancel: false);
    expect(() async {
      await _finishTransfer(transfer2.transferToken, shouldCancel: false);
    }, throwsA((Object e) => e is ServerException && e.message == ErrorCodes.SERVER_INVALID_NOTE_TRANSFER_TOKEN),
        reason: "cancelled");

    final ServerAccount? account = await accountRepository.getAccountBySessionToken(sessionServiceMock.sessionTokenOverride);
    expect(account?.noteInfoList.length, transfer1.noteUpdates.first.serverId, reason: "server account should have 1 note");
    expect(account?.noteInfoList.first, NoteInfoModel(id: 1, encFileName: "c2", lastEdited: _now),
        reason: "note info should match");

    final List<int> newBytes = await noteDataSource.loadNoteData(1);
    expect(jsonEncode(bytes), jsonEncode(newBytes), reason: "uploaded bytes should match");
  });

  test("A cancelled finish request should not cancel a different transfer", () async {
    final StartNoteTransferResponse transfer1 =
        await _startTransfer(<NoteInfoModel>[NoteInfoModel(id: -1, encFileName: "c2", lastEdited: _now)]);
    final StartNoteTransferResponse transfer2 =
        await _startTransfer(<NoteInfoModel>[NoteInfoModel(id: -1, encFileName: "c3", lastEdited: _now)]);

    final List<int> bytes = <int>[1, 2, 3, 4, 5];
    await _upload(transfer1.transferToken, transfer1.noteUpdates.first.serverId, bytes);
    await _upload(transfer2.transferToken, transfer2.noteUpdates.first.serverId, bytes.sublist(1));

    await _finishTransfer(transfer2.transferToken, shouldCancel: true);
    await _finishTransfer(transfer1.transferToken, shouldCancel: false);

    final ServerAccount? account = await accountRepository.getAccountBySessionToken(sessionServiceMock.sessionTokenOverride);
    expect(account?.noteInfoList.length, transfer1.noteUpdates.first.serverId, reason: "server account should have 1 note");
    expect(account?.noteInfoList.first, NoteInfoModel(id: 1, encFileName: "c2", lastEdited: _now),
        reason: "note info should match");

    final List<int> newBytes = await noteDataSource.loadNoteData(1);
    expect(jsonEncode(bytes), jsonEncode(newBytes), reason: "uploaded bytes should match");
  });
}

Future<StartNoteTransferResponse> _startTransfer(List<NoteInfoModel> clientNotes) async {
  final ResponseData data = await restClient.sendRequest(
    endpoint: Endpoints.NOTE_TRANSFER_START,
    bodyData: StartNoteTransferRequest(clientNotes: clientNotes).toJson(),
  );
  return StartNoteTransferResponse.fromJson(data.json!);
}

Future<void> _upload(String? transferToken, int? clientId, List<int>? bytes) async {
  final Map<String, String> queryParams = <String, String>{};
  if (transferToken != null) {
    queryParams[RestJsonParameter.TRANSFER_TOKEN] = transferToken;
  }
  if (clientId != null) {
    queryParams[RestJsonParameter.TRANSFER_NOTE_ID] = clientId.toString();
  }
  await restClient.sendRequest(
    endpoint: Endpoints.NOTE_UPLOAD,
    queryParams: queryParams,
    bodyData: bytes,
  );
}

Future<void> _finishTransfer(String? transferToken, {required bool shouldCancel}) async {
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

DateTime _now = DateTime.now();

List<NoteInfoModel> get _clientList1 => <NoteInfoModel>[
      NoteInfoModel(id: -10, encFileName: "c10", lastEdited: _now.subtract(const Duration(seconds: 1))),
      NoteInfoModel(id: -20, encFileName: "c20", lastEdited: _now.subtract(const Duration(days: 10))),
      NoteInfoModel(id: 11, encFileName: "c11", lastEdited: _now.subtract(const Duration(days: 1))),
      NoteInfoModel(id: 12, encFileName: "c12", lastEdited: _now.subtract(const Duration(days: 2))),
      NoteInfoModel(id: 13, encFileName: "c13", lastEdited: _now.subtract(const Duration(days: 1))),
      NoteInfoModel(id: 14, encFileName: "c14", lastEdited: _now.subtract(const Duration(days: 2))),
      NoteInfoModel(id: 15, encFileName: "c15", lastEdited: _now.subtract(const Duration(days: 1))),
      NoteInfoModel(id: 16, encFileName: "c16", lastEdited: _now.subtract(const Duration(days: 1))),
      NoteInfoModel(id: 17, encFileName: "c11", lastEdited: _now.subtract(const Duration(days: 2))),
    ];

List<NoteInfoModel> get _serverList1 => <NoteInfoModel>[
      NoteInfoModel(id: 11, encFileName: "c11", lastEdited: _now.subtract(const Duration(days: 1))),
      NoteInfoModel(id: 12, encFileName: "s12", lastEdited: _now.subtract(const Duration(days: 1))),
      NoteInfoModel(id: 13, encFileName: "s13", lastEdited: _now.subtract(const Duration(days: 2))),
      NoteInfoModel(id: 14, encFileName: "c14", lastEdited: _now.subtract(const Duration(days: 1))),
      NoteInfoModel(id: 15, encFileName: "c15", lastEdited: _now.subtract(const Duration(days: 2))),
      NoteInfoModel(id: 16, encFileName: "s16", lastEdited: _now.subtract(const Duration(days: 1))),
      NoteInfoModel(id: 17, encFileName: "c12", lastEdited: _now.subtract(const Duration(days: 1))),
      NoteInfoModel(id: 21, encFileName: "s21", lastEdited: _now.subtract(const Duration(seconds: 1))),
      NoteInfoModel(id: 20, encFileName: "s20", lastEdited: _now.subtract(const Duration(days: 10))),
    ];

List<NoteUpdateModel> get _updateList1 => <NoteUpdateModel>[
      NoteUpdateModel(
        clientId: -20,
        serverId: 1,
        newEncFileName: "c20",
        newLastEdited: _now.subtract(const Duration(days: 10)),
        noteTransferStatus: NoteTransferStatus.SERVER_NEEDS_NEW,
      ),
      NoteUpdateModel(
        clientId: -10,
        serverId: 2,
        newEncFileName: "c10",
        newLastEdited: _now.subtract(const Duration(seconds: 1)),
        noteTransferStatus: NoteTransferStatus.SERVER_NEEDS_NEW,
      ),
      NoteUpdateModel(
        clientId: 12,
        serverId: 12,
        newEncFileName: "s12",
        newLastEdited: _now.subtract(const Duration(days: 1)),
        noteTransferStatus: NoteTransferStatus.CLIENT_NEEDS_UPDATE,
      ),
      NoteUpdateModel(
        clientId: 13,
        serverId: 13,
        newEncFileName: "c13",
        newLastEdited: _now.subtract(const Duration(days: 1)),
        noteTransferStatus: NoteTransferStatus.SERVER_NEEDS_UPDATE,
      ),
      NoteUpdateModel(
        clientId: 14,
        serverId: 14,
        newEncFileName: null,
        newLastEdited: _now.subtract(const Duration(days: 1)),
        noteTransferStatus: NoteTransferStatus.CLIENT_NEEDS_UPDATE,
      ),
      NoteUpdateModel(
        clientId: 15,
        serverId: 15,
        newEncFileName: null,
        newLastEdited: _now.subtract(const Duration(days: 1)),
        noteTransferStatus: NoteTransferStatus.SERVER_NEEDS_UPDATE,
      ),
      NoteUpdateModel(
        clientId: 17,
        serverId: 17,
        newEncFileName: "c12",
        newLastEdited: _now.subtract(const Duration(days: 1)),
        noteTransferStatus: NoteTransferStatus.CLIENT_NEEDS_UPDATE,
      ),
      NoteUpdateModel(
        clientId: 20,
        serverId: 20,
        newEncFileName: "s20",
        newLastEdited: _now.subtract(const Duration(days: 10)),
        noteTransferStatus: NoteTransferStatus.CLIENT_NEEDS_NEW,
      ),
      NoteUpdateModel(
        clientId: 21,
        serverId: 21,
        newEncFileName: "s21",
        newLastEdited: _now.subtract(const Duration(seconds: 1)),
        noteTransferStatus: NoteTransferStatus.CLIENT_NEEDS_NEW,
      ),
    ];
