import 'package:app/core/get_it.dart';
import 'package:app/presentation/pages/settings/settings_bloc.dart';
import 'package:app/presentation/pages/settings/settings_event.dart';
import 'package:app/presentation/pages/settings/settings_state.dart';
import 'package:app/presentation/widgets/base_pages/simple_bloc_page.dart';
import 'package:flutter/material.dart';

class SettingsPage extends SimpleBlocPage<SettingsBloc, SettingsState> {
  const SettingsPage() : super();

  @override
  SettingsBloc createBloc(BuildContext context) {
    return sl<SettingsBloc>()..add(const SettingsEventInitialise());
  }

  @override
  Widget buildBody(BuildContext context, SettingsState state) {
    return SingleChildScrollView(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          FilledButton(
            onPressed: () => currentBloc(context).add(const SettingsEventLogout()),
            child: Text(translate("page.settings.logout")),
          )
        ],
      ),
    );
  }

  @override
  PreferredSizeWidget? buildAppBar(BuildContext context, SettingsState state) {
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
  String get pageName => "settings";
}
