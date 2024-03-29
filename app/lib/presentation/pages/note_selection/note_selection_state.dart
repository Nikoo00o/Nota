import 'package:app/core/enums/search_status.dart';
import 'package:app/domain/entities/structure_folder.dart';
import 'package:app/presentation/widgets/base_pages/page_state.dart';

base class NoteSelectionState extends PageState {
  const NoteSelectionState([super.properties = const <String, Object?>{}]);
}

final class NoteSelectionStateInitialised extends NoteSelectionState {
  final StructureFolder currentFolder;
  final SearchStatus searchStatus;
  final String? searchInput;

  /// only used for extended search
  final Map<int, String>? noteContentMap;

  /// Used to display a sync indicator symbol for edited notes since the last transfer
  final DateTime lastNoteTransferTime;

  /// if this is currently marked as favourite
  final bool isFavourite;

  NoteSelectionStateInitialised({
    required this.currentFolder,
    required this.searchStatus,
    required this.searchInput,
    required this.noteContentMap,
    required this.lastNoteTransferTime,
    required this.isFavourite,
  }) : super(<String, Object?>{
          "currentFolder": currentFolder,
          "searchStatus": searchStatus,
          "searchInput": searchInput,
          "noteContentMap": noteContentMap,
          "lastNoteTransferTime": lastNoteTransferTime,
          "isFavourite": isFavourite,
        });
}
