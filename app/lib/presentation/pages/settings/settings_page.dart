import 'package:app/core/constants/routes.dart';
import 'package:app/core/get_it.dart';
import 'package:app/presentation/main/menu/logged_in_menu.dart';
import 'package:app/presentation/pages/settings/settings_bloc.dart';
import 'package:app/presentation/pages/settings/settings_event.dart';
import 'package:app/presentation/pages/settings/settings_state.dart';
import 'package:app/presentation/pages/settings/widgets/settings_selection_option.dart';
import 'package:app/presentation/pages/settings/widgets/settings_toggle_option.dart';
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
  Widget buildBodyWithNoState(BuildContext context, Widget bodyWithState) {
    return Scrollbar(
      child: ListView(
        children: <Widget>[
          bodyWithState,
        ],
      ),
    );
  }

  @override
  Widget buildBodyWithState(BuildContext context, SettingsState state) {
    if (state is SettingsStateInitialized) {
      return Column(
        children: <Widget>[
          SettingsToggleOption(
            titleKey: "page.settings.dark.theme",
            isActive: state.isDarkTheme,
            onChange: (bool value) => currentBloc(context).add(DarkThemeChanged(isDarkTheme: value)),
          ),
          SettingsSelectionOption(
            titleKey: "page.settings.locale",
            initialOptionIndex: state.localeIndex,
            options: state.localeOptions,
            onSelected: (int index) => currentBloc(context).add(LocaleChanged(index: index)),
          ),
        ],
      );
    }
    return const SizedBox();
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
    return const LoggedInMenu(currentPageTranslationKey: "page.settings.title");
  }

  @override
  Future<bool> customBackNavigation(BuildContext context) async {
    sl<NavigationService>().navigateTo(Routes.notes);
    return false;
  }

  @override
  String get pageName => "settings";
}
