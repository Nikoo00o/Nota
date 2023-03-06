import 'package:app/presentation/pages/note_selection/note_selection_event.dart';
import 'package:app/presentation/pages/note_selection/note_selection_state.dart';
import 'package:app/presentation/widgets/base_pages/page_bloc.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class NoteSelectionBloc extends PageBloc<NoteSelectionEvent, NoteSelectionState> {
  NoteSelectionBloc() : super(initialState: const NoteSelectionState());

  @override
  void registerEventHandlers() {
    on<NoteSelectionEventInitialise>(_handleInitialise);
  }

  Future<void> _handleInitialise(NoteSelectionEventInitialise event, Emitter<NoteSelectionState> emit) async {
    emit(_buildState());
  }

  NoteSelectionState _buildState() {
    return const NoteSelectionState();
  }
}
