// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'account_group.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class AccountGroupAdapter extends TypeAdapter<AccountGroup> {
  @override
  final int typeId = 1;

  @override
  AccountGroup read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return AccountGroup(
      name: fields[0] as String,
      parentGroup: fields[1] as String?,
      categoryType: fields[2] as String?,
      isInventoryRelated: fields[3] as bool?,
      isSystemGroup: fields[4] as bool?,
    );
  }

  @override
  void write(BinaryWriter writer, AccountGroup obj) {
    writer
      ..writeByte(5)
      ..writeByte(0)
      ..write(obj.name)
      ..writeByte(1)
      ..write(obj.parentGroup)
      ..writeByte(2)
      ..write(obj.categoryType)
      ..writeByte(3)
      ..write(obj.isInventoryRelated)
      ..writeByte(4)
      ..write(obj.isSystemGroup);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AccountGroupAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
