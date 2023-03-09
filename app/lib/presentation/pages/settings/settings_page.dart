import 'package:app/core/get_it.dart';
import 'package:app/presentation/pages/settings/settings_bloc.dart';
import 'package:app/presentation/pages/settings/settings_event.dart';
import 'package:app/presentation/pages/settings/settings_state.dart';
import 'package:app/presentation/widgets/base_pages/bloc_page.dart';
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
          )
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
  String get pageName => "settings";
}
