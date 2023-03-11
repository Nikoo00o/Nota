import 'package:app/core/get_it.dart';
import 'package:app/presentation/main/menu/menu_bloc.dart';
import 'package:app/presentation/main/menu/widgets/menu_drawer_developer.dart';
import 'package:app/presentation/main/menu/widgets/menu_drawer_header.dart';
import 'package:app/presentation/main/menu/menu_event.dart';
import 'package:app/presentation/main/menu/menu_state.dart';
import 'package:app/presentation/main/menu/widgets/menu_drawer_settings.dart';
import 'package:app/presentation/main/menu/widgets/menu_item.dart';
import 'package:app/presentation/widgets/base_pages/bloc_page.dart';
import 'package:flutter/material.dart';

/// The side menu drawer that is displayed on every page except on the login page!
class LoggedInMenu extends BlocPage<MenuBloc, MenuState> {
  final String currentPageTranslationKey;
  final List<String>? currentPageTranslationKeyParams;

  const LoggedInMenu({required this.currentPageTranslationKey, this.currentPageTranslationKeyParams});

  @override
  MenuBloc createBloc(BuildContext context) {
    final MenuBloc bloc = sl<MenuBloc>();
    bloc.add(MenuInitialised(
      currentPageTranslationKey: currentPageTranslationKey,
      currentPageTranslationKeyParams: currentPageTranslationKeyParams,
    ));
    return bloc;
  }

  @override
  Widget build(BuildContext context) {
    // overridden because the menu should not contain a scaffold and no custom back navigation!
    return createBlocProvider(
      Builder(builder: (BuildContext context) {
        // important: this wrapped builder is needed, so that the buildPartWithNoState can still access the bloc to send
        // events with the inner build context!
        return buildBodyWithNoState(
          context,
          createBlocBuilder(
            builder: (BuildContext context, MenuState state) {
              return buildBodyWithState(context, state);
            },
          ),
        );
      }),
    );
  }

  @override
  Widget buildBodyWithNoState(BuildContext context, Widget bodyWithState) {
    return Drawer(
      child: Scrollbar(
        scrollbarOrientation: ScrollbarOrientation.left,
        child: ListView(
          padding: EdgeInsets.zero,
          children: <Widget>[
            const MenuDrawerHeader(),
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 8, 0, 8),
              child: Text(translate("menu.notes.label"), style: theme(context).textTheme.titleMedium),
            ),
            const MenuItem(pageTitleKey: "page.note.selection.temp.title"),
            const Divider(),
            const MenuDrawerSettings(),
            bodyWithState,
          ],
        ),
      ),
    );
  }

  @override
  Widget buildBodyWithState(BuildContext context, MenuState state) {
    if (state is MenuStateInitialized && state.showDeveloperOptions) {
      return Column(
        children: const <Widget>[
          Divider(),
          MenuDrawerDeveloper(),
        ],
      );
    } else {
      return const SizedBox();
    }
  }

  @override
  void closeMenuDrawer(BuildContext context) {
    Navigator.of(context).pop();
  }

  @override
  void openMenuDrawer(BuildContext context) {
    // menu will always be open here
  }

  @override
  bool isMenuDrawerOpen(BuildContext context) => true;

  @override
  String get pageName => "menu";
}
