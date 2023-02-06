import 'package:shared/data/models/model.dart';
import 'package:shared/domain/entities/note_info.dart';

class NoteInfoModel extends NoteInfo implements Model {
  static const String JSON_ID = "JSON_ID";
  static const String JSON_ENC_FILE_NAME = "JSON_ENC_FILE_NAME";
  static const String JSON_LAST_EDITED = "JSON_LAST_EDITED";

  NoteInfoModel({required super.id, required super.encFileName, required super.lastEdited});

  @override
  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      JSON_ID: id,
      JSON_ENC_FILE_NAME: encFileName,
      JSON_LAST_EDITED: lastEdited.toIso8601String(),
    };
  }

  factory NoteInfoModel.fromJson(Map<String, dynamic> json) {
    return NoteInfoModel(
      id: (json[JSON_ID] as num).toInt(),
      encFileName: json[JSON_ENC_FILE_NAME] as String,
      lastEdited: DateTime.parse(json[JSON_LAST_EDITED] as String),
    );
  }

  factory NoteInfoModel.fromNoteInfo(NoteInfo entity) {
    if (entity is NoteInfoModel) {
      return entity;
    }
    return NoteInfoModel(encFileName: entity.encFileName, id: entity.id, lastEdited: entity.lastEdited);
  }
}
