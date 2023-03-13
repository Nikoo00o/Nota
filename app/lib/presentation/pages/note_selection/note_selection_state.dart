import 'package:app/domain/entities/structure_item.dart';
import 'package:app/presentation/widgets/base_pages/page_state.dart';

class NoteSelectionState extends PageState {
  const NoteSelectionState([super.properties = const <String, Object?>{}]);
}

class NoteSelectionStateInitialised extends NoteSelectionState {
  final StructureItem currentItem;

  NoteSelectionStateInitialised({
    required this.currentItem,
  }) : super(<String, Object?>{
          "currentItem": currentItem,
        });
}
