import 'package:app/domain/entities/structure_folder.dart';
import 'package:app/domain/entities/structure_item.dart';
import 'package:app/domain/entities/structure_note.dart';
import 'package:app/domain/repositories/note_structure_repository.dart';
import 'package:app/domain/usecases/account/get_logged_in_account.dart';
import 'package:app/domain/usecases/note_structure/update_note_structure.dart';
import 'package:app/domain/usecases/note_transfer/fetch_new_note_structure.dart';
import 'package:shared/core/utils/logger/logger.dart';
import 'package:shared/domain/usecases/usecase.dart';

/// This returns a reference, or a deep copy of the current selected note structure item
/// [NoteStructureRepository.currentItem] depending on the [GetCurrentStructureItemParams].
///
/// This should always be called after the use case [UpdateNoteStructure] to refresh the GUI after each modification to
/// the note structure. Look at [UpdateNoteStructure] to see when its called!
///
/// This can call the use case [FetchNewNoteStructure] if there is no note structure cached.
///
/// This can throw the exceptions of [GetLoggedInAccount], but perform no additional input validation!
class GetCurrentStructureItem extends UseCase<StructureItem, GetCurrentStructureItemParams> {
  final NoteStructureRepository noteStructureRepository;
  final FetchNewNoteStructure fetchNewNoteStructure;

  const GetCurrentStructureItem({
    required this.noteStructureRepository,
    required this.fetchNewNoteStructure,
  });

  @override
  Future<StructureItem> execute(GetCurrentStructureItemParams params) async {
    if (noteStructureRepository.root == null) {
      await fetchNewNoteStructure.call(NoParams());
    }

    final StructureItem? item = noteStructureRepository.currentItem;
    Logger.debug("Returning the current selected structure item:\n$item");

    if (params.deepCopy == false) {
      return item!;
    }

    if (item is StructureNote) {
      return item.copyWith();
    } else if (item is StructureFolder) {
      return item.copyWith(changeParentOfChildren: params.changeParentOfChildren);
    }
    throw UnimplementedError();
  }
}

/// If [deepCopy] is false, then this will return the direct reference of the [NoteStructureRepository.currentItem]!
///
/// If [deepCopy] is true, then [changeParentOfChildren] can be set to true to change the parent of children of a folder
class GetCurrentStructureItemParams {
  final bool deepCopy;
  bool changeParentOfChildren;

  GetCurrentStructureItemParams({required this.deepCopy, this.changeParentOfChildren = false});
}
