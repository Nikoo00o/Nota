import 'package:app/domain/entities/structure_folder.dart';
import 'package:app/domain/entities/structure_item.dart';
import 'package:app/domain/entities/structure_note.dart';
import 'package:app/domain/repositories/note_structure_repository.dart';
import 'package:app/domain/usecases/account/get_logged_in_account.dart';
import 'package:app/domain/usecases/note_structure/inner/get_original_structure_item.dart';
import 'package:app/domain/usecases/note_structure/inner/update_note_structure.dart';
import 'package:app/domain/usecases/note_structure/navigation/get_structure_updates_stream.dart';
import 'package:app/domain/usecases/note_transfer/inner/fetch_new_note_structure.dart';
import 'package:shared/core/utils/logger/logger.dart';
import 'package:shared/domain/usecases/usecase.dart';

/// This returns a deep copy of the current selected note structure item [NoteStructureRepository.currentItem]!
/// The parent folder references of the returned item will only be changed if the item is not [NoteStructureRepository.recent]!
///
/// This should always be called after the use case [UpdateNoteStructure] to refresh the GUI after each modification to
/// the note structure. Look at [UpdateNoteStructure] to see when its called!
///
/// This is read only access and can not be used to modify the note structure! For modifications, use
/// [GetOriginalStructureItem]!
///
/// This can call the use case [FetchNewNoteStructure] if there is no note structure cached.
///
/// This can throw the exceptions of [GetLoggedInAccount], but perform no additional input validation!
///
/// As an alternative, you can use [GetStructureUpdatesStream] to receive streamed updates instead!
class GetCurrentStructureItem extends UseCase<StructureItem, NoParams> {
  final NoteStructureRepository noteStructureRepository;
  final FetchNewNoteStructure fetchNewNoteStructure;

  const GetCurrentStructureItem({
    required this.noteStructureRepository,
    required this.fetchNewNoteStructure,
  });

  @override
  Future<StructureItem> execute(NoParams params) async {
    if (noteStructureRepository.root == null) {
      await fetchNewNoteStructure.call(const NoParams());
    }

    final StructureItem? item = noteStructureRepository.currentItem;
    Logger.debug("Returning the current selected structure item as a read only deep copy:\n$item");

    if (item is StructureNote) {
      return item.copyWith();
    } else if (item is StructureFolder) {
      final bool changeParentOfChildren = item.isRecent == false; // don't change the parent of children of recent,
      // because recent has the notes as direct children which have their folder structure as direct parents!
      return item.copyWith(changeParentOfChildren: changeParentOfChildren);
    }
    throw UnimplementedError();
  }
}
