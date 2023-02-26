import 'package:app/domain/entities/structure_folder.dart';
import 'package:app/domain/entities/structure_item.dart';
import 'package:shared/domain/entities/note_info.dart';

/// structure notes will always have a [directParent] folder!
///
/// The decrypted name of a note is the [path] and note the [name]!
///
/// The [id] and [lastModified] are the same as in [NoteInfo]
class StructureNote extends StructureItem {
  /// The noteId
  final int id;

  /// The lastModified timestamp of the note
  @override
  final DateTime lastModified;

  StructureNote({
    required super.name,
    required StructureFolder? directParent,
    required super.canBeModified,
    required this.id,
    required this.lastModified,
  }) : super(directParent: directParent, additionalProperties: <String, Object?>{
          "id": id,
          "lastModified": lastModified,
        });

  /// This just copies the note with the additional values. It does not have to make a deep copy, because all members are
  /// final!
  StructureNote copyWith({
    String? newName,
    StructureFolder? newDirectParent,
    bool? newCanBeModified,
    int? newId,
    DateTime? newLastModified,
  }) {
    return StructureNote(
      name: newName ?? name,
      directParent: newDirectParent ?? directParent,
      canBeModified: newCanBeModified ?? canBeModified,
      id: newId ?? id,
      lastModified: newLastModified ?? lastModified,
    );
  }
}
