import 'dart:async';

import 'package:app/core/get_it.dart';
import 'package:app/domain/entities/structure_item.dart';
import 'package:app/domain/entities/translation_string.dart';
import 'package:app/presentation/widgets/base_note/base_note_bloc.dart';
import 'package:app/presentation/widgets/base_note/base_note_event.dart';
import 'package:app/presentation/widgets/base_note/base_note_state.dart';
import 'package:app/presentation/widgets/base_note/note_favourite_toggle.dart';
import 'package:app/presentation/widgets/base_note/note_popup_menu.dart';
import 'package:app/presentation/widgets/base_pages/bloc_page.dart';
import 'package:flutter/material.dart';

/// this is the shared page super class for all note pages. the bloc is already created for the bloc provider inside
/// of here and the [BaseNoteInitialized] event is added!
///
/// Use the methods [buildTitleAppBar] and [buildBackButton] in the subclass build methods!
abstract base class BaseNotePage<Bloc extends BaseNoteBloc<State>, State extends BaseNoteState>
    extends BlocPage<Bloc, State> {
  const BaseNotePage({
    super.key,
    super.backGroundImage,
    super.backgroundColor,
    super.pagePadding,
  });

  @override
  Bloc createBloc(BuildContext context) {
    return sl<Bloc>()..add(const BaseNoteInitialized());
  }

  /// this builds the title app bar and assumes that the state is initialized. this may include [withBackButton], see
  /// [buildBackButton]
  PreferredSizeWidget buildTitleAppBar(
    BuildContext context,
    StructureItem currentItem, {
    required bool withBackButton,
  }) {
    final TranslationString translation = StructureItem.getTranslationStringForStructureItem(currentItem);
    return AppBar(
      leading: withBackButton ? buildBackButton(context) : null,
      title: Text(
        translate(context, translation.translationKey, keyParams: translation.translationKeyParams),
        overflow: TextOverflow.fade,
        style: textTitleLarge(context).copyWith(fontWeight: FontWeight.bold),
      ),
      centerTitle: false,
      titleSpacing: 8,
      actions: <Widget>[
        NoteFavouriteToggle<Bloc, State>(),
        NotePopupMenu<Bloc, State>(),
      ],
    );
  }

  Widget buildBackButton(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.arrow_back),
      tooltip: translate(context, "back"),
      onPressed: () => currentBloc(context).add(const BaseNoteBackPressed(shouldPopNavigationStack: null)),
    );
  }

  @override
  Future<bool> customBackNavigation(BuildContext context) async {
    final Completer<bool> completer = Completer<bool>();
    currentBloc(context).add(BaseNoteBackPressed(shouldPopNavigationStack: completer));
    return completer.future;
  }
}
