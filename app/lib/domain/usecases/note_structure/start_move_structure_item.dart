import 'package:app/domain/entities/structure_item.dart';
import 'package:app/domain/repositories/note_structure_repository.dart';
import 'package:app/domain/usecases/note_structure/navigation/get_current_structure_item.dart';
import 'package:shared/core/constants/error_codes.dart';
import 'package:shared/core/exceptions/exceptions.dart';
import 'package:shared/core/utils/logger/logger.dart';
import 'package:shared/domain/usecases/usecase.dart';


/// This starts the move of the [NoteStructureRepository.currentItem] by caching a deep copy of it as the
/// [NoteStructureRepository.moveItemSrc] and then setting the current item to the [NoteStructureRepository.moveSelection].
///
/// The current item can be a note, or a folder of the "root", or "recent" tree. After this use case, the target parent
/// folder has to be selected as a destination for the current item to put in. This selection should show a cancel and
/// confirm button on the bottom of the ui and not allow any of the modification buttons. Otherwise it is the same as the
/// "root" view, but there are only folders and no note files to select.
/// Important: the side menu may not be opened in this view!
///
/// Afterwards [GetCurrentStructureItem] should be called again by the ui to return a new copy of the
/// [NoteStructureRepository.currentItem]!
///
/// The buttons on the bottom should then call [FinishMoveStructureItem] to complete the move!
///
/// If the [NoteStructureRepository.currentItem] is not modifiable, or if it does not have a parent then this will throw
/// [ErrorCodes.CANT_BE_MODIFIED]. So it should not be set to [NoteStructureRepository.root], or [NoteStructureRepository.recent]!
///
/// This calls the use case [GetCurrentStructureItem] and can throw the exceptions of it!
class StartMoveStructureItem extends UseCase<void, NoParams> {
  final GetCurrentStructureItem getCurrentStructureItem;
  final NoteStructureRepository noteStructureRepository;

  const StartMoveStructureItem({
    required this.getCurrentStructureItem,
    required this.noteStructureRepository,
  });

  @override
  Future<void> execute(NoParams params) async {
    final StructureItem currentItem = await getCurrentStructureItem.call(const NoParams());

    if (currentItem.canBeModified == false || currentItem.directParent == null) {
      Logger.error("The item can not be modified:\n$currentItem");
      throw const ClientException(message: ErrorCodes.CANT_BE_MODIFIED);
    }

    noteStructureRepository.moveItemSrc = currentItem;
    noteStructureRepository.currentItem = noteStructureRepository.moveSelection;

    Logger.debug("Started the move selection for:\n$currentItem");
  }
}
