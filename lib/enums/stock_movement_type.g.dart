// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'stock_movement_type.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class StockMovementTypeAdapter extends TypeAdapter<StockMovementType> {
  @override
  final int typeId = 200;

  @override
  StockMovementType read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return StockMovementType.openingStock;
      case 1:
        return StockMovementType.purchase;
      case 2:
        return StockMovementType.sale;
      case 3:
        return StockMovementType.returnIn;
      case 4:
        return StockMovementType.returnOut;
      case 5:
        return StockMovementType.productionIn;
      case 6:
        return StockMovementType.productionOut;
      case 7:
        return StockMovementType.adjustment;
      case 8:
        return StockMovementType.salesReturn;
      case 9:
        return StockMovementType.purchaseReturn;
      default:
        return StockMovementType.openingStock;
    }
  }

  @override
  void write(BinaryWriter writer, StockMovementType obj) {
    switch (obj) {
      case StockMovementType.openingStock:
        writer.writeByte(0);
        break;
      case StockMovementType.purchase:
        writer.writeByte(1);
        break;
      case StockMovementType.sale:
        writer.writeByte(2);
        break;
      case StockMovementType.returnIn:
        writer.writeByte(3);
        break;
      case StockMovementType.returnOut:
        writer.writeByte(4);
        break;
      case StockMovementType.productionIn:
        writer.writeByte(5);
        break;
      case StockMovementType.productionOut:
        writer.writeByte(6);
        break;
      case StockMovementType.adjustment:
        writer.writeByte(7);
        break;
      case StockMovementType.salesReturn:
        writer.writeByte(8);
        break;
      case StockMovementType.purchaseReturn:
        writer.writeByte(9);
        break;
    }
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is StockMovementTypeAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
