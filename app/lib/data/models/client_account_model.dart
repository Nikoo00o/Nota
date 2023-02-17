import 'dart:typed_data';

import 'package:app/domain/entities/client_account.dart';
import 'package:shared/data/models/model.dart';
import 'package:shared/data/models/note_info_model.dart';
import 'package:shared/data/models/session_token_model.dart';
import 'package:shared/data/models/shared_account_model_mixin.dart';
import 'package:shared/domain/entities/note_info.dart';
import 'package:shared/domain/entities/session_token.dart';

class ClientAccountModel extends ClientAccount with SharedAccountModelMixin implements Model {
  static const String JSON_DECRYPTED_DATA_KEY = "JSON_DECRYPTED_DATA_KEY";
  static const String JSON_STORE_DECRYPTED_DATA_KEY = "JSON_STORE_DECRYPTED_DATA_KEY";

  ClientAccountModel({
    required super.userName,
    required super.passwordHash,
    required super.sessionToken,
    required super.encryptedDataKey,
    required super.noteInfoList,
    required super.decryptedDataKey,
    required super.storeDecryptedDataKey,
  });

  @override
  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      ...super.toJsonMixin(),
      if (storeDecryptedDataKey) JSON_DECRYPTED_DATA_KEY: decryptedDataKey,
      JSON_STORE_DECRYPTED_DATA_KEY: storeDecryptedDataKey,
    };
  }

  factory ClientAccountModel.fromJson(Map<String, dynamic> json) {
    SessionToken? sessionToken;
    if (json[SharedAccountModelMixin.JSON_SESSION_TOKEN] is Map<String, dynamic>) {
      sessionToken = SessionTokenModel.fromJson(json[SharedAccountModelMixin.JSON_SESSION_TOKEN] as Map<String, dynamic>);
    }

    final List<dynamic> noteInfoDynList = json[SharedAccountModelMixin.JSON_NOTE_INFO_LIST] as List<dynamic>;
    final List<NoteInfo> noteInfoList =
        noteInfoDynList.map((dynamic map) => NoteInfoModel.fromJson(map as Map<String, dynamic>)).toList();

    Uint8List? decryptedDataKey;
    if (json.containsKey(JSON_DECRYPTED_DATA_KEY)) {
      final List<dynamic> dynList = json[JSON_DECRYPTED_DATA_KEY] as List<dynamic>;
      decryptedDataKey = Uint8List.fromList(dynList.map((dynamic element) => element as int).toList());
    }

    return ClientAccountModel(
      userName: json[SharedAccountModelMixin.JSON_USER_NAME] as String,
      passwordHash: json[SharedAccountModelMixin.JSON_PASSWORD_HASH] as String,
      sessionToken: sessionToken,
      encryptedDataKey: json[SharedAccountModelMixin.JSON_ENCRYPTED_DATA_KEY] as String,
      noteInfoList: noteInfoList,
      decryptedDataKey: decryptedDataKey,
      storeDecryptedDataKey: json[JSON_STORE_DECRYPTED_DATA_KEY] as bool,
    );
  }

  factory ClientAccountModel.fromServerAccount(ClientAccount entity) {
    if (entity is ClientAccountModel) {
      return entity;
    }
    return ClientAccountModel(
      userName: entity.userName,
      passwordHash: entity.passwordHash,
      sessionToken: entity.sessionToken,
      encryptedDataKey: entity.encryptedDataKey,
      noteInfoList: entity.noteInfoList,
      decryptedDataKey: entity.decryptedDataKey,
      storeDecryptedDataKey: entity.storeDecryptedDataKey,
    );
  }
}
