import 'package:app/domain/entities/structure_folder.dart';
import 'package:app/domain/entities/structure_item.dart';
import 'package:app/domain/entities/structure_note.dart';
import 'package:app/domain/usecases/note_structure/update_note_structure.dart';
import 'package:shared/core/constants/error_codes.dart';

abstract class NoteStructureRepository {
  /// Contains the whole note structure with sub folders and notes with this being the top most parent folder.
  ///
  /// After the use case [UpdateNoteStructure], this will never be null!
  StructureFolder? root;

  /// Will be updated with the notes of [root], but the children will not include the sub folders!#
  ///
  /// [StructureItem.getParent] will always directly return [recent] for the children here.
  ///
  /// After the use case [UpdateNoteStructure], this will never be null!
  StructureFolder? recent;

  /// Will be a children (either note, or folder) of either [root], or [recent].
  ///
  /// The direct parent will always be a folder and the top most parent will be [root], or [recent].
  ///
  /// After the use case [UpdateNoteStructure], this will never be null! By default this starts at [recent].
  StructureItem? currentItem;

  /// Can return null if the [noteId] was not contained. Otherwise it returns the matching note with the id.
  ///
  /// If [useRootAsParent] is true, then the top most parent will be [root], otherwise the direct parent will always be
  /// [recent]
  StructureNote? getNoteById({required int noteId, required bool useRootAsParent});

  /// Returns the folder matching to the path and otherwise null if its not found.
  ///
  /// This will always use [root] as the top most parent!
  StructureFolder? getFolderByPath(String path);
}
