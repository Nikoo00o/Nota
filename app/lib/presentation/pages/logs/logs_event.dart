import 'package:app/presentation/widgets/base_pages/page_event.dart';

abstract class LogsEvent extends PageEvent {
  const LogsEvent();
}

class LogsEventInitialise extends LogsEvent {
  const LogsEventInitialise();
}

class LogsEventChangeLogLevel extends LogsEvent {
  const LogsEventChangeLogLevel();
}

class LogsEventFilterLogLevel extends LogsEvent {
  const LogsEventFilterLogLevel();
}
