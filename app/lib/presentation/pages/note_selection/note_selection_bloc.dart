import 'dart:async';

import 'package:app/core/constants/routes.dart';
import 'package:app/domain/entities/structure_folder.dart';
import 'package:app/domain/entities/structure_item.dart';
import 'package:app/domain/entities/structure_update_batch.dart';
import 'package:app/domain/usecases/note_structure/create_structure_item.dart';
import 'package:app/domain/usecases/note_structure/navigation/get_current_structure_item.dart';
import 'package:app/domain/usecases/note_structure/navigation/get_structure_updates_stream.dart';
import 'package:app/domain/usecases/note_structure/navigation/navigate_to_item.dart';
import 'package:app/presentation/main/dialog_overlay/dialog_overlay_bloc.dart';
import 'package:app/presentation/pages/note_selection/note_selection_event.dart';
import 'package:app/presentation/pages/note_selection/note_selection_state.dart';
import 'package:app/presentation/widgets/base_pages/page_bloc.dart';
import 'package:app/services/dialog_service.dart';
import 'package:app/services/navigation_service.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared/core/utils/logger/logger.dart';
import 'package:shared/domain/usecases/usecase.dart';

class NoteSelectionBloc extends PageBloc<NoteSelectionEvent, NoteSelectionState> {
  /// This will be updated as deep copies (so it can be used as a reference inside of the state)
  late StructureItem currentItem;

  final NavigationService navigationService;
  final DialogService dialogService;
  final NavigateToItem navigateToItem;
  final CreateStructureItem createStructureItem;

  final GetCurrentStructureItem getCurrentStructureItem;

  final GetStructureUpdatesStream getStructureUpdatesStream;

  /// for the [getStructureUpdatesStream]
  StreamSubscription<StructureUpdateBatch>? subscription;

  NoteSelectionBloc({
    required this.navigationService,
    required this.dialogService,
    required this.navigateToItem,
    required this.createStructureItem,
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
    currentItem = event.newCurrentItem;
    Logger.verbose("handling structure change with new item ${currentItem.path}");
    if (currentItem is StructureFolder) {
      emit(_buildState());
    } else {
      navigationService.navigateTo(Routes.note_edit);
    }
  }

  Future<void> _handleNavigatedBack(NoteSelectionNavigatedBack event, Emitter<NoteSelectionState> emit) async {
    if (currentItem.isTopLevel) {
      event.completer?.complete(true);
    } else {
      event.completer?.complete(false);
      Logger.verbose("navigated back to ${currentItem.getParent()?.path}");
      await navigateToItem.call(const NavigateToItemParamsParent());
    }
  }

  Future<void> _handleDropDownMenuSelected(NoteSelectionDropDownMenuSelected event, Emitter<NoteSelectionState> emit) async {
    //todo: implement
  }

  Future<void> _handleCreatedItem(NoteSelectionCreatedItem event, Emitter<NoteSelectionState> emit) async {
    final Completer<String?> completer = Completer<String?>();
    dialogService.showInputDialog(ShowInputDialog(
      onConfirm: (String input) => completer.complete(input),
      onCancel: () => completer.complete(null),
      titleKey: event.isFolder ? "note.selection.create.folder" : "note.selection.create.note",
      inputLabelKey: "name",
      descriptionKey: event.isFolder ? "note.selection.create.folder.description" : "note.selection.create.note.description",
      validatorCallback: (String? input) => _validateNewItem(input, isFolder: event.isFolder),
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

  String? _validateNewItem(String? name, {required bool isFolder}) {
    if (name == null || name.isEmpty) {
      return null;
    }
    try {
      StructureItem.throwErrorForName(name);
    } catch (_) {
      return translate("note.selection.create.invalid.name");
    }
    if (isFolder && (currentItem as StructureFolder?)?.getDirectFolderByName(name, deepCopy: false) != null) {
      return translate("note.selection.create.name.taken");
    }
    return null;
  }

  Future<void> _handleItemClicked(NoteSelectionItemClicked event, Emitter<NoteSelectionState> emit) async {
    await navigateToItem(NavigateToItemParamsChild(childIndex: event.index));
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
