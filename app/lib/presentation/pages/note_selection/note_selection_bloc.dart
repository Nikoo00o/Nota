import 'dart:async';

import 'package:app/core/constants/routes.dart';
import 'package:app/core/enums/event_action.dart';
import 'package:app/core/utils/input_validator.dart';
import 'package:app/domain/entities/structure_folder.dart';
import 'package:app/domain/entities/structure_item.dart';
import 'package:app/domain/entities/structure_update_batch.dart';
import 'package:app/domain/usecases/note_structure/change_current_structure_item.dart';
import 'package:app/domain/usecases/note_structure/create_structure_item.dart';
import 'package:app/domain/usecases/note_structure/delete_current_structure_item.dart';
import 'package:app/domain/usecases/note_structure/finish_move_structure_item.dart';
import 'package:app/domain/usecases/note_structure/navigation/get_current_structure_item.dart';
import 'package:app/domain/usecases/note_structure/navigation/get_structure_updates_stream.dart';
import 'package:app/domain/usecases/note_structure/navigation/navigate_to_item.dart';
import 'package:app/domain/usecases/note_structure/start_move_structure_item.dart';
import 'package:app/domain/usecases/note_transfer/transfer_notes.dart';
import 'package:app/presentation/main/dialog_overlay/dialog_overlay_bloc.dart';
import 'package:app/presentation/pages/note_selection/note_selection_event.dart';
import 'package:app/presentation/pages/note_selection/note_selection_state.dart';
import 'package:app/presentation/widgets/base_pages/page_bloc.dart';
import 'package:app/services/dialog_service.dart';
import 'package:app/services/navigation_service.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared/core/utils/logger/logger.dart';
import 'package:shared/domain/usecases/usecase.dart';
import 'package:tuple/tuple.dart';

class NoteSelectionBloc extends PageBloc<NoteSelectionEvent, NoteSelectionState> {
  /// This will be updated as deep copies (so it can be used as a reference inside of the state)
  StructureItem? currentItem;

  final NavigationService navigationService;
  final DialogService dialogService;
  final NavigateToItem navigateToItem;
  final CreateStructureItem createStructureItem;
  final ChangeCurrentStructureItem changeCurrentStructureItem;
  final DeleteCurrentStructureItem deleteCurrentStructureItem;
  final StartMoveStructureItem startMoveStructureItem;
  final FinishMoveStructureItem finishMoveStructureItem;
  final TransferNotes transferNotes;

  final GetCurrentStructureItem getCurrentStructureItem;

  final GetStructureUpdatesStream getStructureUpdatesStream;

  /// for the [getStructureUpdatesStream]
  StreamSubscription<StructureUpdateBatch>? subscription;

  final ScrollController scrollController = ScrollController();

  NoteSelectionBloc({
    required this.navigationService,
    required this.dialogService,
    required this.navigateToItem,
    required this.createStructureItem,
    required this.changeCurrentStructureItem,
    required this.deleteCurrentStructureItem,
    required this.startMoveStructureItem,
    required this.finishMoveStructureItem,
    required this.transferNotes,
    required this.getCurrentStructureItem,
    required this.getStructureUpdatesStream,
  }) : super(initialState: const NoteSelectionState());

  @override
  void registerEventHandlers() {
    on<NoteSelectionInitialised>(_handleInitialised);
    on<NoteSelectionStructureChanged>(_handleStructureChanged);
    on<NoteSelectionNavigatedBack>(_handleNavigatedBack);
    on<NoteSelectionDropDownMenuSelected>(_handleDropDownMenuSelected);
    on<NoteSelectionCreatedItem>(_handleCreatedItem);
    on<NoteSelectionItemClicked>(_handleItemClicked);
    on<NoteSelectionServerSynced>(_handleServerSync);
    on<NoteSelectionChangedMove>(_handleChangeMove);
  }

  @override
  Future<void> close() async {
    await subscription?.cancel();
    return super.close();
  }

  Future<void> _handleInitialised(NoteSelectionInitialised event, Emitter<NoteSelectionState> emit) async {
    if (subscription != null) {
      Logger.warn("this should not happen, note selection bloc already initialised");
      return;
    }
    add(NoteSelectionStructureChanged(newCurrentItem: await getCurrentStructureItem.call(const NoParams())));
    subscription =
        await getStructureUpdatesStream.call(GetStructureUpdatesStreamParams(callbackFunction: (StructureUpdateBatch batch) {
      add(NoteSelectionStructureChanged(newCurrentItem: batch.currentItem));
    }));
  }

  Future<void> _handleStructureChanged(NoteSelectionStructureChanged event, Emitter<NoteSelectionState> emit) async {
    final StructureItem? lastItem = currentItem;
    currentItem = event.newCurrentItem;
    Logger.verbose("handling structure change with new item ${currentItem!.path}");
    if (currentItem is StructureFolder) {
      emit(_buildState());
      if (lastItem != null) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          // reset scroll on navigating to other items
          scrollController.jumpTo(scrollController.position.minScrollExtent);
        });
      }
    } else {
      navigationService.navigateTo(Routes.note_edit);
    }
  }

  Future<void> _handleNavigatedBack(NoteSelectionNavigatedBack event, Emitter<NoteSelectionState> emit) async {
    if (currentItem?.isTopLevel ?? true) {
      event.completer?.complete(true);
    } else {
      event.completer?.complete(false);
      Logger.verbose("navigated back to ${currentItem?.getParent()?.path}");
      await navigateToItem.call(const NavigateToItemParamsParent());
    }
  }

  Future<void> _handleDropDownMenuSelected(NoteSelectionDropDownMenuSelected event, Emitter<NoteSelectionState> emit) async {
    switch (event.index) {
      case 0:
        await _renameCurrentFolder();
        break;
      case 1:
        await startMoveStructureItem(const NoParams());
        break;
      case 2:
        await _deleteCurrentFolder();
        break;
    }
  }

  Future<void> _renameCurrentFolder() async {
    final Completer<String?> completer = Completer<String?>();
    dialogService.showInputDialog(ShowInputDialog(
      onConfirm: (String input) => completer.complete(input),
      onCancel: () => completer.complete(null),
      titleKey: "note.selection.rename.folder",
      inputLabelKey: "name",
      descriptionKey: "note.selection.create.folder.description",
      validatorCallback: (String? input) =>
          InputValidator.validateNewItem(input, isFolder: true, parent: currentItem?.getParent()),
    ));
    final String? name = await completer.future;
    final String? oldName = currentItem?.name;
    if (name != null && oldName != null) {
      await changeCurrentStructureItem.call(ChangeCurrentFolderParam(newName: name));
      dialogService.showInfoSnackBar(ShowInfoSnackBar(
        textKey: "note.selection.rename.folder.done",
        textKeyParams: <String>[oldName, name],
      ));
    }
  }

  Future<void> _deleteCurrentFolder() async {
    final Completer<bool> completer = Completer<bool>();
    dialogService.showConfirmDialog(ShowConfirmDialog(
      onConfirm: () => completer.complete(true),
      onCancel: () => completer.complete(false),
      titleKey: "note.selection.delete.folder",
      descriptionKey: "note.selection.delete.folder.description",
      descriptionKeyParams: <String>[currentItem!.name],
    ));
    if (await completer.future) {
      final String path = currentItem!.path;
      await deleteCurrentStructureItem.call(const NoParams());
      dialogService.showInfoSnackBar(ShowInfoSnackBar(
        textKey: "note.selection.delete.folder.done",
        textKeyParams: <String>[path],
      ));
    }
  }

  Future<void> _handleCreatedItem(NoteSelectionCreatedItem event, Emitter<NoteSelectionState> emit) async {
    final Completer<String?> completer = Completer<String?>();
    dialogService.showInputDialog(ShowInputDialog(
      onConfirm: (String input) => completer.complete(input),
      onCancel: () => completer.complete(null),
      titleKey: event.isFolder ? "note.selection.create.folder" : "note.selection.create.note",
      inputLabelKey: "name",
      descriptionKey: event.isFolder ? "note.selection.create.folder.description" : "note.selection.create.note.description",
      validatorCallback: (String? input) =>
          InputValidator.validateNewItem(input, isFolder: event.isFolder, parent: currentItem as StructureFolder?),
    ));
    final String? name = await completer.future;
    if (name != null) {
      await createStructureItem.call(CreateStructureItemParams(name: name, isFolder: event.isFolder));
      if (event.isFolder) {
        dialogService.showInfoSnackBar(ShowInfoSnackBar(
          textKey: "note.selection.folder.created",
          textKeyParams: <String>[name],
        ));
      }
    }
  }

  Future<void> _handleItemClicked(NoteSelectionItemClicked event, Emitter<NoteSelectionState> emit) async {
    await navigateToItem(NavigateToItemParamsChild(childIndex: event.index));
  }

  Future<void> _handleServerSync(NoteSelectionServerSynced event, Emitter<NoteSelectionState> emit) async {
    final bool confirmed = await transferNotes(const NoParams());
    if (confirmed) {
      dialogService.showInfoSnackBar(const ShowInfoSnackBar(textKey: "note.selection.transferred.notes"));
    }
  }

  Future<void> _handleChangeMove(NoteSelectionChangedMove event, Emitter<NoteSelectionState> emit) async {
    final bool confirmed = event.status == EventAction.CONFIRMED;
    final Tuple2<String, String> result =
        await finishMoveStructureItem(FinishMoveStructureItemParams(wasConfirmed: confirmed));
    if (confirmed) {
      if (result.item2.isEmpty) {
        // moved to top level folder
        dialogService.showInfoSnackBar(
            ShowInfoSnackBar(textKey: "note.selection.moved.folder.top", textKeyParams: <String>[result.item1]));
      } else {
        dialogService.showInfoSnackBar(
            ShowInfoSnackBar(textKey: "note.selection.moved.folder", textKeyParams: <String>[result.item1, result.item2]));
      }
    }
  }

  /// only if [currentItem] is [StructureFolder]
  NoteSelectionState _buildState() {
    if (currentItem is StructureFolder) {
      return NoteSelectionStateInitialised(currentFolder: currentItem as StructureFolder);
    } else {
      return const NoteSelectionState();
    }
  }
}
