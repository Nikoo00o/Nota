import 'package:app/core/constants/routes.dart';
import 'package:app/core/get_it.dart';
import 'package:app/presentation/pages/note_selection/note_selection_bloc.dart';
import 'package:app/presentation/pages/note_selection/note_selection_event.dart';
import 'package:app/presentation/pages/note_selection/note_selection_state.dart';
import 'package:app/presentation/widgets/base_pages/simple_bloc_page.dart';
import 'package:app/presentation/widgets/nota_icon.dart';
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
    return Column(
      mainAxisAlignment: MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        FilledButton(
          onPressed: () {
            sl<NavigationService>().navigateTo(Routes.settings);
          },
          child: Text("to settings"),
        ),
        FilledButton(
          onPressed: () {
            sl<NavigationService>().navigateTo(Routes.material_color_test);
          },
          child: Text("to color test"),
        ),
        FilledButton(
          onPressed: () {},
          child: Text("test error dialog"),
        ),
      ],
    );
  }

  @override
  PreferredSizeWidget? buildAppBar(BuildContext context, NoteSelectionState state) {
    return AppBar(
      title: Text(translate("page.note_selection.title")),
      centerTitle: false,
    );
  }

  @override
  Widget? buildMenuDrawer(BuildContext context, NoteSelectionState state) {
    // todo: continue here and make own class
    return Container(
      color: theme(context).scaffoldBackgroundColor,
      width: MediaQuery.of(context).size.width * 3 / 4,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: const <Widget>[
          Text("page.menu.title"),
        ],
      ),
    );
  }

  @override
  String get pageName => "note selection";
}
