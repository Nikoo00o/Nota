import 'package:app/core/constants/routes.dart';
import 'package:app/core/get_it.dart';
import 'package:app/domain/entities/translation_string.dart';
import 'package:app/presentation/main/menu/logged_in_menu.dart';
import 'package:app/presentation/pages/settings/settings_bloc.dart';
import 'package:app/presentation/pages/settings/settings_event.dart';
import 'package:app/presentation/pages/settings/settings_state.dart';
import 'package:app/presentation/pages/settings/widgets/settings_custom_option.dart';
import 'package:app/presentation/pages/settings/widgets/settings_input_option.dart';
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
    if (state is SettingsStateInitialised) {
      return Column(
        children: <Widget>[
          SettingsToggleOption(
            titleKey: "page.settings.dark.theme",
            icon: Icons.dark_mode,
            isActive: state.isDarkTheme,
            onChange: (bool value) => currentBloc(context).add(DarkThemeChanged(isDarkTheme: value)),
          ),
          SettingsSelectionOption(
            titleKey: "page.settings.locale",
            icon: Icons.language,
            dialogTitleKey: "language",
            initialOptionIndex: state.localeIndex,
            options: state.localeOptions.map((String key) => TranslationString(key)).toList(),
            onSelected: (int index) => currentBloc(context).add(LocaleChanged(index: index)),
          ),
          SettingsToggleOption(
            titleKey: "page.settings.auto.login",
            descriptionKey: "page.settings.auto.login.description",
            hasBigDescription: true,
            icon: Icons.lock_open,
            isActive: state.autoLogin,
            onChange: (bool value) => currentBloc(context).add(AutoLoginChanged(autoLogin: value)),
          ),
          SettingsInputOption(
            titleKey: "page.settings.lock.screen.timeout",
            descriptionKey: "page.settings.lock.screen.timeout.description",
            descriptionKeyParams: <String>[state.lockscreenTimeoutInSeconds],
            dialogTitleKey: "page.settings.lock.screen.timeout",
            dialogDescriptionKey: "page.settings.lock.screen.timeout.description.dialog",
            dialogInputLabelKey: "dialog.input.label.number",
            hasBigDescription: true,
            icon: Icons.lock_clock,
            disabled: state.autoLogin,
            keyboardType: TextInputType.number,
            validatorCallback: (String? input) => lockscreenTimeoutValidator(input, context),
            onConfirm: (String value) => currentBloc(context).add(LockscreenTimeoutChanged(timeoutInSeconds: value)),
          ),
          SettingsCustomOption(
            titleKey: "page.settings.password",
            descriptionKey: "page.settings.password.description",
            icon: Icons.lock_reset,
            onTap: () => currentBloc(context).add(const NavigatedToChangePasswordPage()),
          ),
        ],
      );
    }
    return const SizedBox();
  }

  String? lockscreenTimeoutValidator(String? input, BuildContext context) {
    if (RegExp(r"^\d+$").hasMatch(input ?? "") == false) {
      return translate(context, "error.only.numbers");
    }
    return null;
  }

  @override
  PreferredSizeWidget? buildAppBar(BuildContext context) {
    return AppBar(
      title: Text(translate(context, "page.settings.title")),
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
