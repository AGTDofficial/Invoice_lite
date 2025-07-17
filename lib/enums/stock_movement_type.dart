import 'package:hive/hive.dart';

part 'stock_movement_type.g.dart';

@HiveType(typeId: 200) // Unique typeId for StockMovementType
enum StockMovementType {
  @HiveField(0)
  openingStock,
  @HiveField(1)
  purchase,
  @HiveField(2)
  sale,
  @HiveField(3)
  returnIn,
  @HiveField(4)
  returnOut,
  @HiveField(5)
  productionIn,
  @HiveField(6)
  productionOut,
  @HiveField(7)
  adjustment,
  @HiveField(8)
  salesReturn,
  @HiveField(9)
  purchaseReturn,
}

// Generate adapter using build_runner
