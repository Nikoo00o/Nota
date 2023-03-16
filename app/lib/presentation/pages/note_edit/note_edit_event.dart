import 'package:app/core/enums/event_action.dart';
import 'package:app/domain/entities/structure_item.dart';
import 'package:app/presentation/widgets/base_pages/page_event.dart';

abstract class NoteEditEvent extends PageEvent {
  const NoteEditEvent();
}

class NoteEditUpdatedState extends NoteEditEvent {
  const NoteEditUpdatedState();
}

class NoteEditInitialised extends NoteEditEvent {
  const NoteEditInitialised();
}

class NoteEditStructureChanged extends NoteEditEvent {
  final StructureItem newCurrentItem;

  const NoteEditStructureChanged({required this.newCurrentItem});
}

class NoteEditNavigatedBack extends NoteEditEvent {
  const NoteEditNavigatedBack();
}

class NoteEditDropDownMenuSelected extends NoteEditEvent {
  final int index;

  const NoteEditDropDownMenuSelected({required this.index});
}

class NoteEditInputStatusChanged extends NoteEditEvent {
  final EventAction action;

  const NoteEditInputStatusChanged({required this.action});
}
