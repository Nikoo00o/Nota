import 'package:app/presentation/widgets/base_pages/page_event.dart';

abstract class NoteSelectionEvent extends PageEvent {
  const NoteSelectionEvent();
}

class NoteSelectionEventInitialise extends NoteSelectionEvent {
  const NoteSelectionEventInitialise();
}
