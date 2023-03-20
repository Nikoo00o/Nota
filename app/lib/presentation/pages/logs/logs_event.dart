import 'package:app/presentation/widgets/base_pages/page_event.dart';
import 'package:shared/core/enums/log_level.dart';

abstract class LogsEvent extends PageEvent {
  const LogsEvent();
}

class LogsEventInitialise extends LogsEvent {
  const LogsEventInitialise();
}

class LogsEventChangeLogLevel extends LogsEvent {
  final int newLogLevelIndex;

  const LogsEventChangeLogLevel({required this.newLogLevelIndex});
}

class LogsEventFilterLogLevel extends LogsEvent {
  final LogLevel? logLevel;

  const LogsEventFilterLogLevel({required this.logLevel});
}
