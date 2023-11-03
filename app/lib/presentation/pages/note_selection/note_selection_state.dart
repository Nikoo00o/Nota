import 'package:app/core/enums/search_status.dart';
import 'package:app/domain/entities/structure_folder.dart';
import 'package:app/presentation/widgets/base_note/base_note_state.dart';
import 'package:app/presentation/widgets/base_note/note_popup_menu.dart';

base class NoteSelectionState extends BaseNoteState {
  final SearchStatus searchStatus;
  final String? searchInput;

  /// only used for extended search
  final Map<int, String>? noteContentMap;

  /// Used to display a sync indicator symbol for edited notes since the last transfer
  final DateTime lastNoteTransferTime;

  NoteSelectionState({
    required super.dropDownMenuParams,
    required super.currentItem,
    required super.isFavourite,
    required this.searchStatus,
    required this.searchInput,
    required this.noteContentMap,
    required this.lastNoteTransferTime,
  }) : super(properties: <String, Object?>{
          "searchStatus": searchStatus,
          "searchInput": searchInput,
          "noteContentMap": noteContentMap,
          "lastNoteTransferTime": lastNoteTransferTime,
        });

  /// the initial state
  factory NoteSelectionState.initial() {
    return NoteSelectionState(
      dropDownMenuParams: const <NoteDropDownMenuParam>[],
      currentItem: null,
      isFavourite: false,
      searchStatus: SearchStatus.DISABLED,
      searchInput: null,
      noteContentMap: null,
      lastNoteTransferTime: DateTime.now(),
    );
  }

  /// This returns the [currentItem] without checks, so this can throw an exception!
  ///
  /// Its best to check [isInitialized] first!
  StructureFolder get currentFolder => currentItem as StructureFolder;

  @override
  bool get isInitialized => dropDownMenuParams.isNotEmpty && currentItem is StructureFolder;
}
