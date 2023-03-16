import 'package:app/domain/entities/structure_folder.dart';
import 'package:app/domain/entities/structure_item.dart';
import 'package:app/presentation/widgets/base_pages/page_state.dart';

class NoteSelectionState extends PageState {
  const NoteSelectionState([super.properties = const <String, Object?>{}]);
}

class NoteSelectionStateInitialised extends NoteSelectionState {
  final StructureFolder currentFolder;

  NoteSelectionStateInitialised({
    required this.currentFolder,
  }) : super(<String, Object?>{
          "currentFolder": currentFolder,
        });
}
