import 'package:shared/core/enums/note_type.dart';
import 'package:shared/data/models/model.dart';
import 'package:shared/domain/entities/note_info.dart';

class NoteInfoModel extends NoteInfo implements Model {
  static const String JSON_ID = "JSON_ID";
  static const String JSON_ENC_FILE_NAME = "JSON_ENC_FILE_NAME";
  static const String JSON_LAST_EDITED = "JSON_LAST_EDITED";
  static const String JSON_NOTE_TYPE = "JSON_NOTE_TYPE";

  NoteInfoModel({required super.id, required super.encFileName, required super.lastEdited, required super.noteType});

  @override
  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      JSON_ID: id,
      JSON_ENC_FILE_NAME: encFileName,
      JSON_LAST_EDITED: lastEdited.toIso8601String(),
      JSON_NOTE_TYPE: noteType.index,
    };
  }

  factory NoteInfoModel.fromJson(Map<String, dynamic> json) {
    return NoteInfoModel(
      id: (json[JSON_ID] as num).toInt(),
      encFileName: json[JSON_ENC_FILE_NAME] as String,
      lastEdited: DateTime.parse(json[JSON_LAST_EDITED] as String),
      noteType: NoteType.values.elementAt(json[JSON_NOTE_TYPE] as int),
    );
  }

  factory NoteInfoModel.fromNoteInfo(NoteInfo entity) {
    if (entity is NoteInfoModel) {
      return entity;
    }
    return NoteInfoModel(
      encFileName: entity.encFileName,
      id: entity.id,
      lastEdited: entity.lastEdited,
      noteType: entity.noteType,
    );
  }

  /// Overrides the method of the entity
  @override
  NoteInfoModel copyWith({int? newId, String? newEncFileName, DateTime? newLastEdited, NoteType? newNoteType}) {
    return NoteInfoModel(
      id: newId ?? id,
      encFileName: newEncFileName ?? encFileName,
      lastEdited: newLastEdited ?? lastEdited,
      noteType: newNoteType ?? noteType,
    );
  }
}
