import 'package:app/domain/entities/translation_string.dart';
import 'package:app/presentation/widgets/base_note/base_note_bloc.dart';
import 'package:app/presentation/widgets/base_note/base_note_event.dart';
import 'package:app/presentation/widgets/base_note/base_note_state.dart';
import 'package:app/presentation/widgets/base_pages/bloc_page_child.dart';
import 'package:flutter/material.dart';

/// Used inside of the blocs state to create the different popup menu buttons as a list
class NoteDropDownMenuParam {
  /// if the button is enabled
  final bool isEnabled;

  /// contains the translation string for the menu entry
  final TranslationString translationString;

  /// this is the callback method that should be called if this popup menu button is clicked.
  ///
  /// no loading indicator is shown during this, but a state will automatically be emitted afterwards
  final Future<void> Function() callback;

  const NoteDropDownMenuParam({
    required this.isEnabled,
    required this.translationString,
    required this.callback,
  });
}

/// displays the popup menu with the list of popup menu buttons depending on the current state of the shared base
/// bloc! the [BaseNoteDropDownMenuSelected] contains the zero based index of the menu popup button that was clicked
final class NotePopupMenu<Bloc extends BaseNoteBloc<State>, State extends BaseNoteState>
    extends BlocPageChild<Bloc, State> {
  const NotePopupMenu();

  @override
  Widget buildWithNoState(BuildContext context, Widget partWithState) {
    return createBlocSelector<List<NoteDropDownMenuParam>>(
      selector: (BaseNoteState state) => state.dropDownMenuParams,
      builder: (BuildContext context, List<NoteDropDownMenuParam> params) {
        if (params.isNotEmpty) {
          int counter = 0;
          final List<PopupMenuItem<int>> items = params.map((NoteDropDownMenuParam p) {
            final String text = translate(
              context,
              p.translationString.translationKey,
              keyParams: p.translationString.translationKeyParams,
            );
            return PopupMenuItem<int>(
              value: counter++,
              enabled: p.isEnabled,
              child: Text(text),
            );
          }).toList();

          return PopupMenuButton<int>(
            onSelected: (int value) => currentBloc(context).add(BaseNoteDropDownMenuSelected(index: value)),
            itemBuilder: (BuildContext context) => items,
          );
        } else {
          return const SizedBox();
        }
      },
    );
  }
}
