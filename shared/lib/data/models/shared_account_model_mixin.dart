import 'package:shared/data/models/note_info_model.dart';
import 'package:shared/data/models/session_token_model.dart';
import 'package:shared/domain/entities/note_info.dart';
import 'package:shared/domain/entities/shared_account.dart';

/// Mixin used in the models of the sub classes of [SharedAccount] for the json Keys and the [toJsonMixin] helper method
mixin SharedAccountModelMixin on SharedAccount {
  static const String JSON_USER_NAME = "JSON_USER_NAME";
  static const String JSON_PASSWORD_HASH = "JSON_PASSWORD_HASH";
  static const String JSON_SESSION_TOKEN = "JSON_SESSION_TOKEN";
  static const String JSON_ENCRYPTED_DATA_KEY = "JSON_ENCRYPTED_DATA_KEY";
  static const String JSON_NOTE_INFO_LIST = "JSON_NOTE_INFO_LIST";

  /// Returns a json map of the member variables of [SharedAccount]
  Map<String, dynamic> toJsonMixin() {
    SessionTokenModel? sessionTokenModel;
    if (sessionToken != null) {
      sessionTokenModel = SessionTokenModel.fromSessionToken(sessionToken!);
    }

    final List<Map<String, dynamic>> noteInfoJson = List<Map<String, dynamic>>.empty(growable: true);
    for (final NoteInfo entity in noteInfoList) {
      noteInfoJson.add(NoteInfoModel.fromNoteInfo(entity).toJson());
    }

    return <String, dynamic>{
      JSON_USER_NAME: userName,
      JSON_PASSWORD_HASH: passwordHash,
      JSON_SESSION_TOKEN: sessionTokenModel?.toJson(),
      JSON_ENCRYPTED_DATA_KEY: encryptedDataKey,
      JSON_NOTE_INFO_LIST: noteInfoJson,
    };
  }
}
