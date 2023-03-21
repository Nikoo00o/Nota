// GENERATED CODE - DO NOT MODIFY BY HAND

// ignore_for_file: always_specify_types

part of 'log_message.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class LogMessageAdapter extends TypeAdapter<LogMessage> {
  @override
  final int typeId = 1;

  @override
  LogMessage read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return LogMessage(
      message: fields[0] as String?,
      level: fields[1] as LogLevel,
      timestamp: fields[2] as DateTime,
      error: fields[3] as String?,
      stackTrace: fields[4] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, LogMessage obj) {
    writer
      ..writeByte(5)
      ..writeByte(0)
      ..write(obj.message)
      ..writeByte(1)
      ..write(obj.level)
      ..writeByte(2)
      ..write(obj.timestamp)
      ..writeByte(3)
      ..write(obj.error)
      ..writeByte(4)
      ..write(obj.stackTrace);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is LogMessageAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
