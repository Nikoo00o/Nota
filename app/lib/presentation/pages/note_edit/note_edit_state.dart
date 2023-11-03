import 'package:app/domain/entities/structure_note.dart';
import 'package:app/presentation/widgets/base_note/base_note_state.dart';
import 'package:app/presentation/widgets/base_note/note_popup_menu.dart';

base class NoteEditState extends BaseNoteState {
  final bool isEditing;
  final String currentSearchPosition;
  final String searchPositionSize;

  /// This is only needed to rebuild the state
  final int searchLength;

  NoteEditState({
    required super.dropDownMenuParams,
    required super.currentItem,
    required super.isFavourite,
    required this.isEditing,
    required this.currentSearchPosition,
    required this.searchPositionSize,
    required this.searchLength,
  }) : super(properties: <String, Object?>{
          "isEditing": isEditing,
          "currentSearchPosition": currentSearchPosition,
          "searchPositionSize": searchPositionSize,
          "searchLength": searchLength,
        });

  /// the initial state
  factory NoteEditState.initial() {
    return NoteEditState(
      dropDownMenuParams: const <NoteDropDownMenuParam>[],
      currentItem: null,
      isFavourite: false,
      isEditing: false,
      currentSearchPosition: "",
      searchPositionSize: "",
      searchLength: 0,
    );
  }

  /// This returns the [currentItem] without checks, so this can throw an exception!
  ///
  /// Its best to check [isInitialized] first!
  StructureNote get currentNote => currentItem as StructureNote;

  @override
  bool get isInitialized => dropDownMenuParams.isNotEmpty && currentItem is StructureNote;
}
