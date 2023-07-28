import 'package:app/domain/entities/structure_folder.dart';
import 'package:app/domain/entities/structure_item.dart';
import 'package:app/domain/entities/structure_note.dart';
import 'package:app/domain/repositories/note_structure_repository.dart';
import 'package:app/domain/usecases/note_structure/inner/add_new_structure_update_batch.dart';
import 'package:app/domain/usecases/note_structure/navigation/get_current_structure_item.dart';
import 'package:app/domain/usecases/note_structure/navigation/get_structure_updates_stream.dart';
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
///
/// This also adds a new streamed update by calling [AddNewStructureUpdateBatch] which will be received
/// by [GetStructureUpdatesStream]!
class NavigateToItem extends UseCase<void, NavigateToItemParams> {
  final NoteStructureRepository noteStructureRepository;
  final FetchNewNoteStructure fetchNewNoteStructure;
  final AddNewStructureUpdateBatch addNewStructureUpdateBatch;

  const NavigateToItem({
    required this.noteStructureRepository,
    required this.fetchNewNoteStructure,
    required this.addNewStructureUpdateBatch,
  });

  @override
  Future<void> execute(NavigateToItemParams params) async {
    if (noteStructureRepository.root == null) {
      await fetchNewNoteStructure.call(const NoParams());
    }
    final StructureItem newItem = getNewItem(params);

    noteStructureRepository.currentItem = newItem;
    Logger.debug(
        "Navigated to the new current item path ${newItem.path} with the parent ${newItem.topMostParent.name}");

    // at the end send a new update event to the ui!
    await addNewStructureUpdateBatch.call(const NoParams());
  }

  StructureItem getNewItem(NavigateToItemParams params) {
    if (params is _NavigateToItemParamsChild) {
      return getNewChildItem(params);
    } else if (params is NavigateToItemParamsTopLevel) {
      if (params.topLevelIndex < noteStructureRepository.topLevelFolders.length) {
        return noteStructureRepository.topLevelFolders.elementAt(params.topLevelIndex)!;
      } else {
        Logger.error("The parent index ${params.topLevelIndex} was too high");
        throw const ClientException(message: ErrorCodes.INVALID_PARAMS);
      }
    } else if (params is NavigateToItemParamsTopLevelName) {
      final Iterable<StructureFolder?> iterator = noteStructureRepository.topLevelFolders
          .where((StructureFolder? element) => element?.name == params.folderName);
      if (iterator.isNotEmpty && iterator.first != null) {
        return iterator.first!;
      } else {
        Logger.error("The top level folder name ${params.folderName} was not found");
        throw const ClientException(message: ErrorCodes.INVALID_PARAMS);
      }
    } else if (params is NavigateToItemParamsParent) {
      final StructureItem? newItem = noteStructureRepository.currentItem?.getParent();
      if (newItem == null) {
        Logger.error("The current item did not have a parent:\n${noteStructureRepository.currentItem}");
        throw const ClientException(message: ErrorCodes.INVALID_PARAMS);
      }
      return newItem;
    } else if(params is NavigateToItemParamsExact){
      return getExactItem(params);
    }

    throw UnimplementedError();
  }

  StructureItem getNewChildItem(_NavigateToItemParamsChild params) {
    if (params is NavigateToItemParamsChild) {
      final StructureItem? current = noteStructureRepository.currentItem;
      if (current is StructureFolder && params.childIndex < current.amountOfChildren) {
        return current.getChild(params.childIndex);
      } else {
        Logger.error("The child index ${params.childIndex} was too high");
        throw const ClientException(message: ErrorCodes.INVALID_PARAMS);
      }
    } else if (params is NavigateToItemParamsChildNoteById) {
      final StructureItem? current = noteStructureRepository.currentItem;
      if (current is StructureFolder) {
        final StructureNote? result = current.getNoteById(params.noteId);
        if (result != null) {
          return result;
        }
      }
      Logger.error("The note with the id ${params.noteId} was not found");
      throw const ClientException(message: ErrorCodes.INVALID_PARAMS);
    } else if (params is NavigateToItemParamsChildFolderByName) {
      final StructureItem? current = noteStructureRepository.currentItem;
      if (current is StructureFolder) {
        final StructureFolder? result = current.getDirectFolderByName(params.folderName, deepCopy: false);
        if (result != null) {
          return result;
        }
      }
      Logger.error("The folder with the name ${params.folderName} was not found");
      throw const ClientException(message: ErrorCodes.INVALID_PARAMS);
    }

    throw UnimplementedError();
  }

  StructureItem getExactItem(NavigateToItemParamsExact params){
    StructureItem? newItem;
    if(params.path != null){
      newItem = noteStructureRepository.root!.getFolderByPath(params.path!, deepCopy: false);
    } else if(params.id!=null){
      newItem = noteStructureRepository.root!.getNoteById(params.id!);
    }
    if (newItem == null) {
      Logger.error("The exact item with the path: ${params.path} and the id ${params.id} was not found!");
      throw const ClientException(message: ErrorCodes.INVALID_PARAMS);
    }
    return newItem;
  }
}

sealed class NavigateToItemParams {
  const NavigateToItemParams();
}

/// base class for all child navigation params
sealed class _NavigateToItemParamsChild extends NavigateToItemParams {
  const _NavigateToItemParamsChild();
}

/// Navigates to the specific child of the current item at the specified index.
///
/// Throws [ErrorCodes.INVALID_PARAMS] if the [childIndex] was equal, or higher than the amount of children. Or if the
/// [NoteStructureRepository.currentItem] is not a folder.
final class NavigateToItemParamsChild extends _NavigateToItemParamsChild {
  final int childIndex;

  const NavigateToItemParamsChild({required this.childIndex});
}

/// Navigates to the specific recursive child note with the given [noteId] of the [NoteStructureRepository.currentItem]
///
/// The note id is unique and is not the index!!!
///
/// Throws [ErrorCodes.INVALID_PARAMS] if the child was not found. Or if the
/// [NoteStructureRepository.currentItem] is not a folder.
final class NavigateToItemParamsChildNoteById extends _NavigateToItemParamsChild {
  final int noteId;

  const NavigateToItemParamsChildNoteById({required this.noteId});
}

/// Navigates to the specific direct child folder with the given [folderName] of the [NoteStructureRepository.currentItem]
///
/// Throws [ErrorCodes.INVALID_PARAMS] if the child was not found. Or if the
/// [NoteStructureRepository.currentItem] is not a folder.
final class NavigateToItemParamsChildFolderByName extends _NavigateToItemParamsChild {
  final String folderName;

  const NavigateToItemParamsChildFolderByName({required this.folderName});
}

/// Navigates to the parent of the current of the current item.
///
/// Items in recent will directly navigate to recent itself.
///
/// If the parent is null, then this throws [ErrorCodes.INVALID_PARAMS].
final class NavigateToItemParamsParent extends NavigateToItemParams {
  const NavigateToItemParamsParent();
}

/// Navigates to the specific top level item at the specified index.
///
/// Throws [ErrorCodes.INVALID_PARAMS] if the [topLevelIndex] was equal, or higher than the amount of top level items.
final class NavigateToItemParamsTopLevel extends NavigateToItemParams {
  final int topLevelIndex;

  const NavigateToItemParamsTopLevel({required this.topLevelIndex});
}

/// Navigates to the specific top level folder with the specific name.
///
/// Throws [ErrorCodes.INVALID_PARAMS] if the [folderName] was not found!
final class NavigateToItemParamsTopLevelName extends NavigateToItemParams {
  final String folderName;

  const NavigateToItemParamsTopLevelName({required this.folderName});
}

/// Navigates to the exact item (either folder, or note) by using [NoteStructureRepository.root] to find the item by
/// its path, or id!
///
/// Throws [ErrorCodes.INVALID_PARAMS] if the [path], or [id] was not found! Either one of those is null
final class NavigateToItemParamsExact extends NavigateToItemParams {
  /// used to identify a folder
  final String? path;

  /// used to identify a note
  final int? id;

  const NavigateToItemParamsExact.note(int this.id) : path = null;

  const NavigateToItemParamsExact.folder(String this.path) : id = null;
}
