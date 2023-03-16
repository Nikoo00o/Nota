import 'dart:convert';
import 'dart:typed_data';
import 'package:app/data/models/client_account_model.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared/data/models/note_info_model.dart';
import 'package:shared/data/models/session_token_model.dart';
import 'package:shared/domain/entities/note_info.dart';
import 'package:shared/domain/entities/session_token.dart';

import '../fixtures/fixture_reader.dart';

void main() {
  group("client account model conversion tests: ", () {
    group("default toJson", () {
      test("empty with dec key to json", () async {
        final String json = jsonEncode(_getEmptyModel(storeDecryptedKey: true));
        expect(json, fixture("empty_account.json", removeFormatting: true));
      });

      test("empty with no key to json", () async {
        final String json = jsonEncode(_getEmptyModel(storeDecryptedKey: false));
        expect(json, fixture("empty_account_no_key.json", removeFormatting: true));
      });

      test("filled with dec key to json", () async {
        final String json = jsonEncode(_getFilledModel(storeDecryptedKey: true));
        expect(json, fixture("filled_account.json", removeFormatting: true));
      });

      test("filled with no key to json", () async {
        final String json = jsonEncode(_getFilledModel(storeDecryptedKey: false));
        expect(json, fixture("filled_account_no_key.json", removeFormatting: true));
      });
    });

    group("default fromJson", () {
      test("empty with dec key from json", () async {
        final Map<String, dynamic> json =
            jsonDecode(fixture("empty_account.json", removeFormatting: true)) as Map<String, dynamic>;
        final ClientAccountModel model = ClientAccountModel.fromJson(json);
        expect(model, _getEmptyModel(storeDecryptedKey: true));
      });

      test("empty with no key from json", () async {
        final Map<String, dynamic> json =
            jsonDecode(fixture("empty_account_no_key.json", removeFormatting: true)) as Map<String, dynamic>;
        final ClientAccountModel model = ClientAccountModel.fromJson(json);
        expect(model, _getEmptyModel(storeDecryptedKey: false));
      });

      test("filled with dec key from json", () async {
        final Map<String, dynamic> json =
            jsonDecode(fixture("filled_account.json", removeFormatting: true)) as Map<String, dynamic>;
        final ClientAccountModel model = ClientAccountModel.fromJson(json);
        expect(model, _getFilledModel(storeDecryptedKey: true));
      });

      test("filled with no key from json", () async {
        final Map<String, dynamic> json =
            jsonDecode(fixture("filled_account_no_key.json", removeFormatting: true)) as Map<String, dynamic>;
        final ClientAccountModel model = ClientAccountModel.fromJson(json);
        expect(model, _getFilledModel(storeDecryptedKey: false));
      });
    });

    test("toJson with entity inside", () async {
      final String json = jsonEncode(_getFilledWithEntityInside());
      expect(json, fixture("filled_account.json", removeFormatting: true));
    });

    test("fromJson with entity inside", () async {
      final Map<String, dynamic> json =
          jsonDecode(fixture("filled_account.json", removeFormatting: true)) as Map<String, dynamic>;
      final ClientAccountModel model = ClientAccountModel.fromJson(json);
      expect(model, _getFilledWithEntityInside());
    });

    test("add a note info model after fromJson", () async {
      final Map<String, dynamic> json =
          jsonDecode(fixture("filled_account.json", removeFormatting: true)) as Map<String, dynamic>;
      final ClientAccountModel model = ClientAccountModel.fromJson(json);
      final NoteInfoModel noteInfo = NoteInfoModel(id: 2, encFileName: "2", lastEdited: DateTime.now());
      model.noteInfoList.add(noteInfo);
      expect(model.noteInfoList.last, noteInfo);
    });

    test("add a note info entity after fromJson", () async {
      final Map<String, dynamic> json =
      jsonDecode(fixture("filled_account.json", removeFormatting: true)) as Map<String, dynamic>;
      final ClientAccountModel model = ClientAccountModel.fromJson(json);
      final NoteInfo noteInfo = NoteInfo(id: 2, encFileName: "2", lastEdited: DateTime.now());
      model.noteInfoList.add(noteInfo);
      expect(model.noteInfoList.last, noteInfo);
    });
  });
}

final DateTime date = DateTime.parse("2023-03-13 21:53:31");

ClientAccountModel _getEmptyModel({required bool storeDecryptedKey}) {
  return ClientAccountModel(
    username: "test",
    passwordHash: "test",
    sessionToken: SessionTokenModel(validTo: date, token: "test"),
    encryptedDataKey: "test",
    noteInfoList: <NoteInfo>[],
    decryptedDataKey: Uint8List.fromList(<int>[]),
    storeDecryptedDataKey: storeDecryptedKey,
    needsServerSideLogin: true,
  );
}

ClientAccountModel _getFilledModel({required bool storeDecryptedKey}) {
  return ClientAccountModel(
    username: "test",
    passwordHash: "test",
    sessionToken: SessionTokenModel(validTo: date, token: "test"),
    encryptedDataKey: "test",
    noteInfoList: <NoteInfo>[NoteInfoModel(id: 1, lastEdited: date, encFileName: "test")],
    decryptedDataKey: Uint8List.fromList(<int>[1, 2, 3, 4]),
    storeDecryptedDataKey: storeDecryptedKey,
    needsServerSideLogin: true,
  );
}

ClientAccountModel _getFilledWithEntityInside() {
  return ClientAccountModel(
    username: "test",
    passwordHash: "test",
    sessionToken: SessionToken(validTo: date, token: "test"),
    encryptedDataKey: "test",
    noteInfoList: <NoteInfo>[NoteInfo(id: 1, lastEdited: date, encFileName: "test")],
    decryptedDataKey: Uint8List.fromList(<int>[1, 2, 3, 4]),
    storeDecryptedDataKey: true,
    needsServerSideLogin: true,
  );
}
