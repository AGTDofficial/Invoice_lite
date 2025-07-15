// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'party.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class PartyAdapter extends TypeAdapter<Party> {
  @override
  final int typeId = 5;

  @override
  Party read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Party(
      name: fields[0] as String,
      type: fields[1] as String,
      gstin: fields[2] as String?,
      phone: fields[3] as String?,
      address: fields[4] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, Party obj) {
    writer
      ..writeByte(5)
      ..writeByte(0)
      ..write(obj.name)
      ..writeByte(1)
      ..write(obj.type)
      ..writeByte(2)
      ..write(obj.gstin)
      ..writeByte(3)
      ..write(obj.phone)
      ..writeByte(4)
      ..write(obj.address);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PartyAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
