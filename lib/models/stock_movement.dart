import 'package:hive/hive.dart';
import '../enums/stock_movement_type.dart';

part 'stock_movement.g.dart';

@HiveType(typeId: 101)
class StockMovement extends HiveObject {
  @HiveField(0)
  final String itemId;

  @HiveField(1)
  final int quantity;

  @HiveField(2)
  final DateTime dateTime;

  @HiveField(3)
  final String referenceId; // For linking to invoice or other reference

  @HiveField(4)
  final StockMovementType type;

  @HiveField(5)
  final double? balance; // Stock balance after this movement

  StockMovement({
    required this.itemId,
    required this.quantity,
    required this.dateTime,
    required this.referenceId,
    required this.type,
    this.balance,
  });
}
