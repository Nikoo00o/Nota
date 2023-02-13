import 'package:shared/core/enums/note_transfer_status.dart';
import 'package:shared/data/models/model.dart';
import 'package:shared/domain/entities/note_update.dart';

class NoteUpdateModel extends NoteUpdate implements Model {
  static const String JSON_CLIENT_ID = "JSON_CLIENT_ID";
  static const String JSON_SERVER_ID = "JSON_SERVER_ID";
  static const String JSON_NEW_ENCRYPTED_FILE_NAME = "JSON_NEW_ENCRYPTED_FILE_NAME";
  static const String JSON_NEW_LAST_EDITED = "JSON_NEW_LAST_EDITED";
  static const String JSON_TRANSFER_STATUS = "JSON_TRANSFER_STATUS";

  NoteUpdateModel({
    required super.clientId,
    required super.serverId,
    required super.newEncFileName,
    required super.newLastEdited,
    required super.noteTransferStatus,
  });

  @override
  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      JSON_CLIENT_ID: clientId,
      JSON_SERVER_ID: serverId,
      JSON_NEW_ENCRYPTED_FILE_NAME: newEncFileName,
      JSON_NEW_LAST_EDITED: newLastEdited.toIso8601String(),
      JSON_TRANSFER_STATUS: noteTransferStatus.toString(),
    };
  }

  factory NoteUpdateModel.fromJson(Map<String, dynamic> json) {
    return NoteUpdateModel(
      clientId: (json[JSON_CLIENT_ID] as num).toInt(),
      serverId: (json[JSON_SERVER_ID] as num).toInt(),
      newEncFileName: json[JSON_NEW_ENCRYPTED_FILE_NAME] as String,
      newLastEdited: DateTime.parse(json[JSON_NEW_LAST_EDITED] as String),
      noteTransferStatus: NoteTransferStatus.fromString(json[JSON_TRANSFER_STATUS] as String),
    );
  }
}
