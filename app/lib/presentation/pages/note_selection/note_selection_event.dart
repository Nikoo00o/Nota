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