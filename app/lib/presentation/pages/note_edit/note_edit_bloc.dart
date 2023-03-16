import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:app/core/constants/routes.dart';
import 'package:app/core/enums/event_action.dart';
import 'package:app/core/utils/input_validator.dart';
import 'package:app/core/utils/security_utils_extension.dart';
import 'package:app/domain/entities/structure_folder.dart';
import 'package:app/domain/entities/structure_item.dart';
import 'package:app/domain/entities/structure_note.dart';
import 'package:app/domain/entities/structure_update_batch.dart';
import 'package:app/domain/usecases/note_structure/change_current_structure_item.dart';
import 'package:app/domain/usecases/note_structure/delete_current_structure_item.dart';
import 'package:app/domain/usecases/note_structure/navigation/get_current_structure_item.dart';
import 'package:app/domain/usecases/note_structure/navigation/get_structure_updates_stream.dart';
import 'package:app/domain/usecases/note_structure/navigation/navigate_to_item.dart';
import 'package:app/domain/usecases/note_structure/start_move_structure_item.dart';
import 'package:app/domain/usecases/note_transfer/inner/store_note_encrypted.dart';
import 'package:app/domain/usecases/note_transfer/load_note_content.dart';
import 'package:app/presentation/main/dialog_overlay/dialog_overlay_bloc.dart';
import 'package:app/presentation/pages/note_edit/note_edit_event.dart';
import 'package:app/presentation/pages/note_edit/note_edit_state.dart';
import 'package:app/presentation/pages/note_edit/widgets/custom_edit_controller.dart';
import 'package:app/presentation/widgets/base_pages/page_bloc.dart';
import 'package:app/services/dialog_service.dart';
import 'package:app/services/navigation_service.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared/core/utils/list_utils.dart';
import 'package:shared/core/utils/logger/logger.dart';
import 'package:shared/domain/usecases/usecase.dart';

class NoteEditBloc extends PageBloc<NoteEditEvent, NoteEditState> {
  /// This will be updated as deep copies (so it can be used as a reference inside of the state)
  late StructureItem currentItem;

  final NavigationService navigationService;
  final StartMoveStructureItem startMoveStructureItem;
  final DeleteCurrentStructureItem deleteCurrentStructureItem;
  final NavigateToItem navigateToItem;
  final DialogService dialogService;
  final GetCurrentStructureItem getCurrentStructureItem;

  final GetStructureUpdatesStream getStructureUpdatesStream;

  /// for the [getStructureUpdatesStream]
  StreamSubscription<StructureUpdateBatch>? subscription;

  final LoadNoteContent loadNoteContent;
  final ChangeCurrentStructureItem changeCurrentStructureItem;

  final TextEditingController searchController = TextEditingController();
  final FocusNode searchFocus = FocusNode();
  final CustomEditController inputController = CustomEditController();

  /// the has focus is true if the user is currently editing the note
  final FocusNode inputFocus = FocusNode(); // todo: also add one for search field

  /// calculated from the loaded note to test if the user changed something
  List<int>? noteHash;

  NoteEditBloc({
    required this.navigationService,
    required this.startMoveStructureItem,
    required this.deleteCurrentStructureItem,
    required this.navigateToItem,
    required this.dialogService,
    required this.getCurrentStructureItem,
    required this.getStructureUpdatesStream,
    required this.loadNoteContent,
    required this.changeCurrentStructureItem,
  }) : super(initialState: const NoteEditState());

  @override
  void registerEventHandlers() {
    on<NoteEditUpdatedState>(_handleUpdatedState);
    on<NoteEditInitialised>(_handleInitialised);
    on<NoteEditStructureChanged>(_handleStructureChanged);
    on<NoteEditNavigatedBack>(_handleNavigatedBack);
    on<NoteEditDropDownMenuSelected>(_handleDropDownMenuSelected);
    on<NoteEditInputSaved>(_handleInputSaved);
    on<NoteEditSearchStepped>(_handleSearchStep);
  }

  @override
  Future<void> close() async {
    await subscription?.cancel();
    return super.close();
  }

  Future<void> _handleUpdatedState(NoteEditUpdatedState event, Emitter<NoteEditState> emit) async {
    if (event.didSearchChange) {
      inputController.updateSearch(searchController.text);
    }
    emit(_buildState());
  }

  Future<void> _handleInitialised(NoteEditInitialised event, Emitter<NoteEditState> emit) async {
    if (subscription != null) {
      Logger.warn("this should not happen, note selection bloc already initialised");
      return;
    }

    inputFocus.addListener(() {
      if (inputFocus.hasFocus) {
        add(const NoteEditUpdatedState(didSearchChange: false)); // important: rebuild state only if input received the focus
      }
    });
    searchFocus.addListener(() {
      if (searchFocus.hasFocus) {
        add(const NoteEditUpdatedState(didSearchChange: false)); // important: rebuild state only if search received the
        // focus
      }
    });

    // init first item and init stream
    add(NoteEditStructureChanged(newCurrentItem: await getCurrentStructureItem.call(const NoParams())));
    subscription =
        await getStructureUpdatesStream.call(GetStructureUpdatesStreamParams(callbackFunction: (StructureUpdateBatch batch) {
      add(NoteEditStructureChanged(newCurrentItem: batch.currentItem));
    }));
  }

  Future<void> _handleStructureChanged(NoteEditStructureChanged event, Emitter<NoteEditState> emit) async {
    currentItem = event.newCurrentItem;
    dialogService.showLoadingDialog();
    Logger.verbose("handling structure change with new item ${currentItem.path}");
    if (currentItem is StructureNote) {
      if (noteHash == null) {
        Logger.verbose("loading initial note content");
        final List<int> data = await loadNoteContent(LoadNoteContentParams(noteId: (currentItem as StructureNote).id));
        noteHash = await SecurityUtilsExtension.hashBytesAsync(data);
        inputController.text = utf8.decode(data);
      }
      emit(_buildState());
    } else {
      navigationService.navigateTo(Routes.note_selection);
      inputController.clear(); // clear text input field on navigating away
    }
    dialogService.hideLoadingDialog();
  }

  Future<void> _handleNavigatedBack(NoteEditNavigatedBack event, Emitter<NoteEditState> emit) async {
    if (isEditing == false ||
        ListUtils.equals(noteHash, await SecurityUtilsExtension.hashBytesAsync(utf8.encode(inputController.text))) ||
        await _userConfirmedDrop()) {
      Logger.verbose("navigated back to ${currentItem.getParent()?.path}");
      await navigateToItem.call(const NavigateToItemParamsParent());
      //navigating will be done automatically inside of _handleStructureChanged
    }
  }

  Future<bool> _userConfirmedDrop() async {
    final Completer<bool> completer = Completer<bool>();
    dialogService.showConfirmDialog(ShowConfirmDialog(
      onConfirm: () => completer.complete(true),
      onCancel: () => completer.complete(false),
      titleKey: "attention",
      descriptionKey: "note.edit.drop.changes",
      confirmButtonKey: "yes",
      cancelButtonKey: "no",
    ));
    return completer.future;
  }

  Future<void> _handleDropDownMenuSelected(NoteEditDropDownMenuSelected event, Emitter<NoteEditState> emit) async {
    switch (event.index) {
      case 0:
        await _renameCurrentNote();
        break;
      case 1:
        await startMoveStructureItem(const NoParams());
        break;
      case 2:
        await _deleteCurrentNote();
        break;
    }
  }

  Future<void> _renameCurrentNote() async {
    final Completer<String?> completer = Completer<String?>();
    dialogService.showInputDialog(ShowInputDialog(
      onConfirm: (String input) => completer.complete(input),
      onCancel: () => completer.complete(null),
      titleKey: "note.edit.rename.note",
      inputLabelKey: "name",
      descriptionKey: "note.selection.create.folder.description",
      validatorCallback: (String? input) =>
          InputValidator.validateNewItem(input, isFolder: true, parent: currentItem.getParent()),
    ));
    final String? name = await completer.future;
    if (name != null) {
      await changeCurrentStructureItem.call(ChangeCurrentNoteParam(newName: name));
      dialogService.showInfoSnackBar(ShowInfoSnackBar(
        textKey: "note.edit.rename.note.done",
        textKeyParams: <String>[currentItem.name, name],
      ));
    }
  }

  Future<void> _deleteCurrentNote() async {
    final Completer<bool> completer = Completer<bool>();
    dialogService.showConfirmDialog(ShowConfirmDialog(
      onConfirm: () => completer.complete(true),
      onCancel: () => completer.complete(false),
      titleKey: "note.edit.delete.note",
      descriptionKey: "note.edit.delete.note.description",
      descriptionKeyParams: <String>[currentItem.name],
    ));
    if (await completer.future) {
      final String path = currentItem.path;
      await deleteCurrentStructureItem.call(const NoParams());
      dialogService.showInfoSnackBar(ShowInfoSnackBar(
        textKey: "note.edit.delete.note.done",
        textKeyParams: <String>[path],
      ));
    }
  }

  Future<void> _handleInputSaved(NoteEditInputSaved event, Emitter<NoteEditState> emit) async {
    dialogService.showLoadingDialog();
    _clearFocus();
    final List<int> newData = utf8.encode(inputController.text);
    final List<int> newHash = await SecurityUtilsExtension.hashBytesAsync(newData);
    if (ListUtils.equals(newHash, noteHash) == false) {
      await changeCurrentStructureItem.call(ChangeCurrentNoteParam(newName: currentItem.name, newContent: newData));
      noteHash = newHash;
      dialogService.showInfoSnackBar(const ShowInfoSnackBar(textKey: "saved", duration: Duration(seconds: 1)));
    }
    emit(_buildState());
    dialogService.hideLoadingDialog();
  }

  Future<void> _handleSearchStep(NoteEditSearchStepped event, Emitter<NoteEditState> emit) async {
    if (inputController.moveSearch(forward: event.forward)) {
      if (inputFocus.hasFocus == false) {
        inputFocus.requestFocus();
      }
    }
    emit(_buildState());
  }

  void _clearFocus() {
    if (inputFocus.hasFocus) {
      inputFocus.unfocus();
    }
    if (searchFocus.hasFocus) {
      searchFocus.unfocus();
    }
    searchController.clear(); // also clear search text
    inputController.updateSearch(""); // and also clear input controller
  }

  /// only if [currentItem] is [StructureNote]
  NoteEditState _buildState() {
    if (currentItem is StructureNote) {
      return NoteEditStateInitialised(
        currentNote: currentItem as StructureNote,
        isEditing: isEditing,
        currentSearchPosition: inputController.currentSearchPosition.toString(),
        searchPositionSize: inputController.searchPositionAmount.toString(),
        searchLength: inputController.searchSize,
      );
    } else {
      return const NoteEditState();
    }
  }

  bool get isEditing => inputFocus.hasFocus || searchFocus.hasFocus;

  @override
  bool get enableLoadingDialog => false; // prevent loading dialog for all small changes
}
