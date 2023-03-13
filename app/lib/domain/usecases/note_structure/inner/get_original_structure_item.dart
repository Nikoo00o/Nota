import 'package:app/domain/entities/structure_folder.dart';
import 'package:app/domain/entities/structure_item.dart';
import 'package:app/domain/entities/structure_note.dart';
import 'package:app/domain/repositories/note_structure_repository.dart';
import 'package:app/domain/usecases/account/get_logged_in_account.dart';
import 'package:app/domain/usecases/note_structure/change_current_structure_item.dart';
import 'package:app/domain/usecases/note_structure/create_structure_item.dart';
import 'package:app/domain/usecases/note_structure/delete_current_structure_item.dart';
import 'package:app/domain/usecases/note_structure/finish_move_structure_item.dart';
import 'package:app/domain/usecases/note_structure/navigation/get_current_structure_item.dart';
import 'package:app/domain/usecases/note_structure/inner/update_note_structure.dart';
import 'package:app/domain/usecases/note_transfer/inner/fetch_new_note_structure.dart';
import 'package:shared/core/constants/error_codes.dart';
import 'package:shared/core/exceptions/exceptions.dart';
import 'package:shared/core/utils/logger/logger.dart';
import 'package:shared/domain/usecases/usecase.dart';

/// This returns a reference to the original item in the [NoteStructureRepository.root] folder that matches the
/// [NoteStructureRepository.currentItem]! So the returned item will always have root as top level folder, where the
/// current item can have either recent, or root as parent folder.
///
/// This should always be called when the current item should be modified AND you always have to call
/// [UpdateNoteStructure] after you are done with your modifications with the original item reference, so that the current
/// item will be updated!
///
/// This is called at the start of each use case that changes the structure like [CreateStructureItem],
/// [FinishMoveStructureItem], [ChangeCurrentStructureItem], [DeleteCurrentStructureItem]
///
/// For read only access, use [GetCurrentStructureItem]!
///
/// This will return [NoteStructureRepository.root] itself if the current item is recent, or move!
///
/// This can call the use case [FetchNewNoteStructure] if there is no note structure cached.
///
/// This can throw the exceptions of [GetLoggedInAccount], but perform no additional input validation!
class GetOriginalStructureItem extends UseCase<StructureItem, NoParams> {
  final NoteStructureRepository noteStructureRepository;
  final FetchNewNoteStructure fetchNewNoteStructure;

  const GetOriginalStructureItem({
    required this.noteStructureRepository,
    required this.fetchNewNoteStructure,
  });

  @override
  Future<StructureItem> execute(NoParams params) async {
    if (noteStructureRepository.root == null) {
      await fetchNewNoteStructure.call(const NoParams());
    }
    final StructureItem? item = noteStructureRepository.currentItem;

    if (item is StructureFolder) {
      if (item.isRecent || item.isMove) {
        Logger.verbose("The current original item is recent");
        return noteStructureRepository.root!;
      }
      final StructureFolder? folder = noteStructureRepository.getFolderByPath(item.path, deepCopy: false);
      Logger.debug("Returned the original folder reference:\n$folder");
      return folder!;
    } else if (item is StructureNote) {
      final StructureNote? note = noteStructureRepository.getNoteById(noteId: item.id, useRootAsParent: true);
      Logger.debug("Returned the original note reference:\n$note");
      return note!;
    } else {
      throw UnimplementedError();
    }
  }
}
