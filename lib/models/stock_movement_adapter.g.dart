// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'stock_movement_adapter.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class StockMovementAdapterAdapter extends TypeAdapter<StockMovementAdapter> {
  @override
  final int typeId = 101;

  @override
  StockMovementAdapter read(BinaryReader reader) {
    return StockMovementAdapter();
  }

  @override
  void write(BinaryWriter writer, StockMovementAdapter obj) {
    writer.writeByte(0);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is StockMovementAdapterAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
