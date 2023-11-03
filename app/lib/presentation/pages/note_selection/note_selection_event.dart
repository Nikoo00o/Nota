import 'package:app/core/enums/event_action.dart';
import 'package:app/core/enums/search_status.dart';
import 'package:app/presentation/widgets/base_note/base_note_event.dart';
import 'package:desktop_drop/desktop_drop.dart';

sealed class NoteSelectionEvent extends BaseNoteEvent {
  const NoteSelectionEvent();
}

final class NoteSelectionCreatedItem extends NoteSelectionEvent {
  final bool isFolder;

  const NoteSelectionCreatedItem({required this.isFolder});
}

final class NoteSelectionItemClicked extends NoteSelectionEvent {
  final int index;

  const NoteSelectionItemClicked({required this.index});
}

final class NoteSelectionNavigateToParent extends NoteSelectionEvent {
  const NoteSelectionNavigateToParent();
}

final class NoteSelectionServerSynced extends NoteSelectionEvent {
  const NoteSelectionServerSynced();
}

final class NoteSelectionChangedMove extends NoteSelectionEvent {
  final EventAction status;

  const NoteSelectionChangedMove({required this.status});
}

final class NoteSelectionChangeSearch extends NoteSelectionEvent {
  final SearchStatus searchStatus;

  const NoteSelectionChangeSearch({required this.searchStatus});
}

final class NoteSelectionDroppedFile extends NoteSelectionEvent {
  final DropDoneDetails details;

  const NoteSelectionDroppedFile({required this.details});
}