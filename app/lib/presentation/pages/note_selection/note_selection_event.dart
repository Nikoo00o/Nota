import 'dart:async';

import 'package:app/domain/entities/structure_item.dart';
import 'package:app/presentation/widgets/base_pages/page_event.dart';

abstract class NoteSelectionEvent extends PageEvent {
  const NoteSelectionEvent();
}

class NoteSelectionInitialised extends NoteSelectionEvent {
  const NoteSelectionInitialised();
}

class NoteSelectionStructureChanged extends NoteSelectionEvent {
  final StructureItem newCurrentItem;

  const NoteSelectionStructureChanged({required this.newCurrentItem});
}

class NoteSelectionNavigatedBack extends NoteSelectionEvent {
  /// The completer returns true if the current item is a top level folder and otherwise false(if it can navigate to parent)
  final Completer<bool>? completer;

  const NoteSelectionNavigatedBack({required this.completer});
}

class NoteSelectionDropDownMenuSelected extends NoteSelectionEvent {
  final int index;

  const NoteSelectionDropDownMenuSelected({required this.index});
}

class NoteSelectionCreatedItem extends NoteSelectionEvent {
  final bool isFolder;

  const NoteSelectionCreatedItem({required this.isFolder});
}

class NoteSelectionItemClicked extends NoteSelectionEvent {
  final int index;

  const NoteSelectionItemClicked({required this.index});
}

class NoteSelectionServerSynced extends NoteSelectionEvent {
  const NoteSelectionServerSynced();
}
