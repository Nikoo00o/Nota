import 'dart:math';

import 'package:app/core/constants/routes.dart';
import 'package:app/core/get_it.dart';
import 'package:app/domain/entities/translation_string.dart';
import 'package:app/presentation/main/menu/logged_in_menu.dart';
import 'package:app/presentation/pages/logs/logs_bloc.dart';
import 'package:app/presentation/pages/logs/logs_event.dart';
import 'package:app/presentation/pages/logs/logs_state.dart';
import 'package:app/presentation/pages/settings/widgets/settings_selection_option.dart';
import 'package:app/presentation/widgets/base_pages/bloc_page.dart';
import 'package:app/services/navigation_service.dart';
import 'package:flutter/material.dart';
import 'package:shared/core/enums/log_level.dart';
import 'package:shared/core/utils/logger/log_color.dart';
import 'package:shared/core/utils/logger/log_message.dart';
import 'package:shared/core/utils/logger/logger.dart';

class LogsPage extends BlocPage<LogsBloc, LogsState> {
  const LogsPage() : super();

  @override
  LogsBloc createBloc(BuildContext context) {
    return sl<LogsBloc>()..add(const LogsEventInitialise());
  }

  @override
  Widget buildBodyWithNoState(BuildContext context, Widget bodyWithState) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: <Widget>[
        createBlocBuilder(builder: _buildLogLevelSelection),
        const SizedBox(height: 5),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: <Widget>[
            Padding(
              padding: const EdgeInsets.fromLTRB(10, 0, 0, 0),
              child: Text(translate(context, "page.logs.filtered"), style: textLabelLarge(context)),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(0, 0, 10, 0),
              child: createBlocBuilder(builder: _buildFilterDropDown),
            ),
          ],
        ),
        Expanded(
          child: Scrollbar(
            controller: currentBloc(context).scrollController,
            child: bodyWithState,
          ),
        )
      ],
    );
  }

  Widget _buildLogLevelSelection(BuildContext context, LogsState state) {
    if (state is LogsStateInitialised) {
      return SettingsSelectionOption(
        titleKey: "page.logs.choose.title",
        descriptionKey: "page.logs.choose.description",
        descriptionKeyParams: <String>[LogLevel.values.elementAt(state.currentLogLevelIndex).toString()],
        icon: Icons.filter_5,
        dialogTitleKey: "log.level",
        initialOptionIndex: state.currentLogLevelIndex,
        options: LogLevel.values
            .map((LogLevel level) => TranslationString("empty.param.1", translationKeyParams: <String>[level.toString()]))
            .toList(),
        onSelected: (int index) => currentBloc(context).add(LogsEventChangeLogLevel(newLogLevelIndex: index)),
      );
    } else {
      return const SizedBox();
    }
  }

  Widget _buildFilterDropDown(BuildContext context, LogsState state) {
    if (state is LogsStateInitialised) {
      return DropdownButton<LogLevel>(
        value: state.filterLevel,
        //isDense: true,
        items: List<DropdownMenuItem<LogLevel>>.generate(
          LogLevel.values.length,
          (int index) => DropdownMenuItem<LogLevel>(
            value: LogLevel.values.elementAt(index),
            child: Text(LogLevel.values.elementAt(index).toString(), style: textLabelMedium(context)),
          ),
        ),
        onChanged: (LogLevel? logLevel) => currentBloc(context).add(LogsEventFilterLogLevel(logLevel: logLevel)),
      );
    } else {
      return const SizedBox();
    }
  }

  @override

  /// builds the list view of the log entries
  Widget buildBodyWithState(BuildContext context, LogsState state) {
    if (state is LogsStateInitialised) {
      return ListView.builder(
        controller: currentBloc(context).scrollController,
        itemCount: state.logMessages.length,
        itemBuilder: (BuildContext context, int index) {
          final LogMessage logMessage = state.logMessages.elementAt(state.logMessages.length - index - 1);
          final LogColor logColor = Logger.getLogColorForMessage(logMessage)!;

          return Padding(
            padding: const EdgeInsets.fromLTRB(0, 2, 0, 2),
            child: Card(
              elevation: 3,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(4, 4, 4, 4),
                child: Text(
                  logMessage.toString(),
                  style: textBodyMedium(context).copyWith(color: Color.fromRGBO(logColor.r, logColor.g, logColor.b, 1.0)),
                ),
              ),
            ),
          );
        },
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
