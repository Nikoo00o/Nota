import 'dart:async';

import 'package:app/core/constants/routes.dart';
import 'package:app/domain/entities/structure_folder.dart';
import 'package:app/domain/entities/structure_item.dart';
import 'package:app/domain/entities/structure_note.dart';
import 'package:app/domain/entities/structure_update_batch.dart';
import 'package:app/domain/usecases/note_structure/navigation/get_current_structure_item.dart';
import 'package:app/domain/usecases/note_structure/navigation/get_structure_updates_stream.dart';
import 'package:app/domain/usecases/note_structure/navigation/navigate_to_item.dart';
import 'package:app/presentation/pages/note_edit/note_edit_event.dart';
import 'package:app/presentation/pages/note_edit/note_edit_state.dart';
import 'package:app/presentation/widgets/base_pages/page_bloc.dart';
import 'package:app/services/navigation_service.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared/core/utils/logger/logger.dart';
import 'package:shared/domain/usecases/usecase.dart';

class NoteEditBloc extends PageBloc<NoteEditEvent, NoteEditState> {
  /// This will be updated as deep copies (so it can be used as a reference inside of the state)
  late StructureItem currentItem;

  final NavigationService navigationService;
  final NavigateToItem navigateToItem;
  final GetCurrentStructureItem getCurrentStructureItem;

  final GetStructureUpdatesStream getStructureUpdatesStream;
  /// for the [getStructureUpdatesStream]
  StreamSubscription<StructureUpdateBatch>? subscription;

  NoteEditBloc({
    required this.navigationService,
    required this.navigateToItem,
    required this.getCurrentStructureItem,
    required this.getStructureUpdatesStream,
  }) : super(initialState: const NoteEditState());

  @override
  void registerEventHandlers() {
    on<NoteEditInitialised>(_handleInitialised);
    on<NoteEditStructureChanged>(_handleStructureChanged);
    on<NoteEditNavigatedBack>(_handleNavigatedBack);
    on<NoteEditDropDownMenuSelected>(_handleDropDownMenuSelected);
  }

  @override
  Future<void> close() async {
    await subscription?.cancel();
    return super.close();
  }

  Future<void> _handleInitialised(NoteEditInitialised event, Emitter<NoteEditState> emit) async {
    if (subscription != null) {
      Logger.warn("this should not happen, note selection bloc already initialised");
      return;
    }
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
      emit(_buildState());
    } else {
      navigationService.navigateTo(Routes.note_selection);
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

  /// only if [currentItem] is [StructureNote]
  NoteEditState _buildState() {
    if (currentItem is StructureNote) {
      return NoteEditStateInitialised(currentNote: currentItem as StructureNote);
    } else {
      return const NoteEditState();
    }
  }
}
