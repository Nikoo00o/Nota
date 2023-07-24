import 'package:app/presentation/widgets/base_pages/page_event.dart';
import 'package:shared/core/enums/log_level.dart';

sealed class LogsEvent extends PageEvent {
  const LogsEvent();
}

final class LogsEventInitialise extends LogsEvent {
  const LogsEventInitialise();
}

final class LogsEventUpdateState extends LogsEvent {
  const LogsEventUpdateState();
}

final class LogsEventChangeLogLevel extends LogsEvent {
  final int newLogLevelIndex;

  const LogsEventChangeLogLevel({required this.newLogLevelIndex});
}

final class LogsEventFilterLogLevel extends LogsEvent {
  final LogLevel? logLevel;

  const LogsEventFilterLogLevel({required this.logLevel});
}
