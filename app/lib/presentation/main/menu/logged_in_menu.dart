import 'package:app/core/get_it.dart';
import 'package:app/presentation/main/menu/menu_bloc.dart';
import 'package:app/presentation/main/menu/menu_event.dart';
import 'package:app/presentation/main/menu/menu_state.dart';
import 'package:app/presentation/widgets/base_pages/bloc_page.dart';
import 'package:flutter/material.dart';

/// The side menu drawer that is displayed on every page except on the login page!
class LoggedInMenu extends BlocPage<MenuBloc, MenuState> {
  const LoggedInMenu();

  @override
  MenuBloc createBloc(BuildContext context) {
    return sl<MenuBloc>()..add(const MenuEventInitialise());
  }

  @override
  Widget build(BuildContext context) {
    // overridden because the menu should not contain a scaffold!
    return createBlocProvider(buildBodyWithNoState(
      context,
      createBlocBuilder(
        builder: (BuildContext context, MenuState state) {
          return buildBodyWithState(context, state);
        },
      ),
    ));
  }

  @override
  Widget buildBodyWithNoState(BuildContext context, Widget bodyWithState) {
    return Container(
      color: theme(context).scaffoldBackgroundColor,
      width: MediaQuery.of(context).size.width * 3 / 4,
      height: MediaQuery.of(context).size.height,
      child: SingleChildScrollView(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.max,
          children: <Widget>[
            const Text("Default Menu with the 'scaffoldBackgroundColor' color"),
            const Text("AppBar has default color"),
            const Text("The containers of the page have the 'background' color"),
            FilledButton(
              onPressed: () {
                closeMenuDrawer(context);
              },
              child: const Text("close menu"),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget buildBodyWithState(BuildContext context, MenuState state) {
    return Container();
  }

  @override
  void closeMenuDrawer(BuildContext context) {
    Navigator.of(context).pop();
  }

  @override
  void openMenuDrawer(BuildContext context) {
    // nothing
  }

  @override
  bool isMenuDrawerOpen(BuildContext context) => true;

  @override
  String get pageName => "menu";
}
