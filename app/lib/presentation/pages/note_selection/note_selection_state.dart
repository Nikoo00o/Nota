import 'package:app/core/enums/search_status.dart';
import 'package:app/domain/entities/structure_folder.dart';
import 'package:app/presentation/widgets/base_pages/page_state.dart';

class NoteSelectionState extends PageState {
  const NoteSelectionState([super.properties = const <String, Object?>{}]);
}

class NoteSelectionStateInitialised extends NoteSelectionState {
  final StructureFolder currentFolder;
  final SearchStatus searchStatus;
  final String? searchInput;

  /// only used for extended search
  final Map<int, String>? noteContentMap;

  NoteSelectionStateInitialised({
    required this.currentFolder,
    required this.searchStatus,
    required this.searchInput,
    required this.noteContentMap,
  }) : super(<String, Object?>{
          "currentFolder": currentFolder,
          "searchStatus": searchStatus,
          "searchInput": searchInput,
          "noteContentMap": noteContentMap,
        });
}
