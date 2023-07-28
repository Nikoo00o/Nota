import 'package:hive/hive.dart';
import 'package:shared/core/enums/log_level.dart';

part 'log_message.g.dart';

@HiveType(typeId: 1)
class LogMessage extends HiveObject {
  @HiveField(0)
  final String? message;
  @HiveField(1)
  final LogLevel level;
  @HiveField(2)
  final DateTime timestamp;
  @HiveField(3)
  final String? error;
  @HiveField(4)
  final String? stackTrace;

  /// Only print these first stack trace lines and not spam the log with the full stack trace.
  /// They are taken from beginning and end!
  static const int stackTraceLines = 16;

  LogMessage({
    this.message,
    required this.level,
    required this.timestamp,
    this.error,
    this.stackTrace,
  });

  String get _formattedTime {
    final String hour = timestamp.hour.toString().padLeft(2, "0");
    final String minutes = timestamp.minute.toString().padLeft(2, "0");
    final String second = timestamp.second.toString().padLeft(2, "0");
    final String millisecond = timestamp.millisecond.toString().padLeft(3, "0");
    return "$hour:$minutes:$second.$millisecond";
  }

  @override
  String toString() {
    final StringBuffer buffer = StringBuffer();
    buffer.write("$_formattedTime $level: ");
    if (message != null) {
      buffer.write(message);
    }
    if (error != null) {
      buffer.write("\nException: $error");
    }
    if (stackTrace != null) {
      final String stackTraceText = stackTrace!.toString();
      final List<String> lines = stackTraceText.split("\n");
      if (lines.length > stackTraceLines) {
        _write(lines.take(stackTraceLines ~/ 2), buffer);
        _write(lines.sublist(lines.length - stackTraceLines ~/ 2), buffer);
      } else {
        _write(lines, buffer);
      }
    }
    return buffer.toString();
  }

  void _write(Iterable<String> lines, StringBuffer buffer) {
    for (final String line in lines) {
      buffer.write("\n$line");
    }
  }

  /// If this log [level] could be logged for the [targetLevel]!
  bool canLog(LogLevel targetLevel) => level.index <= targetLevel.index;
}
