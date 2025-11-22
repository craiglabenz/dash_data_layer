// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'hive_adapters.dart';

// **************************************************************************
// AdaptersGenerator
// **************************************************************************

class ClickAdapter extends TypeAdapter<Click> {
  @override
  final typeId = 0;

  @override
  Click read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Click(
      delta: (fields[0] as num).toInt(),
      clickedAt: fields[1] as DateTime,
    );
  }

  @override
  void write(BinaryWriter writer, Click obj) {
    writer
      ..writeByte(2)
      ..writeByte(0)
      ..write(obj.delta)
      ..writeByte(1)
      ..write(obj.clickedAt);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ClickAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
