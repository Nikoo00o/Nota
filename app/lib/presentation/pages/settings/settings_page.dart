import 'package:app/core/constants/routes.dart';
import 'package:app/core/get_it.dart';
import 'package:app/presentation/main/menu/logged_in_menu.dart';
import 'package:app/presentation/pages/settings/settings_bloc.dart';
import 'package:app/presentation/pages/settings/settings_event.dart';
import 'package:app/presentation/pages/settings/settings_state.dart';
import 'package:app/presentation/widgets/base_pages/bloc_page.dart';
import 'package:app/services/navigation_service.dart';
import 'package:flutter/material.dart';

class SettingsPage extends BlocPage<SettingsBloc, SettingsState> {
  const SettingsPage() : super();

  @override
  SettingsBloc createBloc(BuildContext context) {
    return sl<SettingsBloc>()..add(const SettingsEventInitialise());
  }

  @override
  Widget buildBodyWithState(BuildContext context, SettingsState state) {
    return SingleChildScrollView(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          FilledButton(
            onPressed: () => currentBloc(context).add(const SettingsEventLogout()),
            child: Text(translate("page.settings.logout")),
          ),
          FilledButton(
            onPressed: () {
              sl<NavigationService>().navigateTo(Routes.dialog_test);
            },
            child: const Text("to dialog test"),
          ),
          FilledButton(
            onPressed: () {
              sl<NavigationService>().navigateTo(Routes.splash_screen_test);
            },
            child: const Text("to splash screen test"),
          ),
          FilledButton(
            onPressed: () {
              sl<NavigationService>().navigateTo(Routes.material_color_test);
            },
            child: const Text("to color test"),
          ),
        ],
      ),
    );
  }

  @override
  PreferredSizeWidget? buildAppBar(BuildContext context) {
    return AppBar(
      title: Text(translate("page.settings.title")),
      centerTitle: false,
    );
  }

  @override
  Widget? buildMenuDrawer(BuildContext context) {
    return const LoggedInMenu();
  }

  @override
  Future<bool> customBackNavigation(BuildContext context) async {
    sl<NavigationService>().navigateTo(Routes.notes);
    return false;
  }

  @override
  String get pageName => "settings";
}
