// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'log_level.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class LogLevelAdapter extends TypeAdapter<LogLevel> {
  @override
  final int typeId = 0;

  @override
  LogLevel read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return LogLevel.ERROR;
      case 1:
        return LogLevel.WARN;
      case 2:
        return LogLevel.INFO;
      case 3:
        return LogLevel.DEBUG;
      case 4:
        return LogLevel.VERBOSE;
      case 5:
        return LogLevel.SPAM;
      default:
        return LogLevel.ERROR;
    }
  }

  @override
  void write(BinaryWriter writer, LogLevel obj) {
    switch (obj) {
      case LogLevel.ERROR:
        writer.writeByte(0);
        break;
      case LogLevel.WARN:
        writer.writeByte(1);
        break;
      case LogLevel.INFO:
        writer.writeByte(2);
        break;
      case LogLevel.DEBUG:
        writer.writeByte(3);
        break;
      case LogLevel.VERBOSE:
        writer.writeByte(4);
        break;
      case LogLevel.SPAM:
        writer.writeByte(5);
        break;
    }
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is LogLevelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
