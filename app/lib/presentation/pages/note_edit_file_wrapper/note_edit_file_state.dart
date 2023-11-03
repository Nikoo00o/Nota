import 'package:app/domain/entities/note_content/note_content.dart';
import 'package:app/domain/entities/structure_note.dart';
import 'package:app/presentation/widgets/base_note/base_note_state.dart';
import 'package:app/presentation/widgets/base_note/note_popup_menu.dart';

base class NoteEditFileState extends BaseNoteState {
  /// the content of the file. this is null if [isInitialized] is false and otherwise it should always contain the
  /// correct data!
  final NoteContentFileWrapper? content;

  NoteEditFileState({
    required super.dropDownMenuParams,
    required super.currentItem,
    required super.isFavourite,
    required this.content,
  }) : super(properties: <String, Object?>{
          "content": content,
        });

  /// the initial state
  factory NoteEditFileState.initial() {
    return NoteEditFileState(
      dropDownMenuParams: const <NoteDropDownMenuParam>[],
      currentItem: null,
      isFavourite: false,
      content: null,
    );
  }

  /// This returns the [currentItem] without checks, so this can throw an exception!
  ///
  /// Its best to check [isInitialized] first!
  StructureNote get currentNote => currentItem as StructureNote;

  @override
  bool get isInitialized => dropDownMenuParams.isNotEmpty && currentItem is StructureNote;
}
