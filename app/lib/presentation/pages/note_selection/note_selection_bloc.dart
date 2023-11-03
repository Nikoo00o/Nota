import 'dart:async';

import 'package:app/core/config/app_config.dart';
import 'package:app/core/enums/routes.dart';
import 'package:app/core/enums/event_action.dart';
import 'package:app/core/enums/search_status.dart';
import 'package:app/core/utils/input_validator.dart';
import 'package:app/domain/entities/structure_folder.dart';
import 'package:app/domain/entities/structure_item.dart';
import 'package:app/domain/entities/translation_string.dart';
import 'package:app/domain/usecases/note_structure/create_structure_item.dart';
import 'package:app/domain/usecases/note_structure/finish_move_structure_item.dart';
import 'package:app/domain/usecases/note_structure/load_all_structure_content.dart';
import 'package:app/domain/usecases/note_structure/navigation/navigate_to_item.dart';
import 'package:app/domain/usecases/note_transfer/get_last_note_transfer_time.dart';
import 'package:app/domain/usecases/note_transfer/transfer_notes.dart';
import 'package:app/presentation/main/dialog_overlay/dialog_overlay_bloc.dart';
import 'package:app/presentation/pages/note_selection/note_selection_event.dart';
import 'package:app/presentation/pages/note_selection/note_selection_state.dart';
import 'package:app/presentation/widgets/base_note/base_note_bloc.dart';
import 'package:app/presentation/widgets/base_note/base_note_event.dart';
import 'package:app/presentation/widgets/base_note/note_popup_menu.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared/core/constants/error_codes.dart';
import 'package:shared/core/enums/note_type.dart';
import 'package:shared/core/exceptions/exceptions.dart';
import 'package:shared/core/utils/logger/logger.dart';
import 'package:shared/domain/usecases/usecase.dart';
import 'package:tuple/tuple.dart';

final class NoteSelectionBloc extends BaseNoteBloc<NoteSelectionState> {
  final NavigateToItem navigateToItem;
  final CreateStructureItem createStructureItem;
  final FinishMoveStructureItem finishMoveStructureItem;

  final TransferNotes transferNotes;
  final GetLastNoteTransferTime getLastNoteTransferTime;
  final LoadAllStructureContent loadAllStructureContent;

  final ScrollController scrollController = ScrollController();

  // todo: maybe change the disable method and move this into a search service, so that the search is saved between
  //  note and folder! (or a shared note service)
  final TextEditingController searchController = TextEditingController();

  final FocusNode searchFocus = FocusNode();

  /// extended, or default search, or disabled for no search at all
  SearchStatus searchStatus = SearchStatus.DISABLED;

  /// this is only used  for the extended search and has the note content mapped to the note id
  Map<int, String>? noteContentMap;

  /// time stamp from the last server sync
  late DateTime lastNoteTransferTime;

  StructureFolder? get currentFolder => currentItem as StructureFolder?;

  NoteSelectionBloc({
    required super.navigationService,
    required super.dialogService,
    required super.appConfig,
    required super.appSettingsRepository,
    required super.getCurrentStructureItem,
    required super.getStructureUpdatesStream,
    required super.changeCurrentStructureItem,
    required super.startMoveStructureItem,
    required super.deleteCurrentStructureItem,
    required super.exportCurrentStructureItem,
    required super.isFavouriteUC,
    required super.changeFavourite,
    required this.navigateToItem,
    required this.createStructureItem,
    required this.finishMoveStructureItem,
    required this.transferNotes,
    required this.getLastNoteTransferTime,
    required this.loadAllStructureContent,
  }) : super(initialState: NoteSelectionState.initial());

  @override
  List<NoteDropDownMenuParam> get dropDownMenu {
    return <NoteDropDownMenuParam>[
      ...super.dropDownMenu,
      NoteDropDownMenuParam(
        isEnabled: currentFolder?.topMostParent.isMove == false,
        translationString: TranslationString("note.selection.extended.search"),
        callback: _enableExtendedSearch,
      ),
    ];
  }

  @override
  void registerEventHandlers() {
    super.registerEventHandlers(); // important: first register the super classes event handlers
    on<NoteSelectionCreatedItem>(_handleCreatedItem);
    on<NoteSelectionItemClicked>(_handleItemClicked);
    on<NoteSelectionNavigateToParent>(_handleNavigateToParent);
    on<NoteSelectionServerSynced>(_handleServerSync);
    on<NoteSelectionChangedMove>(_handleChangeMove);
    on<NoteSelectionChangeSearch>(_handleChangeSearch);
    on<NoteSelectionDroppedFile>(_handleDroppedFile);
  }

  @override
  Future<void> initialize() async {
    lastNoteTransferTime = await getLastNoteTransferTime(const NoParams());
    final bool autoServerSync = await appSettingsRepository.getAutoServerSync();
    if (autoServerSync && lastNoteTransferTime.add(appConfig.automaticServerSyncDelay).isBefore(DateTime.now())) {
      Logger.verbose("performing automatic server sync");
      await _serverSync(null);
    }
  }

  @override
  Future<NoteSelectionState> buildState() async {
    if (currentItem is StructureItem) {
      return NoteSelectionState(
        dropDownMenuParams: dropDownMenu,
        currentItem: currentItem,
        isFavourite: isFavourite,
        searchStatus: searchStatus,
        searchInput: _searchInput,
        noteContentMap: noteContentMap,
        lastNoteTransferTime: lastNoteTransferTime,
      );
    } else {
      return NoteSelectionState.initial();
    }
  }

  @override
  Future<void> onUpdateState() async {
    // so far there is nothing to do here, only new state emitted automatically afterwards
  }

  @override
  Future<bool> onStructureChange(StructureItem? oldItem) async {
    switch (currentItem!.noteType) {
      case NoteType.FOLDER:
        if (currentItem is! StructureFolder) {
          Logger.error("structure change to folder did not have the correct note type");
          throw const ClientException(message: ErrorCodes.INVALID_PARAMS);
        }
        if (oldItem != null) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            // reset scroll on navigating to other items
            scrollController.jumpTo(scrollController.position.minScrollExtent);
          });
        }
        return true;
      case NoteType.RAW_TEXT:
        navigationService.navigateTo(Routes.note_edit);
        return false;
      case NoteType.FILE_WRAPPER:
        navigationService.navigateTo(Routes.note_edit_file);
        return false;
    }
  }

  @override
  Future<bool> onBackNavigationShouldPop() async {
    if (searchStatus != SearchStatus.DISABLED) {
      await _disableSearch();
      add(const BaseNoteUpdatedState()); // important: update state!
      return false;
    } else if (currentItem?.isTopLevel ?? true) {
      return true;
    } else {
      Logger.verbose("navigated back to ${currentItem?.getParent()?.path}");
      await navigateToItem.call(const NavigateToItemParamsParent());
      return false;
    }
  }

  Future<void> _handleCreatedItem(NoteSelectionCreatedItem event, Emitter<NoteSelectionState> emit) async {
    await _disableSearch();
    final Completer<(String input, int index)?> completer = Completer<(String input, int index)?>();
    dialogService.showInputDialog(ShowInputDialog(
      onConfirm: (String input, int index) => completer.complete((input, index)),
      onCancel: () => completer.complete(null),
      titleKey: event.isFolder ? "note.selection.create.folder" : "note.selection.create.note",
      inputLabelKey: "name",
      descriptionKey:
          event.isFolder ? "note.selection.create.folder.description" : "note.selection.create.note.description",
      validatorCallback: (String? input) =>
          InputValidator.validateNewItem(input, isFolder: event.isFolder, parent: currentItem as StructureFolder?),
      autoFocus: true,
      dropDownTextKeys: event.isFolder == true
          ? null
          : <TranslationString>[
              TranslationString("note.selection.create.note.type.default"),
              TranslationString("note.selection.create.note.type.file"),
            ],
    ));
    final (String input, int index)? pattern = await completer.future;
    if (pattern != null) {
      NoteType createdType = NoteType.FOLDER;
      if (event.isFolder == false) {
        final int noteTypeIndex = pattern.$2; // drop down menu selection
        createdType = switch (noteTypeIndex) {
          1 => NoteType.FILE_WRAPPER,
          _ => NoteType.RAW_TEXT, // default for more, or index 0 is raw text
        };
      }

      await createStructureItem.call(CreateStructureItemParams(
        name: pattern.$1,
        noteType: createdType,
      ));

      switch (createdType) {
        case NoteType.FOLDER:
          dialogService.showInfoSnackBar(ShowInfoSnackBar(
            textKey: "note.selection.folder.created",
            textKeyParams: <String>[pattern.$1],
          ));
        case NoteType.RAW_TEXT:
        case NoteType.FILE_WRAPPER:
        // todo: adjust the createdType above depending on the noteTypeIndex
      }
    } else {
      emit(await buildState()); // update state when its not done by the structure change
    }
  }

  Future<void> _handleItemClicked(NoteSelectionItemClicked event, Emitter<NoteSelectionState> emit) async {
    await navigateToItem(NavigateToItemParamsChild(childIndex: event.index));
  }

  Future<void> _handleNavigateToParent(NoteSelectionNavigateToParent event, Emitter<NoteSelectionState> emit) async {
    if (currentItem?.isTopLevel ?? true) {
      Logger.error("navigate to parent did not have the correct note type");
      throw const ClientException(message: ErrorCodes.INVALID_PARAMS);
    }
    Logger.verbose("navigated back to ${currentItem?.getParent()?.path}");
    await navigateToItem.call(const NavigateToItemParamsParent());
  }

  Future<void> _handleServerSync(NoteSelectionServerSynced event, Emitter<NoteSelectionState> emit) async {
    await _disableSearch();
    dialogService.showLoadingDialog();
    await _serverSync(() async => emit(await buildState()));
    dialogService.hideLoadingDialog();
  }

  /// [emitCallback] is optional to emit a state only on success
  Future<void> _serverSync(Future<void> Function()? emitCallback) async {
    final bool confirmed = await transferNotes(const NoParams());
    if (confirmed) {
      lastNoteTransferTime = await getLastNoteTransferTime(const NoParams());
      await emitCallback?.call();
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
      await _activateSearch(event.searchStatus);
      emit(await buildState()); // also build new state
    }
  }

  Future<void> _enableExtendedSearch() async {
    await _activateSearch(SearchStatus.EXTENDED);
    add(const BaseNoteUpdatedState()); // also build new state
  }

  Future<void> _activateSearch(SearchStatus newStatus) async {
    searchStatus = newStatus;
    if (newStatus == SearchStatus.EXTENDED) {
      dialogService.showLoadingDialog();
      noteContentMap = await loadAllStructureContent(const NoParams());
      dialogService.hideLoadingDialog();
    } else {
      noteContentMap = null;
    }
    if (searchFocus.hasFocus == false) {
      searchFocus.requestFocus();
    }
  }

  Future<void> _disableSearch() async {
    if (searchFocus.hasFocus) {
      searchFocus.unfocus();
    }
    searchStatus = SearchStatus.DISABLED;
    noteContentMap = null;
    searchController.clear();
  }

  Future<void> _handleDroppedFile(NoteSelectionDroppedFile event, Emitter<NoteSelectionState> emit) async {
    if (event.details.files.length == 1) {
      await createStructureItem.call(CreateStructureItemParamsFromDroppedFile(path: event.details.files.first.path));
    } else {
      Logger.error("currently dragging and dropping multiple files is not supported");
      throw const FileException(message: ErrorCodes.FILE_NOT_SUPPORTED);
    }
  }

  /// as lower case if [AppConfig.searchCaseSensitive] is false. input of the search bar
  String? get _searchInput {
    if (searchStatus != SearchStatus.DISABLED && searchController.text.isNotEmpty) {
      return appConfig.searchCaseSensitive ? searchController.text : searchController.text.toLowerCase();
    }
    return null;
  }
}
