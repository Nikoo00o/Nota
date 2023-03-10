import 'package:app/core/constants/routes.dart';
import 'package:app/core/get_it.dart';
import 'package:app/presentation/main/dialog_overlay/dialog_overlay_bloc.dart';
import 'package:app/presentation/pages/note_selection/note_selection_bloc.dart';
import 'package:app/presentation/pages/note_selection/note_selection_event.dart';
import 'package:app/presentation/pages/note_selection/note_selection_state.dart';
import 'package:app/presentation/widgets/base_pages/bloc_page.dart';
import 'package:app/services/dialog_service.dart';
import 'package:app/services/navigation_service.dart';
import 'package:flutter/material.dart';
import 'package:shared/core/utils/logger/logger.dart';

class NoteSelectionPage extends BlocPage<NoteSelectionBloc, NoteSelectionState> {
  const NoteSelectionPage() : super();

  @override
  NoteSelectionBloc createBloc(BuildContext context) {
    return sl<NoteSelectionBloc>()..add(const NoteSelectionEventInitialise());
  }

  @override
  Widget buildBodyWithState(BuildContext context, NoteSelectionState state) {
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
          onPressed: () {
            sl<DialogOverlayBloc>().add(ShowInfoSnackBar(textKey: "some long long info text yay"));
          },
          child: Text("test snack"),
        ),
        FilledButton(
          onPressed: () {
            sl<DialogOverlayBloc>().add(ShowInfoDialog(descriptionKey: "some long description, yay"));
          },
          child: Text("test info dialog"),
        ),
        FilledButton(
          onPressed: () async {
            sl<DialogOverlayBloc>().add(ShowLoadingDialog());
            await Future<void>.delayed(Duration(seconds: 4));
            sl<DialogOverlayBloc>().add(HideLoadingDialog());
          },
          child: Text("test loading dialog"),
        ),
        FilledButton(
          onPressed: () async {
            sl<DialogService>().show(ShowErrorDialog(descriptionKey: "errorrororororoor"));
          },
          child: Text("test error dialog "),
        ),
        FilledButton(
          onPressed: () async {
            sl<DialogService>().show(ShowConfirmDialog(
              descriptionKey: "confirm this",
              onConfirm: () {
                Logger.verbose("CONFIRMED");
              },
              onCancel: () {
                Logger.verbose("CANCELLED");
              },
            ));
          },
          child: Text("test confirm dialog "),
        ),
      ],
    );
  }

  @override
  PreferredSizeWidget? buildAppBar(BuildContext context) => createAppBarWithState(context);

  @override
  PreferredSizeWidget buildAppBarWithState(BuildContext context, NoteSelectionState state) {
    return AppBar(
      title: Text(translate("page.note_selection.title")),
      centerTitle: false,
    );
  }

  @override
  Widget? buildMenuDrawer(BuildContext context) {
    // todo: continue here and make own class
    return Container(
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
