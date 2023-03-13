import 'dart:async';

import 'package:app/core/constants/routes.dart';
import 'package:app/domain/entities/structure_folder.dart';
import 'package:app/domain/entities/structure_item.dart';
import 'package:app/domain/entities/structure_update_batch.dart';
import 'package:app/domain/usecases/note_structure/create_structure_item.dart';
import 'package:app/domain/usecases/note_structure/navigation/get_current_structure_item.dart';
import 'package:app/domain/usecases/note_structure/navigation/get_structure_updates_stream.dart';
import 'package:app/domain/usecases/note_structure/navigation/navigate_to_item.dart';
import 'package:app/presentation/pages/note_selection/note_selection_event.dart';
import 'package:app/presentation/pages/note_selection/note_selection_state.dart';
import 'package:app/presentation/widgets/base_pages/page_bloc.dart';
import 'package:app/services/navigation_service.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared/core/utils/logger/logger.dart';
import 'package:shared/domain/usecases/usecase.dart';

class NoteSelectionBloc extends PageBloc<NoteSelectionEvent, NoteSelectionState> {
  /// This will be updated as deep copies (so it can be used as a reference inside of the state)
  late StructureItem currentItem;

  final NavigationService navigationService;
  final NavigateToItem navigateToItem;
  final CreateStructureItem createStructureItem;

  final GetCurrentStructureItem getCurrentStructureItem;

  final GetStructureUpdatesStream getStructureUpdatesStream;
  /// for the [getStructureUpdatesStream]
  StreamSubscription<StructureUpdateBatch>? subscription;

  NoteSelectionBloc({
    required this.navigationService,
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
      event.completer.complete(true);
    } else {
      event.completer.complete(false);
      Logger.verbose("navigated back to ${currentItem.getParent()?.path}");
      await navigateToItem.call(const NavigateToItemParamsParent());
    }
  }

  Future<void> _handleDropDownMenuSelected(NoteSelectionDropDownMenuSelected event, Emitter<NoteSelectionState> emit) async {
    //todo: implement
  }

  Future<void> _handleCreatedItem(NoteSelectionCreatedItem event, Emitter<NoteSelectionState> emit) async {


    // todo: show dialog with input validator, etc

    await createStructureItem.call(CreateStructureItemParams(name: "test", isFolder: event.isFolder));

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
