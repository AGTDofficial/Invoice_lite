// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'stock_movement.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class StockMovementAdapter extends TypeAdapter<StockMovement> {
  @override
  final int typeId = 101;

  @override
  StockMovement read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return StockMovement(
      itemId: fields[0] as String,
      quantity: fields[1] as double,
      dateTime: fields[2] as DateTime,
      referenceId: fields[3] as String,
      type: fields[4] as StockMovementType,
      balance: fields[5] as double?,
    );
  }

  @override
  void write(BinaryWriter writer, StockMovement obj) {
    writer
      ..writeByte(6)
      ..writeByte(0)
      ..write(obj.itemId)
      ..writeByte(1)
      ..write(obj.quantity)
      ..writeByte(2)
      ..write(obj.dateTime)
      ..writeByte(3)
      ..write(obj.referenceId)
      ..writeByte(4)
      ..write(obj.type)
      ..writeByte(5)
      ..write(obj.balance);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is StockMovementAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
