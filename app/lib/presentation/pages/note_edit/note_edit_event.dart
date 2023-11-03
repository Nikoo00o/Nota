import 'package:app/domain/entities/structure_item.dart';
import 'package:app/presentation/widgets/base_note/base_note_event.dart';
import 'package:app/presentation/widgets/base_pages/page_event.dart';

sealed class NoteEditEvent extends BaseNoteEvent {
  const NoteEditEvent();
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