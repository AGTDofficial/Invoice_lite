// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'item_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class ItemAdapter extends TypeAdapter<Item> {
  @override
  final int typeId = 22;

  @override
  Item read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Item(
      id: fields[0] as String?,
      name: fields[1] as String,
      itemGroup: fields[2] as String?,
      itemCode: fields[3] as String?,
      unit: fields[4] as String,
      saleRate: fields[5] as double?,
      purchaseRate: fields[6] as double?,
      openingStock: fields[7] as double,
      currentStock: fields[8] as double,
      isStockTracked: fields[9] as bool,
      minStockLevel: fields[10] as double,
      description: fields[12] as String?,
    )
      ..lastUpdated = fields[11] as DateTime?
      ..stockMovements = (fields[16] as List).cast<StockMovement>();
  }

  @override
  void write(BinaryWriter writer, Item obj) {
    writer
      ..writeByte(14)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.name)
      ..writeByte(2)
      ..write(obj.itemGroup)
      ..writeByte(3)
      ..write(obj.itemCode)
      ..writeByte(4)
      ..write(obj.unit)
      ..writeByte(5)
      ..write(obj.saleRate)
      ..writeByte(6)
      ..write(obj.purchaseRate)
      ..writeByte(7)
      ..write(obj.openingStock)
      ..writeByte(8)
      ..write(obj.currentStock)
      ..writeByte(9)
      ..write(obj.isStockTracked)
      ..writeByte(10)
      ..write(obj.minStockLevel)
      ..writeByte(11)
      ..write(obj.lastUpdated)
      ..writeByte(12)
      ..write(obj.description)
      ..writeByte(16)
      ..write(obj.stockMovements);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ItemAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
