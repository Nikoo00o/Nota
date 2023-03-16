import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:app/core/constants/routes.dart';
import 'package:app/core/enums/event_action.dart';
import 'package:app/core/utils/security_utils_extension.dart';
import 'package:app/domain/entities/structure_folder.dart';
import 'package:app/domain/entities/structure_item.dart';
import 'package:app/domain/entities/structure_note.dart';
import 'package:app/domain/entities/structure_update_batch.dart';
import 'package:app/domain/usecases/note_structure/change_current_structure_item.dart';
import 'package:app/domain/usecases/note_structure/navigation/get_current_structure_item.dart';
import 'package:app/domain/usecases/note_structure/navigation/get_structure_updates_stream.dart';
import 'package:app/domain/usecases/note_structure/navigation/navigate_to_item.dart';
import 'package:app/domain/usecases/note_transfer/inner/store_note_encrypted.dart';
import 'package:app/domain/usecases/note_transfer/load_note_content.dart';
import 'package:app/presentation/main/dialog_overlay/dialog_overlay_bloc.dart';
import 'package:app/presentation/pages/note_edit/note_edit_event.dart';
import 'package:app/presentation/pages/note_edit/note_edit_state.dart';
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
  final NavigateToItem navigateToItem;
  final DialogService dialogService;
  final GetCurrentStructureItem getCurrentStructureItem;

  final GetStructureUpdatesStream getStructureUpdatesStream;

  /// for the [getStructureUpdatesStream]
  StreamSubscription<StructureUpdateBatch>? subscription;

  final LoadNoteContent loadNoteContent;
  final ChangeCurrentStructureItem changeCurrentStructureItem;
  final TextEditingController inputController = TextEditingController();

  /// the has focus is true if the user is currently editing the note
  final FocusNode inputFocusNode = FocusNode(); // todo: also add one for search field

  /// calculated from the loaded note to test if the user changed something
  List<int>? noteHash;

  NoteEditBloc({
    required this.navigationService,
    required this.navigateToItem,
    required this.dialogService,
    required this.getCurrentStructureItem,
    required this.getStructureUpdatesStream,
    required this.loadNoteContent,
    required this.changeCurrentStructureItem,
  }) : super(initialState: const NoteEditState());

  @override
  void registerEventHandlers() {
    on<NoteEditInitialised>(_handleInitialised);
    on<NoteEditUpdateState>(_handleUpdateState);
    on<NoteEditStructureChanged>(_handleStructureChanged);
    on<NoteEditNavigatedBack>(_handleNavigatedBack);
    on<NoteEditDropDownMenuSelected>(_handleDropDownMenuSelected);
    on<NoteEditInputStatusChanged>(_handleInputStatusChanged);
  }

  @override
  Future<void> close() async {
    await subscription?.cancel();
    return super.close();
  }

  Future<void> _handleUpdateState(NoteEditUpdateState event, Emitter<NoteEditState> emit) async => emit(_buildState());

  Future<void> _handleInitialised(NoteEditInitialised event, Emitter<NoteEditState> emit) async {
    if (subscription != null) {
      Logger.warn("this should not happen, note selection bloc already initialised");
      return;
    }

    inputFocusNode.addListener(() {
      if (inputFocusNode.hasFocus) {
        add(const NoteEditUpdateState()); // important: rebuild state only if input received the focus
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
      inputController.clear();// clear text input field on navigating away
    }
  }

  Future<void> _handleNavigatedBack(NoteEditNavigatedBack event, Emitter<NoteEditState> emit) async {
    Logger.verbose("navigated back to ${currentItem.getParent()?.path}");
    await navigateToItem.call(const NavigateToItemParamsParent());
    //navigating will be done automatically inside of _handleStructureChanged
  }

  Future<void> _handleDropDownMenuSelected(NoteEditDropDownMenuSelected event, Emitter<NoteEditState> emit) async {
    //todo: implement
  }

  Future<void> _handleInputStatusChanged(NoteEditInputStatusChanged event, Emitter<NoteEditState> emit) async {
    if (event.action == EventAction.CONFIRMED) {
      inputFocusNode.unfocus();
      final List<int> newData = utf8.encode(inputController.text);
      final List<int> newHash = await SecurityUtilsExtension.hashBytesAsync(newData);
      if (ListUtils.equals(newHash, noteHash) == false) {
        await changeCurrentStructureItem.call(ChangeCurrentNoteParam(newName: currentItem.name, newContent: newData));
        dialogService.showInfoSnackBar(const ShowInfoSnackBar(textKey: "saved", duration: Duration(seconds: 1)));
      }
    }
    //todo: implement
    emit(_buildState());
  }

  /// only if [currentItem] is [StructureNote]
  NoteEditState _buildState() {
    if (currentItem is StructureNote) {
      return NoteEditStateInitialised(
        currentNote: currentItem as StructureNote,
        isInputFocused: inputFocusNode.hasFocus,
      );
    } else {
      return const NoteEditState();
    }
  }
}
