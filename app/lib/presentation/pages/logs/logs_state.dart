import 'package:app/presentation/widgets/base_pages/page_state.dart';
import 'package:shared/core/utils/logger/log_message.dart';

class LogsState extends PageState {
  const LogsState([super.properties = const <String, Object?>{}]);
}

class LogsStateInitialised extends LogsState {
  final List<LogMessage> logMessages;

  LogsStateInitialised({
    required this.logMessages,
  }) : super(<String, Object?>{
          "logMessages": logMessages,
        });
}
