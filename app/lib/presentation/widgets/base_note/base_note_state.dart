import 'package:app/domain/entities/structure_item.dart';
import 'package:app/presentation/widgets/base_note/note_popup_menu.dart';
import 'package:app/presentation/widgets/base_pages/page_state.dart';

/// shared super class for all states of the note related pages (note selection and the note edit pages)
abstract base class BaseNoteState extends PageState {
  /// this is only set once after it was empty for the initial state. when this is not empty, then the state is
  /// initialized
  final List<NoteDropDownMenuParam> dropDownMenuParams;

  /// The current item which can be either a note, or a folder (only at first if initialized is false, then this is
  /// null!)
  ///
  /// Its fine to use this as a reference inside of the state and not to copy it on building the state, because the
  /// bloc always receives a new reference from the update stream from the repository!
  final StructureItem? currentItem;

  /// if this current item is currently marked as favourite
  final bool isFavourite;

  BaseNoteState({
    required this.dropDownMenuParams,
    required this.currentItem,
    required this.isFavourite,
    Map<String, Object?> properties = const <String, Object?>{},
  }) : super(<String, Object?>{
          "dropDownMenuParams": dropDownMenuParams,
          "currentItem": currentItem,
          "isFavourite": isFavourite,
          ...properties,
        });

  /// returns if this is not the first initial state (so the bloc has been initialized). it checks if the
  /// [dropDownMenuParams] are not empty and also if the [currentItem] is of the correct type for the states
  bool get isInitialized;
}
