import 'package:app/presentation/widgets/base_pages/page_state.dart';
import 'package:shared/core/enums/log_level.dart';
import 'package:shared/core/utils/logger/log_message.dart';

base class LogsState extends PageState {
  const LogsState([super.properties = const <String, Object?>{}]);
}

final class LogsStateInitialised extends LogsState {
  final List<LogMessage> logMessages;
  final LogLevel filterLevel;
  final int currentLogLevelIndex;
  final String searchText;

  LogsStateInitialised({
    required this.logMessages,
    required this.filterLevel,
    required this.currentLogLevelIndex,
    required this.searchText,
  }) : super(<String, Object?>{
          "logMessages": logMessages,
          "filterLevel": filterLevel,
          "currentLogLevelIndex": currentLogLevelIndex,
          "searchText": searchText,
        });
}
