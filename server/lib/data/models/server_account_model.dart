import 'package:server/domain/entities/server_account.dart';
import 'package:shared/core/utils/nullable.dart';
import 'package:shared/data/models/model.dart';
import 'package:shared/data/models/note_info_model.dart';
import 'package:shared/data/models/session_token_model.dart';
import 'package:shared/data/models/shared_account_model_mixin.dart';
import 'package:shared/domain/entities/note_info.dart';
import 'package:shared/domain/entities/session_token.dart';

class ServerAccountModel extends ServerAccount with SharedAccountModelMixin implements Model {
  ServerAccountModel({
    required super.userName,
    required super.passwordHash,
    required super.sessionToken,
    required super.encryptedDataKey,
    required super.noteInfoList,
  });

  @override
  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      ...super.toJsonMixin(),
    };
  }

  factory ServerAccountModel.fromJson(Map<String, dynamic> json) {
    SessionToken? sessionToken;
    if (json[SharedAccountModelMixin.JSON_SESSION_TOKEN] is Map<String, dynamic>) {
      sessionToken = SessionTokenModel.fromJson(json[SharedAccountModelMixin.JSON_SESSION_TOKEN] as Map<String, dynamic>);
    }

    final List<dynamic> noteInfoDynList = json[SharedAccountModelMixin.JSON_NOTE_INFO_LIST] as List<dynamic>;
    final List<NoteInfo> noteInfoList =
        noteInfoDynList.map((dynamic map) => NoteInfoModel.fromJson(map as Map<String, dynamic>)).toList();

    return ServerAccountModel(
      userName: json[SharedAccountModelMixin.JSON_USER_NAME] as String,
      passwordHash: json[SharedAccountModelMixin.JSON_PASSWORD_HASH] as String,
      sessionToken: sessionToken,
      encryptedDataKey: json[SharedAccountModelMixin.JSON_ENCRYPTED_DATA_KEY] as String,
      noteInfoList: noteInfoList,
    );
  }

  factory ServerAccountModel.fromServerAccount(ServerAccount entity) {
    if (entity is ServerAccountModel) {
      return entity;
    }
    return ServerAccountModel(
      userName: entity.userName,
      passwordHash: entity.passwordHash,
      sessionToken: entity.sessionToken,
      encryptedDataKey: entity.encryptedDataKey,
      noteInfoList: entity.noteInfoList,
    );
  }
  
}
