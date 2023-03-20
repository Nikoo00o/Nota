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
import 'package:app/domain/repositories/app_settings_repository.dart';
import 'package:app/domain/usecases/note_structure/change_current_structure_item.dart';
import 'package:app/domain/usecases/note_structure/delete_current_structure_item.dart';
import 'package:app/domain/usecases/note_structure/navigation/get_current_structure_item.dart';
import 'package:app/domain/usecases/note_structure/navigation/get_structure_updates_stream.dart';
import 'package:app/domain/usecases/note_structure/navigation/navigate_to_item.dart';
import 'package:app/domain/usecases/note_structure/start_move_structure_item.dart';
import 'package:app/domain/usecases/note_transfer/inner/store_note_encrypted.dart';
import 'package:app/domain/usecases/note_transfer/load_note_buffer.dart';
import 'package:app/domain/usecases/note_transfer/load_note_content.dart';
import 'package:app/domain/usecases/note_transfer/save_note_buffer.dart';
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
  final SaveNoteBuffer saveNoteBuffer;
  final LoadNoteBuffer loadNoteBuffer;
  final AppSettingsRepository appSettingsRepository;
  final GetCurrentStructureItem getCurrentStructureItem;

  final GetStructureUpdatesStream getStructureUpdatesStream;

  /// for the [getStructureUpdatesStream]
  StreamSubscription<StructureUpdateBatch>? subscription;

  final LoadNoteContent loadNoteContent;
  final ChangeCurrentStructureItem changeCurrentStructureItem;

  final TextEditingController searchController = TextEditingController();
  final FocusNode searchFocus = FocusNode();
  final CustomEditController inputController = CustomEditController();
  final ScrollController scrollController = ScrollController();

  /// the has focus is true if the user is currently editing the note
  final FocusNode inputFocus = FocusNode(); // todo: also add one for search field

  /// calculated from the loaded note to test if the user changed something
  List<int>? noteHash;

  NoteEditBloc({
    required this.navigationService,
    required this.startMoveStructureItem,
    required this.deleteCurrentStructureItem,
    required this.navigateToItem,
    required this.saveNoteBuffer,
    required this.loadNoteBuffer,
    required this.appSettingsRepository,
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
    on<NoteEditAppPaused>(_handleAppPaused);
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
        final String? bufferedData = await loadNoteBuffer(const NoParams());
        if (bufferedData != null) {
          inputController.text = bufferedData; // restore and reset buffered data after pausing the app and coming back
          // here from the lockscreen
          await saveNoteBuffer(const SaveNoteBufferParams(content: null));
          if (inputFocus.hasFocus == false) {
            inputFocus.requestFocus();
          }
        } else {
          inputController.text = utf8.decode(data);
        }
      }
      emit(_buildState());
    } else {
      navigationService.navigateTo(Routes.note_selection); // will be called automatically from _handleNavigatedBack below
    }
    dialogService.hideLoadingDialog();
  }

  Future<void> _handleNavigatedBack(NoteEditNavigatedBack event, Emitter<NoteEditState> emit) async {
    await _clearFocus(); // always clear focus. only show confirm dialog if is editing and if content has changed!
    final bool contentChanged = await hasContentChanged(updateOldHash: false);
    final bool autoSave = await appSettingsRepository.getAutoSave();
    if (autoSave) {
      dialogService.showLoadingDialog();
      await _saveInputIfChanged();
      dialogService.hideLoadingDialog();
    }

    if (contentChanged == false || autoSave || await _userConfirmedDrop()) {
      Logger.verbose("navigated back to ${currentItem.getParent()?.path}");
      inputController.clear(); // also clear text input on navigating
      await navigateToItem.call(const NavigateToItemParamsParent());
      //navigating will be done automatically inside of _handleStructureChanged
    } else {
      inputFocus.requestFocus(); // make sure the user knows that he has to edit the text again
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
    await _clearFocus();
    await _saveInputIfChanged();
    emit(_buildState());
    dialogService.hideLoadingDialog();
  }

  Future<void> _saveInputIfChanged() async {
    final List<int> newData = utf8.encode(inputController.text);
    if (await hasContentChanged(updateOldHash: true)) {
      await changeCurrentStructureItem.call(ChangeCurrentNoteParam(newName: currentItem.name, newContent: newData));
      dialogService.showInfoSnackBar(const ShowInfoSnackBar(textKey: "saved", duration: Duration(seconds: 1)));
    }
  }

  Future<void> _handleSearchStep(NoteEditSearchStepped event, Emitter<NoteEditState> emit) async {
    if (inputController.moveSearch(forward: event.forward)) {
      if (inputFocus.hasFocus == false) {
        inputFocus.requestFocus();
      }
    }
    emit(_buildState());
  }

  Future<void> _handleAppPaused(NoteEditAppPaused event, Emitter<NoteEditState> emit) async {
    if (noteHash != null && await hasContentChanged(updateOldHash: false)) {
      await saveNoteBuffer(SaveNoteBufferParams(content: inputController.text));
    }
  }

  /// clears focus of input and search, also clears the searchcontroller and updates the search of the input controller.
  /// also resets the note buffer
  Future<void> _clearFocus() async {
    if (inputFocus.hasFocus) {
      inputFocus.unfocus();
    }
    if (searchFocus.hasFocus) {
      searchFocus.unfocus();
    }
    searchController.clear(); // also clear search text
    inputController.updateSearch(""); // and also clear input controller
    await saveNoteBuffer(const SaveNoteBufferParams(content: null));
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

  /// compares the [noteHash] to a newly computed hash of the [inputController.text] and returns if they are different.
  ///
  /// If they are different (so the content has changed) and [updateOldHash] is true, then the [noteHash] will be set to
  /// the new one!
  Future<bool> hasContentChanged({required bool updateOldHash}) async {
    final List<int> newHash = await SecurityUtilsExtension.hashBytesAsync(utf8.encode(inputController.text));
    if (ListUtils.equals(newHash, noteHash) == false) {
      if (updateOldHash) {
        noteHash = newHash;
      }
      return true;
    }
    return false;
  }

  bool get isEditing => inputFocus.hasFocus || searchFocus.hasFocus;

  @override
  bool get enableLoadingDialog => false; // prevent loading dialog for all small changes
}
