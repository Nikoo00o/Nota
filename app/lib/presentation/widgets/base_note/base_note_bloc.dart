import 'dart:async';

import 'package:app/core/config/app_config.dart';
import 'package:app/core/utils/input_validator.dart';
import 'package:app/domain/entities/structure_folder.dart';
import 'package:app/domain/entities/structure_item.dart';
import 'package:app/domain/entities/structure_update_batch.dart';
import 'package:app/domain/entities/translation_string.dart';
import 'package:app/domain/repositories/app_settings_repository.dart';
import 'package:app/domain/usecases/favourites/change_favourite.dart';
import 'package:app/domain/usecases/favourites/is_favourite.dart';
import 'package:app/domain/usecases/note_structure/change_current_structure_item.dart';
import 'package:app/domain/usecases/note_structure/delete_current_structure_item.dart';
import 'package:app/domain/usecases/note_structure/export_current_structure_item.dart';
import 'package:app/domain/usecases/note_structure/navigation/get_current_structure_item.dart';
import 'package:app/domain/usecases/note_structure/navigation/get_structure_updates_stream.dart';
import 'package:app/domain/usecases/note_structure/start_move_structure_item.dart';
import 'package:app/presentation/main/dialog_overlay/dialog_overlay_bloc.dart';
import 'package:app/presentation/widgets/base_note/base_note_event.dart';
import 'package:app/presentation/widgets/base_note/base_note_state.dart';
import 'package:app/presentation/widgets/base_note/note_popup_menu.dart';
import 'package:app/presentation/widgets/base_pages/page_bloc.dart';
import 'package:app/services/dialog_service.dart';
import 'package:app/services/navigation_service.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared/core/constants/error_codes.dart';
import 'package:shared/core/exceptions/exceptions.dart';
import 'package:shared/core/utils/logger/logger.dart';
import 'package:shared/domain/usecases/usecase.dart';

/// this is the shared bloc super class for all of the note pages which already adds some event handlers and provides
/// some use cases and class variables.
///
/// you should look to override the following: [initialize], [buildState], [onUpdateState], [onStructureChange],
/// [onBackNavigationShouldPop], [dropDownMenu].
///
/// remember to call [registerEventHandlers] of this if you override that method in the sub class!
abstract base class BaseNoteBloc<State extends BaseNoteState> extends PageBloc<BaseNoteEvent, State> {
  final NavigationService navigationService;
  final DialogService dialogService;
  final AppConfig appConfig;
  final AppSettingsRepository appSettingsRepository;

  final GetCurrentStructureItem getCurrentStructureItem;
  final GetStructureUpdatesStream getStructureUpdatesStream;

  final ChangeCurrentStructureItem changeCurrentStructureItem;
  final StartMoveStructureItem startMoveStructureItem;
  final DeleteCurrentStructureItem deleteCurrentStructureItem;
  final ExportCurrentStructureItem exportCurrentStructureItem;

  final IsFavourite isFavouriteUC;
  final ChangeFavourite changeFavourite;

  /// the subscription for the [getStructureUpdatesStream] that will be closed on closing the bloc and is initialized
  /// in the initialize handler
  StreamSubscription<StructureUpdateBatch>? _subscription;

  /// This will be updated as deep copies (so it can be used as a reference inside of the state). it will only be
  /// null at first before the bloc is initialized
  StructureItem? currentItem;

  /// if the current item is selected as a favourite
  bool isFavourite = false;

  BaseNoteBloc({
    required State initialState,
    required this.navigationService,
    required this.dialogService,
    required this.appConfig,
    required this.appSettingsRepository,
    required this.getCurrentStructureItem,
    required this.getStructureUpdatesStream,
    required this.changeCurrentStructureItem,
    required this.startMoveStructureItem,
    required this.deleteCurrentStructureItem,
    required this.exportCurrentStructureItem,
    required this.isFavouriteUC,
    required this.changeFavourite,
  }) : super(initialState: initialState);

  @override
  void registerEventHandlers() {
    on<BaseNoteInitialized>(_handleInitialized);
    on<BaseNoteDropDownMenuSelected>(_handleDropDownMenuSelected);
    on<BaseNoteUpdatedState>(_handleUpdatedState);
    on<BaseNoteStructureChanged>(_handleStructureChanged);
    on<BaseNoteFavouriteChanged>(_handleFavouriteChanged);
    on<BaseNoteBackPressed>(_handleNavigatedBack);
  }

  @override
  Future<void> close() async {
    await _subscription?.cancel();
    return super.close();
  }

  Future<void> _handleInitialized(BaseNoteInitialized event, Emitter<State> emit) async {
    if (_subscription != null) {
      Logger.warn("this should not happen, base note bloc already initialised");
      return;
    }
    dialogService.showLoadingDialog();
    // init first item and init stream
    add(BaseNoteStructureChanged(newCurrentItem: await getCurrentStructureItem.call(const NoParams())));
    _subscription = await getStructureUpdatesStream
        .call(GetStructureUpdatesStreamParams(callbackFunction: (StructureUpdateBatch batch) {
      add(BaseNoteStructureChanged(newCurrentItem: batch.currentItem));
    }));
    await initialize();
    dialogService.hideLoadingDialog();
  }

  /// This can be overridden in your subclass to initialize additional stuff before the current item is set and before
  /// the initialisation is done (but the current item might also already be set async)
  ///
  /// A loading dialog is already shown during this! a state is not automatically emitted, but a
  /// [BaseNoteStructureChanged] event is added which will then build and emit a new state!
  Future<void> initialize();

  /// Important: override this in your subclass to create the concrete state subclass object with all data!
  Future<State> buildState();

  /// override this in your subclass to execute custom logic on receiving the [BaseNoteUpdatedState] event. the new
  /// state is emitted automatically afterwards.
  ///
  /// there is no loading dialog being shown currently!
  Future<void> onUpdateState() async {}

  /// override this and react to structure item changes from the [BaseNoteStructureChanged] event.
  ///
  /// a loading dialog is already shown and the [currentItem] is the new item. the [oldItem] was the current item
  /// before the event! afterwards the favourite status is set!
  ///
  /// also a state is automatically emitted if this method returns true. otherwise it will not!
  Future<bool> onStructureChange(StructureItem? oldItem);

  /// override this and react to the [BaseNoteBackPressed] event that is send when the user clicks the back button.
  ///
  /// The completer returns true if no custom back navigation was executed and the default back navigation (for
  /// example navigator pop) should be executed. otherwise the completer should return false (for example if the
  /// current item is a deeper folder of the note selection that will be changed to a higher folder on navigating back)
  ///
  /// there is no loading dialog being shown currently and there will be no state emitted!
  Future<bool> onBackNavigationShouldPop();

  /// Important: override this in your subclass to add the custom menu buttons afterwards (first insert those of this
  /// super method inside of the list!). And then call this method inside of the [buildState] method for the drop
  /// down menu param (so it will be called before and will be used to build the state!)!
  ///
  /// If the drop down action need to emit a new state, then add a [BaseNoteUpdatedState] event in the callback!
  List<NoteDropDownMenuParam> get dropDownMenu {
    final bool isFolder = currentItem is StructureFolder;
    final bool canBeModified = isFolder == false || (currentItem as StructureFolder).canBeModified;
    return <NoteDropDownMenuParam>[
      NoteDropDownMenuParam(
        isEnabled: canBeModified,
        translationString: TranslationString("note.selection.rename"),
        callback: _renameCurrentItem,
      ),
      NoteDropDownMenuParam(
        isEnabled: canBeModified,
        translationString: TranslationString("note.selection.move"),
        callback: _moveCurrentItem,
      ),
      NoteDropDownMenuParam(
        isEnabled: canBeModified,
        translationString: TranslationString("note.selection.delete"),
        callback: _deleteCurrentItem,
      ),
    ];
  }

  Future<void> _handleDropDownMenuSelected(BaseNoteDropDownMenuSelected event, Emitter<State> emit) async {
    if (event.index >= state.dropDownMenuParams.length) {
      Logger.error("drop down menu index error: ${event.index} is bigger than ${state.dropDownMenuParams.length}");
      throw const ClientException(message: ErrorCodes.INVALID_PARAMS);
    }
    await state.dropDownMenuParams.elementAt(event.index).callback.call();
    emit(await buildState());
  }

  Future<void> _renameCurrentItem() async {
    final bool isFolder = currentItem is StructureFolder;
    final Completer<String?> completer = Completer<String?>();
    dialogService.showInputDialog(ShowInputDialog(
      onConfirm: (String input, int index) => completer.complete(input),
      onCancel: () => completer.complete(null),
      titleKey: isFolder ? "note.selection.rename.folder" : "note.edit.rename.note",
      inputLabelKey: "name",
      descriptionKey: "note.selection.create.folder.description",
      validatorCallback: (String? input) =>
          InputValidator.validateNewItem(input, isFolder: isFolder, parent: currentItem?.getParent()),
      autoFocus: true,
    ));
    final String? name = await completer.future;
    final String? oldName = currentItem?.name;
    if (name != null && oldName != null) {
      await changeCurrentStructureItem
          .call(isFolder ? ChangeCurrentFolderParam(newName: name) : ChangeCurrentNoteParam(newName: name));
      dialogService.showInfoSnackBar(ShowInfoSnackBar(
        textKey: isFolder ? "note.selection.rename.folder.done" : "note.edit.rename.note.done",
        textKeyParams: <String>[oldName, name],
      ));
    }
  }

  Future<void> _moveCurrentItem() async {
    await startMoveStructureItem(const NoParams());
  }

  Future<void> _deleteCurrentItem() async {
    final bool isFolder = currentItem is StructureFolder;
    final Completer<bool> completer = Completer<bool>();
    dialogService.showConfirmDialog(ShowConfirmDialog(
      onConfirm: () => completer.complete(true),
      onCancel: () => completer.complete(false),
      titleKey: isFolder ? "note.selection.delete.folder" : "note.edit.delete.note",
      descriptionKey: isFolder ? "note.selection.delete.folder.description" : "note.edit.delete.note.description",
      descriptionKeyParams: <String>[currentItem!.name],
    ));
    if (await completer.future) {
      final String path = currentItem!.path;
      await deleteCurrentStructureItem.call(const NoParams());
      dialogService.showInfoSnackBar(ShowInfoSnackBar(
        textKey: isFolder ? "note.selection.delete.folder.done" : "note.edit.delete.note.done",
        textKeyParams: <String>[path],
      ));
    }
  }

  /// exports the current selected structure item
  Future<void> exportCurrentItem() async {
    await exportCurrentStructureItem.call(const NoParams());
  }

  Future<void> _handleUpdatedState(BaseNoteUpdatedState event, Emitter<BaseNoteState> emit) async {
    await onUpdateState();
    emit(await buildState());
  }

  Future<void> _handleStructureChanged(BaseNoteStructureChanged event, Emitter<BaseNoteState> emit) async {
    final StructureItem? lastItem = currentItem;
    currentItem = event.newCurrentItem;
    dialogService.showLoadingDialog();
    Logger.verbose("handling structure change with new item ${currentItem?.path}");
    final bool emitState = await onStructureChange(lastItem);
    isFavourite = await isFavouriteUC.call(IsFavouriteParams.fromItem(currentItem!));
    if (emitState) {
      emit(await buildState());
    }
    dialogService.hideLoadingDialog();
  }

  Future<void> _handleFavouriteChanged(BaseNoteFavouriteChanged event, Emitter<BaseNoteState> emit) async {
    isFavourite = event.isFavourite;
    await changeFavourite.call(ChangeFavouriteParams(isFavourite: isFavourite, item: currentItem!));
    emit(await buildState());
  }

  Future<void> _handleNavigatedBack(BaseNoteBackPressed event, Emitter<BaseNoteState> emit) async {
    final bool result = await onBackNavigationShouldPop();
    event.shouldPopNavigationStack?.complete(result);
  }
}
