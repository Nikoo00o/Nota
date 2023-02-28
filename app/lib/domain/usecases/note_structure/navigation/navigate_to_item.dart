import 'package:app/domain/entities/structure_folder.dart';
import 'package:app/domain/entities/structure_item.dart';
import 'package:app/domain/repositories/note_structure_repository.dart';
import 'package:app/domain/usecases/note_structure/get_current_structure_item.dart';
import 'package:app/domain/usecases/note_transfer/inner/fetch_new_note_structure.dart';
import 'package:shared/core/constants/error_codes.dart';
import 'package:shared/core/exceptions/exceptions.dart';
import 'package:shared/core/utils/logger/logger.dart';
import 'package:shared/domain/usecases/usecase.dart';

/// This navigates to a new item by changing the [NoteStructureRepository.currentItem].
///
/// Afterwards [GetCurrentStructureItem] should be called again by the ui to return a new copy of the
/// [NoteStructureRepository.currentItem]!
///
/// This can call [FetchNewNoteStructure] and throw the exceptions of it!
///
/// This can also throw [ErrorCodes.INVALID_PARAMS] depending on the index, or parent of the different [NavigateToItemParams]
class NavigateToItem extends UseCase<void, NavigateToItemParams> {
  final NoteStructureRepository noteStructureRepository;
  final FetchNewNoteStructure fetchNewNoteStructure;

  const NavigateToItem({
    required this.noteStructureRepository,
    required this.fetchNewNoteStructure,
  });

  @override
  Future<void> execute(NavigateToItemParams params) async {
    if (noteStructureRepository.root == null) {
      await fetchNewNoteStructure.call(const NoParams());
    }
    StructureItem? newItem;

    if (params is NavigateToItemParamsChild) {
      final StructureItem? current = noteStructureRepository.currentItem;
      if (current is StructureFolder && params.childIndex < current.amountOfChildren) {
        newItem = current.getChild(params.childIndex);
      } else {
        Logger.error("The child index ${params.childIndex} was too high");
        throw const ClientException(message: ErrorCodes.INVALID_PARAMS);
      }
    } else if (params is NavigateToItemParamsTopLevel) {
      if (params.parentIndex < noteStructureRepository.topLevelFolders.length) {
        newItem = noteStructureRepository.topLevelFolders.elementAt(params.parentIndex);
      } else {
        Logger.error("The parent index ${params.parentIndex} was too high");
        throw const ClientException(message: ErrorCodes.INVALID_PARAMS);
      }
    } else if (params is NavigateToItemParamsParent) {
      newItem = noteStructureRepository.currentItem?.getParent();
      if (newItem == null) {
        Logger.error("The current item did not have a parent:\n${noteStructureRepository.currentItem}");
        throw const ClientException(message: ErrorCodes.INVALID_PARAMS);
      }
    }

    noteStructureRepository.currentItem = newItem;
    Logger.debug("Navigated to the new current item path ${newItem?.path} with the parent ${newItem?.topMostParent.name}");
  }
}

abstract class NavigateToItemParams {
  const NavigateToItemParams();
}

/// Navigates to the specific child of the current item at the specified index.
///
/// Throws [ErrorCodes.INVALID_PARAMS] if the [childIndex] was equal, or higher than the amount of children. Or if the
/// [NoteStructureRepository.currentItem] is not a folder.
class NavigateToItemParamsChild extends NavigateToItemParams {
  final int childIndex;

  const NavigateToItemParamsChild({required this.childIndex});
}

/// Navigates to the parent of the current of the current item.
///
/// Items in recent will directly navigate to recent itself.
///
/// If the parent is null, then this throws [ErrorCodes.INVALID_PARAMS].
class NavigateToItemParamsParent extends NavigateToItemParams {
  const NavigateToItemParamsParent();
}

/// Navigates to the specific top level item at the specified index.
///
/// Throws [ErrorCodes.INVALID_PARAMS] if the [parentIndex] was equal, or higher than the amount of top level items.
class NavigateToItemParamsTopLevel extends NavigateToItemParams {
  final int parentIndex;

  const NavigateToItemParamsTopLevel({required this.parentIndex});
}
