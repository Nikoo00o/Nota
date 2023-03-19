import 'package:hive/hive.dart';

part 'log_level.g.dart';

/// The type of the log entry (a lower level is more important)
@HiveType(typeId: 0)
enum LogLevel {
  /// 0
  @HiveField(0)
  ERROR,

  /// 1
  @HiveField(1)
  WARN,

  /// 2
  @HiveField(2)
  INFO,

  /// 3
  @HiveField(3)
  DEBUG,

  /// 4
  @HiveField(4)
  VERBOSE;

  @override
  String toString() {
    return name;
  }

  factory LogLevel.fromString(String data) {
    return values.firstWhere((LogLevel element) => element.name == data);
  }
}
