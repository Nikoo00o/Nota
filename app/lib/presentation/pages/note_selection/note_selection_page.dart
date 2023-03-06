import 'package:app/core/constants/routes.dart';
import 'package:app/core/get_it.dart';
import 'package:app/presentation/pages/note_selection/note_selection_bloc.dart';
import 'package:app/presentation/pages/note_selection/note_selection_event.dart';
import 'package:app/presentation/pages/note_selection/note_selection_state.dart';
import 'package:app/presentation/widgets/base_pages/simple_bloc_page.dart';
import 'package:app/services/navigation_service.dart';
import 'package:flutter/material.dart';

class NoteSelectionPage extends SimpleBlocPage<NoteSelectionBloc, NoteSelectionState> {
  const NoteSelectionPage() : super();

  @override
  NoteSelectionBloc createBloc(BuildContext context) {
    return sl<NoteSelectionBloc>()..add(const NoteSelectionEventInitialise());
  }

  @override
  Widget buildBody(BuildContext context, NoteSelectionState state) {
    return SingleChildScrollView(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          FilledButton(
            onPressed: () {
              sl<NavigationService>().navigateTo(Routes.settings);
            },
            child: Text("navigate to settings "),
          ),
          FilledButton(
            onPressed: () {

            },
            child: Text("Dialog test 1 "),
          ),
        ],
      ),
    );
  }

  @override
  PreferredSizeWidget? buildAppBar(BuildContext context, NoteSelectionState state) {
    return AppBar(
      title: Text(
        translate("page.settings.title"),
        style: TextStyle(color: theme(context).colorScheme.onPrimaryContainer),
      ),
      centerTitle: false,
      backgroundColor: theme(context).colorScheme.primaryContainer,
    );
  }

  @override
  String get pageName => "note selection";
}
