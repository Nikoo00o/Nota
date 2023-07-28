import 'dart:async';

import 'package:app/core/config/app_config.dart';
import 'package:app/core/constants/routes.dart';
import 'package:app/core/enums/event_action.dart';
import 'package:app/core/enums/search_status.dart';
import 'package:app/core/utils/input_validator.dart';
import 'package:app/domain/entities/structure_folder.dart';
import 'package:app/domain/entities/structure_item.dart';
import 'package:app/domain/entities/structure_update_batch.dart';
import 'package:app/domain/usecases/favourites/change_favourite.dart';
import 'package:app/domain/usecases/favourites/is_favourite.dart';
import 'package:app/domain/usecases/note_structure/change_current_structure_item.dart';
import 'package:app/domain/usecases/note_structure/create_structure_item.dart';
import 'package:app/domain/usecases/note_structure/delete_current_structure_item.dart';
import 'package:app/domain/usecases/note_structure/finish_move_structure_item.dart';
import 'package:app/domain/usecases/note_structure/load_all_structure_content.dart';
import 'package:app/domain/usecases/note_structure/navigation/get_current_structure_item.dart';
import 'package:app/domain/usecases/note_structure/navigation/get_structure_updates_stream.dart';
import 'package:app/domain/usecases/note_structure/navigation/navigate_to_item.dart';
import 'package:app/domain/usecases/note_structure/start_move_structure_item.dart';
import 'package:app/domain/usecases/note_transfer/get_last_note_transfer_time.dart';
import 'package:app/domain/usecases/note_transfer/transfer_notes.dart';
import 'package:app/presentation/main/dialog_overlay/dialog_overlay_bloc.dart';
import 'package:app/presentation/pages/note_selection/note_selection_event.dart';
import 'package:app/presentation/pages/note_selection/note_selection_state.dart';
import 'package:app/presentation/widgets/base_pages/page_bloc.dart';
import 'package:app/services/dialog_service.dart';
import 'package:app/services/navigation_service.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared/core/enums/note_type.dart';
import 'package:shared/core/utils/logger/logger.dart';
import 'package:shared/domain/usecases/usecase.dart';
import 'package:tuple/tuple.dart';

final class NoteSelectionBloc extends PageBloc<NoteSelectionEvent, NoteSelectionState> {
  final NavigationService navigationService;
  final AppConfig appConfig;
  final DialogService dialogService;

  final NavigateToItem navigateToItem;

  final CreateStructureItem createStructureItem;
  final ChangeCurrentStructureItem changeCurrentStructureItem;
  final DeleteCurrentStructureItem deleteCurrentStructureItem;

  final StartMoveStructureItem startMoveStructureItem;
  final FinishMoveStructureItem finishMoveStructureItem;

  final TransferNotes transferNotes;
  final GetLastNoteTransferTime getLastNoteTransferTime;
  final LoadAllStructureContent loadAllStructureContent;

  final GetCurrentStructureItem getCurrentStructureItem;
  final GetStructureUpdatesStream getStructureUpdatesStream;
  final IsFavourite isFavourite;
  final ChangeFavourite changeFavourite;

  final ScrollController scrollController = ScrollController();
  final FocusNode searchFocus = FocusNode();
  final TextEditingController searchController = TextEditingController();

  /// for the [getStructureUpdatesStream]
  StreamSubscription<StructureUpdateBatch>? subscription;

  /// This will be updated as deep copies (so it can be used as a reference inside of the state for navigation)
  StructureItem? currentItem;

  /// extended, or default search, or disabled for no search at all
  SearchStatus searchStatus = SearchStatus.DISABLED;

  /// this is only used  for the extended search and has the note content mapped to the note id
  Map<int, String>? noteContentMap;

  late DateTime lastNoteTransferTime;

  bool favourite = false;

  // todo: maybe in the future make this bloc leaner (and put some of the selection and edit stuff together like the
  //  favourite handling, etc)

  NoteSelectionBloc({
    required this.navigationService,
    required this.appConfig,
    required this.dialogService,
    required this.navigateToItem,
    required this.createStructureItem,
    required this.changeCurrentStructureItem,
    required this.deleteCurrentStructureItem,
    required this.startMoveStructureItem,
    required this.finishMoveStructureItem,
    required this.transferNotes,
    required this.getLastNoteTransferTime,
    required this.loadAllStructureContent,
    required this.getCurrentStructureItem,
    required this.getStructureUpdatesStream,
    required this.isFavourite,
    required this.changeFavourite,
  }) : super(initialState: const NoteSelectionState());

  @override
  void registerEventHandlers() {
    on<NoteSelectionUpdatedState>(_handleUpdatedState);
    on<NoteSelectionInitialised>(_handleInitialised);
    on<NoteSelectionStructureChanged>(_handleStructureChanged);
    on<NoteSelectionNavigatedBack>(_handleNavigatedBack);
    on<NoteSelectionDropDownMenuSelected>(_handleDropDownMenuSelected);
    on<NoteSelectionCreatedItem>(_handleCreatedItem);
    on<NoteSelectionItemClicked>(_handleItemClicked);
    on<NoteSelectionServerSynced>(_handleServerSync);
    on<NoteSelectionChangedMove>(_handleChangeMove);
    on<NoteSelectionChangeSearch>(_handleChangeSearch);
    on<NoteSelectionChangeFavourite>(_handleChangeFavourite);
  }

  @override
  Future<void> close() async {
    await subscription?.cancel();
    return super.close();
  }

  Future<void> _handleUpdatedState(NoteSelectionUpdatedState event, Emitter<NoteSelectionState> emit) async =>
      emit(_buildState());

  Future<void> _handleInitialised(NoteSelectionInitialised event, Emitter<NoteSelectionState> emit) async {
    if (subscription != null) {
      Logger.warn("this should not happen, note selection bloc already initialised");
      return;
    }
    dialogService.showLoadingDialog();
    lastNoteTransferTime = await getLastNoteTransferTime(const NoParams());
    add(NoteSelectionStructureChanged(newCurrentItem: await getCurrentStructureItem.call(const NoParams())));
    subscription = await getStructureUpdatesStream
        .call(GetStructureUpdatesStreamParams(callbackFunction: (StructureUpdateBatch batch) {
      add(NoteSelectionStructureChanged(newCurrentItem: batch.currentItem));
    }));
    dialogService.hideLoadingDialog();
  }

  Future<void> _handleStructureChanged(NoteSelectionStructureChanged event, Emitter<NoteSelectionState> emit) async {
    final StructureItem? lastItem = currentItem;
    currentItem = event.newCurrentItem;
    Logger.verbose("handling structure change with new item ${currentItem!.path}");
    if (currentItem is StructureFolder) {
      favourite = await isFavourite.call(IsFavouriteParams.fromItem(currentItem!));
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
    if (searchStatus != SearchStatus.DISABLED && event.ignoreSearch == false) {
      event.completer?.complete(false);
      _disableSearch(emit);
      emit(_buildState());
    } else if (currentItem?.isTopLevel ?? true) {
      event.completer?.complete(true);
    } else {
      event.completer?.complete(false);
      Logger.verbose("navigated back to ${currentItem?.getParent()?.path}");
      await navigateToItem.call(const NavigateToItemParamsParent());
    }
  }

  Future<void> _handleDropDownMenuSelected(
      NoteSelectionDropDownMenuSelected event, Emitter<NoteSelectionState> emit) async {
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
      case 3:
        await _activateSearch(SearchStatus.EXTENDED, emit);
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
    _disableSearch(emit);
    final Completer<String?> completer = Completer<String?>();
    dialogService.showInputDialog(ShowInputDialog(
      onConfirm: (String input) => completer.complete(input),
      onCancel: () => completer.complete(null),
      titleKey: event.isFolder ? "note.selection.create.folder" : "note.selection.create.note",
      inputLabelKey: "name",
      descriptionKey:
          event.isFolder ? "note.selection.create.folder.description" : "note.selection.create.note.description",
      validatorCallback: (String? input) =>
          InputValidator.validateNewItem(input, isFolder: event.isFolder, parent: currentItem as StructureFolder?),
    ));
    final String? name = await completer.future;
    if (name != null) {
      // todo: currently only creating either a folder, or a raw text note
      await createStructureItem.call(CreateStructureItemParams(
        name: name,
        noteType: event.isFolder ? NoteType.FOLDER : NoteType.RAW_TEXT,
      ));
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
    _disableSearch(emit);
    dialogService.showLoadingDialog();
    final bool confirmed = await transferNotes(const NoParams());
    if (confirmed) {
      lastNoteTransferTime = await getLastNoteTransferTime(const NoParams());
      emit(_buildState());
      dialogService.showInfoSnackBar(const ShowInfoSnackBar(textKey: "note.selection.transferred.notes"));
    }
    dialogService.hideLoadingDialog();
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
        dialogService.showInfoSnackBar(ShowInfoSnackBar(
            textKey: "note.selection.moved.folder", textKeyParams: <String>[result.item1, result.item2]));
      }
    }
  }

  Future<void> _handleChangeSearch(NoteSelectionChangeSearch event, Emitter<NoteSelectionState> emit) async {
    if (event.searchStatus == SearchStatus.DISABLED) {
      if (searchFocus.hasFocus) {
        searchFocus.unfocus(); // only unfocus
      }
    } else {
      await _activateSearch(event.searchStatus, emit);
    }
  }

  Future<void> _activateSearch(SearchStatus newStatus, Emitter<NoteSelectionState> emit) async {
    searchStatus = newStatus;
    if (newStatus == SearchStatus.EXTENDED) {
      dialogService.showLoadingDialog();
      noteContentMap = await loadAllStructureContent(const NoParams());
      dialogService.hideLoadingDialog();
    } else {
      noteContentMap = null;
    }
    emit(_buildState());
    if (searchFocus.hasFocus == false) {
      searchFocus.requestFocus();
    }
  }

  void _disableSearch(Emitter<NoteSelectionState> emit) {
    if (searchFocus.hasFocus) {
      searchFocus.unfocus();
    }
    searchStatus = SearchStatus.DISABLED;
    noteContentMap = null;
    searchController.clear();
    emit(_buildState());
  }

  Future<void> _handleChangeFavourite(NoteSelectionChangeFavourite event, Emitter<NoteSelectionState> emit) async {
    favourite = event.isFavourite;
    await changeFavourite.call(ChangeFavouriteParams(isFavourite: favourite, item: currentItem!));
    emit(_buildState());
  }

  /// only if [currentItem] is [StructureFolder]
  NoteSelectionState _buildState() {
    if (currentItem is StructureFolder) {

      return NoteSelectionStateInitialised(
        currentFolder: currentItem as StructureFolder,
        searchStatus: searchStatus,
        searchInput: _searchInput,
        noteContentMap: noteContentMap,
        lastNoteTransferTime: lastNoteTransferTime,
        isFavourite: favourite,
      );
    } else {
      return const NoteSelectionState();
    }
  }

  /// as lower case if [AppConfig.searchCaseSensitive] is false
  String? get _searchInput {
    if (searchStatus != SearchStatus.DISABLED && searchController.text.isNotEmpty) {
      return appConfig.searchCaseSensitive ? searchController.text : searchController.text.toLowerCase();
    }
    return null;
  }
}
