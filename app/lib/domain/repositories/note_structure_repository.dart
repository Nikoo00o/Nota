import 'package:app/domain/entities/structure_folder.dart';
import 'package:app/domain/entities/structure_item.dart';
import 'package:app/domain/entities/structure_note.dart';
import 'package:app/domain/usecases/note_structure/inner/update_note_structure.dart';
import 'package:shared/core/constants/error_codes.dart';

abstract class NoteStructureRepository {
  /// Contains the whole note structure with sub folders and notes with this being the top most parent folder.
  ///
  /// This contains the original references that should be used for modifications to the structure items!
  ///
  /// After the use case [UpdateNoteStructure], this will never be null!
  StructureFolder? root;

  /// This will always be updated with a deep copy of the notes of [root], but the children will not include the sub folders!
  ///
  /// [StructureItem.getParent] will always directly return [recent] for the children here.
  ///
  /// After the use case [UpdateNoteStructure], this will never be null!
  ///
  /// This should not be used to modify the structure items!
  StructureFolder? recent;

  /// This is also a top level folder that will be created as a deep copy of the notes of [root] like [recent], but here
  /// the sub folders will not include any files and all sub folders are non modifiable.
  /// This will only be used for the move use cases to select a new target parent folder.
  StructureFolder? moveSelection;

  /// This is the cached source item for the move use cases which will be moved to the selected item on completion!
  StructureItem? moveItemSrc;

  /// This will always be a reference to a child (either note, or folder) of either [root], or [recent].
  ///
  /// The direct parent will always be a folder and the top most parent will be [root], or [recent].
  ///
  /// After the use case [UpdateNoteStructure], this will never be null! By default this starts at [recent].
  StructureItem? currentItem;

  /// Returns a list of references to the top level folders with the following indices:
  ///
  /// [0] = [root]
  ///
  /// [1] = [recent]
  ///
  /// [2] = [moveSelection]
  ///
  /// The [moveSelection] should not be included inside of the menu in the ui.
  List<StructureFolder?> get topLevelFolders;

  /// Can return null if the [noteId] was not contained. Otherwise it returns the matching note with the id.
  ///
  /// If [useRootAsParent] is true, then the top most parent will be [root], otherwise the direct parent will always be
  /// [recent]
  StructureNote? getNoteById({required int noteId, required bool useRootAsParent});

  /// Returns the folder matching to the path and otherwise null if its not found.
  ///
  /// This will always use [root] as the top most parent!
  StructureFolder? getFolderByPath(String path, {required bool deepCopy});

  /// This returns a new unique decremented client note counter.
  ///
  /// This will always be below 0!
  Future<int> getNewClientNoteCounter();
}
