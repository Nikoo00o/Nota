import 'package:app/presentation/pages/logs/logs_bloc.dart';
import 'package:app/presentation/pages/logs/logs_event.dart';
import 'package:app/presentation/pages/logs/logs_state.dart';
import 'package:app/presentation/widgets/base_pages/bloc_page_child.dart';
import 'package:flutter/material.dart';
import 'package:shared/core/enums/log_level.dart';

class FilterLogsBar extends BlocPageChild<LogsBloc, LogsState> {
  const FilterLogsBar();

  @override
  Widget buildWithNoState(BuildContext context, Widget partWithState) {
    return Row(
      children: <Widget>[
        _buildSearchContainer(context),
        SizedBox(
          width: 45,
          height: 40,
          child: TextButton(
            onPressed: () => currentBloc(context).searchFocus.unfocus(),
            child: Text(translate(context, "ok")),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(15, 0, 10, 0),
          child: createBlocBuilder(builder: _buildFilterDropDown),
        ),
      ],
    );
  }

  Widget _buildSearchContainer(BuildContext context) {
    return Flexible(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(10, 0, 5, 0),
        child: Container(
          height: 34.0,
          decoration: BoxDecoration(
            color: colorPrimary(context).withOpacity(0.15),
            borderRadius: BorderRadius.circular(32),
          ),
          padding: const EdgeInsets.only(right: 10),
          child: TextField(
            focusNode: currentBloc(context).searchFocus,
            controller: currentBloc(context).searchController,
            onChanged: (String _) => currentBloc(context).add(const LogsEventUpdateState()),
            decoration: InputDecoration(
              hintText: translate(context, "page.logs.filtered"),
              prefixIcon: const Icon(Icons.search),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.only(bottom: 12),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFilterDropDown(BuildContext context, LogsState state) {
    if (state is LogsStateInitialised) {
      return DropdownButton<LogLevel>(
        value: state.filterLevel,
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
}
