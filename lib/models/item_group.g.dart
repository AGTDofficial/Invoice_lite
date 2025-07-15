// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'item_group.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class ItemGroupAdapter extends TypeAdapter<ItemGroup> {
  @override
  final int typeId = 6;

  @override
  ItemGroup read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return ItemGroup(
      name: fields[0] as String,
      parentGroup: fields[1] as String?,
      isSystemGroup: fields[2] == null ? false : fields[2] as bool,
    );
  }

  @override
  void write(BinaryWriter writer, ItemGroup obj) {
    writer
      ..writeByte(3)
      ..writeByte(0)
      ..write(obj.name)
      ..writeByte(1)
      ..write(obj.parentGroup)
      ..writeByte(2)
      ..write(obj.isSystemGroup);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ItemGroupAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
