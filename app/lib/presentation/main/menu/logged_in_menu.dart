import 'package:app/core/get_it.dart';
import 'package:app/presentation/main/menu/menu_bloc.dart';
import 'package:app/presentation/main/menu/menu_drawer_header.dart';
import 'package:app/presentation/main/menu/menu_event.dart';
import 'package:app/presentation/main/menu/menu_state.dart';
import 'package:app/presentation/widgets/base_pages/bloc_page.dart';
import 'package:app/presentation/widgets/nota_icon.dart';
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
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: <Widget>[
          const MenuDrawerHeader(),
          ListTile(
            title: const Text('Item 1'),
            onTap: () {
              // Update the state of the app.
              // ...
            },
          ),
          ListTile(
            title: const Text('Item 2'),
            onTap: () {
              // Update the state of the app.
              // ...
            },
          ),
          Card(
            child: ListTile(
              title: Text('One-line with trailing widget'),
              leading: Icon(Icons.more_vert),
            ),
          ),
        ],
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
