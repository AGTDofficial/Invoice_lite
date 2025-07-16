import 'package:hive/hive.dart';
import 'stock_movement.dart';
import '../enums/stock_movement_type.dart';

part 'stock_movement_adapter.g.dart';

@HiveType(typeId: 101)
class StockMovementAdapter extends TypeAdapter<StockMovement> {
  @override
  StockMovement read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{};
    for (int i = 0; i < numOfFields; i++) {
      fields[reader.readByte()] = reader.read();
    }
    return StockMovement(
      itemId: fields[0] as String,
      quantity: fields[1] as double,
      dateTime: fields[2] as DateTime,
      referenceId: fields[3] as String,
      type: StockMovementType.values[fields[4] as int],
      balance: fields[5] as double?,
    );
  }

  @override
  void write(BinaryWriter writer, StockMovement obj) {
    writer
      ..writeByte(6)
      ..writeByte(0)
      ..write(obj.itemId.toString())
      ..writeByte(1)
      ..write(obj.quantity)
      ..writeByte(2)
      ..write(obj.dateTime)
      ..writeByte(3)
      ..write(obj.referenceId)
      ..writeByte(4)
      ..write(obj.type.index)
      ..writeByte(5)
      ..write(obj.balance);
  }

  @override
  int get typeId => 101;
}
