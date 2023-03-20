import 'package:app/core/constants/routes.dart';
import 'package:app/core/get_it.dart';
import 'package:app/domain/entities/translation_string.dart';
import 'package:app/presentation/main/menu/logged_in_menu.dart';
import 'package:app/presentation/pages/logs/logs_bloc.dart';
import 'package:app/presentation/pages/logs/logs_event.dart';
import 'package:app/presentation/pages/logs/logs_state.dart';
import 'package:app/presentation/widgets/base_pages/bloc_page.dart';
import 'package:app/services/navigation_service.dart';
import 'package:flutter/material.dart';

class LogsPage extends BlocPage<LogsBloc, LogsState> {
  const LogsPage() : super();

  @override
  LogsBloc createBloc(BuildContext context) {
    return sl<LogsBloc>()..add(const LogsEventInitialise());
  }

  @override
  Widget buildBodyWithNoState(BuildContext context, Widget bodyWithState) {
    return Scrollbar(
      controller: currentBloc(context).scrollController,
      child: ListView(
        controller: currentBloc(context).scrollController,
        children: <Widget>[
          bodyWithState,
        ],
      ),
    );
  }

  @override
  Widget buildBodyWithState(BuildContext context, LogsState state) {
    if (state is LogsStateInitialised) {
      return Column(
        children: <Widget>[],
      );
    }
    return const SizedBox();
  }

  @override
  PreferredSizeWidget? buildAppBar(BuildContext context) {
    return AppBar(
      title: Text(
        translate(context, "page.logs.title"),
        style: textTitleLarge(context).copyWith(fontWeight: FontWeight.bold),
      ),
      centerTitle: false,
    );
  }

  @override
  Widget? buildMenuDrawer(BuildContext context) {
    return const LoggedInMenu(currentPageTranslationKey: "page.logs.title");
  }

  @override
  Future<bool> customBackNavigation(BuildContext context) async {
    sl<NavigationService>().navigateTo(Routes.note_selection);
    return false;
  }

  @override
  String get pageName => "logs";
}
