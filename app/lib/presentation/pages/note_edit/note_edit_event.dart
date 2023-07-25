import 'package:app/domain/entities/structure_item.dart';
import 'package:app/presentation/widgets/base_pages/page_event.dart';

sealed class NoteEditEvent extends PageEvent {
  const NoteEditEvent();
}

final class NoteEditUpdatedState extends NoteEditEvent {
  final bool didSearchChange;

  const NoteEditUpdatedState({required this.didSearchChange});
}

final class NoteEditInitialised extends NoteEditEvent {
  const NoteEditInitialised();
}

final class NoteEditStructureChanged extends NoteEditEvent {
  final StructureItem newCurrentItem;

  const NoteEditStructureChanged({required this.newCurrentItem});
}

final class NoteEditNavigatedBack extends NoteEditEvent {
  const NoteEditNavigatedBack();
}

final class NoteEditDropDownMenuSelected extends NoteEditEvent {
  final int index;

  const NoteEditDropDownMenuSelected({required this.index});
}

final class NoteEditInputSaved extends NoteEditEvent {
  const NoteEditInputSaved();
}

final class NoteEditSearchStepped extends NoteEditEvent {
  final bool forward;

  const NoteEditSearchStepped({required this.forward});
}

final class NoteEditAppPaused extends NoteEditEvent {
  const NoteEditAppPaused();
}

final class NoteEditChangeFavourite extends NoteEditEvent {
  final bool isFavourite;

  const NoteEditChangeFavourite({required this.isFavourite});
}
