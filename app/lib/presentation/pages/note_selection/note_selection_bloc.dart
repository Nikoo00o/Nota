import 'dart:async';

import 'package:app/domain/entities/structure_item.dart';
import 'package:app/domain/entities/structure_update_batch.dart';
import 'package:app/domain/usecases/note_structure/navigation/get_current_structure_item.dart';
import 'package:app/domain/usecases/note_structure/navigation/get_structure_updates_stream.dart';
import 'package:app/presentation/pages/note_selection/note_selection_event.dart';
import 'package:app/presentation/pages/note_selection/note_selection_state.dart';
import 'package:app/presentation/widgets/base_pages/page_bloc.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared/core/utils/logger/logger.dart';
import 'package:shared/domain/usecases/usecase.dart';

class NoteSelectionBloc extends PageBloc<NoteSelectionEvent, NoteSelectionState> {
  /// This will be updated as deep copies (so it can be used as a reference inside of the state)
  late StructureItem currentItem;

  final GetCurrentStructureItem getCurrentStructureItem;

  final GetStructureUpdatesStream getStructureUpdatesStream;

  StreamSubscription<StructureUpdateBatch>? subscription;

  NoteSelectionBloc({
    required this.getCurrentStructureItem,
    required this.getStructureUpdatesStream,
  }) : super(initialState: const NoteSelectionState());

  @override
  void registerEventHandlers() {
    on<NoteSelectionInitialised>(_handleInitialised);
    on<NoteSelectionStructureChanged>(_handleStructureChanged);
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
    currentItem = await getCurrentStructureItem.call(const NoParams());
    subscription =
        await getStructureUpdatesStream.call(GetStructureUpdatesStreamParams(callbackFunction: (StructureUpdateBatch batch) {
      add(NoteSelectionStructureChanged(newCurrentItem: batch.currentItem));
    }));
    emit(_buildState());
  }

  Future<void> _handleStructureChanged(NoteSelectionStructureChanged event, Emitter<NoteSelectionState> emit) async {
    currentItem = event.newCurrentItem;
    Logger.verbose("handling structure change with new item ${currentItem.path}");
    emit(_buildState());
  }

  NoteSelectionState _buildState() {
    return NoteSelectionStateInitialised(currentItem: currentItem);
  }
}
