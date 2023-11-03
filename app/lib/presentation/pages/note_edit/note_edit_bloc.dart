import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:app/core/constants/routes.dart';
import 'package:app/core/utils/security_utils_extension.dart';
import 'package:app/domain/entities/note_content/note_content.dart';
import 'package:app/domain/entities/structure_item.dart';
import 'package:app/domain/entities/structure_note.dart';
import 'package:app/domain/entities/translation_string.dart';
import 'package:app/domain/usecases/note_structure/change_current_structure_item.dart';
import 'package:app/domain/usecases/note_structure/navigation/navigate_to_item.dart';
import 'package:app/domain/usecases/note_transfer/load_note_buffer.dart';
import 'package:app/domain/usecases/note_transfer/load_note_content.dart';
import 'package:app/domain/usecases/note_transfer/save_note_buffer.dart';
import 'package:app/presentation/main/dialog_overlay/dialog_overlay_bloc.dart';
import 'package:app/presentation/pages/note_edit/note_edit_event.dart';
import 'package:app/presentation/pages/note_edit/note_edit_state.dart';
import 'package:app/presentation/pages/note_edit/widgets/custom_edit_controller.dart';
import 'package:app/presentation/widgets/base_note/base_note_bloc.dart';
import 'package:app/presentation/widgets/base_note/base_note_event.dart';
import 'package:app/presentation/widgets/base_note/note_popup_menu.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared/core/enums/note_type.dart';
import 'package:shared/core/utils/list_utils.dart';
import 'package:shared/core/utils/logger/logger.dart';
import 'package:shared/domain/usecases/usecase.dart';

final class NoteEditBloc extends BaseNoteBloc<NoteEditState> {
  final NavigateToItem navigateToItem;
  final SaveNoteBuffer saveNoteBuffer;
  final LoadNoteBuffer loadNoteBuffer;
  final LoadNoteContent loadNoteContent;

  final TextEditingController searchController = TextEditingController();
  late final CustomEditController inputController;
  final ScrollController scrollController = ScrollController();

  /// here it has focus if the user is typing in the search bar
  final FocusNode searchFocus = FocusNode();

  /// the has focus is true if the user is currently editing the note
  final FocusNode inputFocus = FocusNode();

  /// if the user is currently in the editing view (if either the search bar, or the edit text field is focused).
  ///
  /// this is set automatically on focus change inside of [_enableEditing] and [_clearFocus] with a state rebuild
  bool isEditing = false;

  /// calculated from the loaded note to test if the user changed something
  List<int>? noteHash;

  NoteEditBloc({
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
    required this.saveNoteBuffer,
    required this.loadNoteBuffer,
    required this.loadNoteContent,
  }) : super(initialState: NoteEditState.initial()) {
    inputController = CustomEditController(searchCaseSensitive: appConfig.searchCaseSensitive);
  }

  @override
  List<NoteDropDownMenuParam> get dropDownMenu {
    return <NoteDropDownMenuParam>[
      ...super.dropDownMenu,
      NoteDropDownMenuParam(
        isEnabled: true,
        translationString: TranslationString("note.selection.export"),
        callback: exportCurrentItem,
      ),
    ];
  }

  @override
  void registerEventHandlers() {
    super.registerEventHandlers(); // important: first register the super classes event handlers
    on<NoteEditInputSaved>(_handleInputSaved);
    on<NoteEditSearchStepped>(_handleSearchStep);
    on<NoteEditAppPaused>(_handleAppPaused);
  }

  @override
  Future<void> initialize() async {
    inputFocus.addListener(_enableEditing);
    searchFocus.addListener(_enableEditing);
  }

  @override
  Future<void> close() async {
    inputFocus.removeListener(_enableEditing);
    searchFocus.removeListener(_enableEditing);
    return super.close();
  }

  @override
  Future<NoteEditState> buildState() async {
    if (currentItem is StructureNote) {
      return NoteEditState(
        dropDownMenuParams: dropDownMenu,
        currentItem: currentItem,
        isFavourite: isFavourite,
        isEditing: isEditing,
        currentSearchPosition: inputController.currentSearchPosition.toString(),
        searchPositionSize: inputController.searchPositionAmount.toString(),
        searchLength: inputController.searchSize,
      );
    } else {
      return NoteEditState.initial();
    }
  }

  @override
  Future<void> onUpdateState() async {
    inputController.updateSearch(searchController.text); // todo: if the search system is changed, this can also be
    // done with better performance so that it is not updated every time the state rebuilds
    if (Platform.isWindows) {
      //todo: this is needed because of a flutter bug with text edit field on windows with
      // the new line characters
      final String oldText = inputController.text;
      const String search = "\r\n";
      if (oldText.contains(search)) {
        Logger.verbose("replaced \\r\\n with \\n on windows");
        inputController.text = oldText.replaceAll(search, "\n");
      }
    }
    // state is emitted automatically afterwards
  }

  @override
  Future<bool> onStructureChange(StructureItem? oldItem) async {
    if (currentItem is StructureNote && currentItem!.noteType == NoteType.RAW_TEXT) {
      // this will be called after initialization
      if (noteHash == null) {
        Logger.verbose("loading initial note content");
        final StructureNote note = currentItem as StructureNote;
        final NoteContent data = await loadNoteContent(LoadNoteContentParams(noteId: note.id, noteType: note.noteType));

        noteHash = await SecurityUtilsExtension.hashBytesAsync(data.text);
        final String? bufferedData = await loadNoteBuffer(const NoParams());
        if (bufferedData != null) {
          inputController.text = bufferedData; // restore and reset buffered data after pausing the app and coming back
          // here from the lockscreen
          await saveNoteBuffer(const SaveNoteBufferParams(content: null));
          if (inputFocus.hasFocus == false) {
            inputFocus.requestFocus();
          }
        } else {
          inputController.text = utf8.decode(data.text);
        }
      }
      return true;
    } else {
      Logger.verbose("navigated away from note edit, because the note type is different");
      // will be called automatically from the structure change of _handleNavigatedBack
      navigationService.navigateTo(Routes.note_selection);
      return false;
    }
  }

  @override
  Future<bool> onBackNavigationShouldPop() async {
    await _clearFocus(); // always clear focus. only show confirm dialog if is editing and if content has changed!
    final bool contentChanged = await hasContentChanged(updateOldHash: false);
    final bool autoSave = await appSettingsRepository.getAutoSave();
    if (autoSave) {
      dialogService.showLoadingDialog();
      await _saveInputIfChanged();
      dialogService.hideLoadingDialog();
    }

    if (contentChanged == false || autoSave || await _userConfirmedDrop()) {
      Logger.verbose("navigated back to ${currentItem?.getParent()?.path}");
      inputController.clear(); // also clear text input on navigating
      await navigateToItem.call(const NavigateToItemParamsParent());
      // the navigator navigating will be done automatically inside of _handleStructureChanged
    } else {
      inputFocus.requestFocus(); // make sure the user knows that he has to edit the text again
    }
    return false; // no navigator pop is needed here !
  }

  void _enableEditing() {
    if (isEditing == false) {
      isEditing = true;
      add(const BaseNoteUpdatedState());
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

  Future<void> _handleInputSaved(NoteEditInputSaved event, Emitter<NoteEditState> emit) async {
    dialogService.showLoadingDialog();
    await _clearFocus();
    await _saveInputIfChanged();
    emit(await buildState());
    dialogService.hideLoadingDialog();
  }

  Future<void> _saveInputIfChanged() async {
    final List<int> newData = utf8.encode(inputController.text);
    if (await hasContentChanged(updateOldHash: true)) {
      await changeCurrentStructureItem.call(ChangeCurrentNoteParam(newName: currentItem!.name, newContent: newData));
      dialogService.showInfoSnackBar(const ShowInfoSnackBar(textKey: "saved", duration: Duration(seconds: 1)));
    }
  }

  Future<void> _handleSearchStep(NoteEditSearchStepped event, Emitter<NoteEditState> emit) async {
    if (inputController.moveSearch(forward: event.forward)) {
      if (inputFocus.hasFocus == false) {
        inputFocus.requestFocus();
      }
    }
    emit(await buildState());
  }

  Future<void> _handleAppPaused(NoteEditAppPaused event, Emitter<NoteEditState> emit) async {
    if (noteHash != null && await hasContentChanged(updateOldHash: false)) {
      if (await appSettingsRepository.getAutoSave()) {
        await _saveInputIfChanged();
      } else {
        await saveNoteBuffer(SaveNoteBufferParams(content: inputController.text));
      }
    }
  }

  /// clears focus of input and search, also clears the searchcontroller and updates the search of the input controller.
  /// also resets the note buffer
  ///
  /// this also sets [isEditing] to false!
  Future<void> _clearFocus() async {
    if (inputFocus.hasFocus) {
      inputFocus.unfocus();
    }
    if (searchFocus.hasFocus) {
      searchFocus.unfocus();
    }
    isEditing = false;
    searchController.clear(); // also clear search text
    inputController.updateSearch(""); // and also clear input controller
    await saveNoteBuffer(const SaveNoteBufferParams(content: null));
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
}
