// ✅ Cleaned and efficient item_service.dart

import 'package:hive/hive.dart';
import '../enums/stock_movement_type.dart';
import '../models/item_model.dart';
import '../models/stock_movement.dart';

class ItemService {
  static final Box<Item> _itemBox = Hive.box<Item>('itemsBox');
  static final Box<StockMovement> _movementBox = Hive.box<StockMovement>('stockMovements');

  // Get item by ID safely
  static Item? getItemById(String id) {
    try {
      return _itemBox.values.firstWhere((item) => item.id == id);
    } catch (e) {
      print('❌ Item not found: $id');
      return null;
    }
  }

  // Update stock based on movement type
  static void updateStock({
    required String itemId,
    required double quantity,
    required StockMovementType movementType,
    required DateTime date,
    String? referenceId,
    String? narration,
  }) {
    final item = getItemById(itemId);
    if (item == null) return;

    double newStock = item.currentStock;

    switch (movementType) {
      case StockMovementType.purchase:
      case StockMovementType.purchaseReturn:
      case StockMovementType.productionIn:
      case StockMovementType.returnIn:
        newStock += quantity.abs();
        break;

      case StockMovementType.sale:
      case StockMovementType.salesReturn:
      case StockMovementType.productionOut:
      case StockMovementType.returnOut:
        newStock -= quantity.abs();
        break;

      case StockMovementType.openingStock:
        newStock = quantity;
        break;
        
      case StockMovementType.adjustment:
        newStock += quantity; // Can be positive or negative
        break;
    }

    item.currentStock = newStock;
    item.save();

    final movement = StockMovement(
      itemId: itemId,
      quantity: quantity,
      dateTime: date,
      type: movementType,
      referenceId: referenceId ?? 'system',
      narration: narration ?? movementType.name,
    );

    _movementBox.add(movement);
    print('📦 Stock updated for ${item.name}: $newStock');
  }

  // Initialize item with opening stock
  static void addNewItem(Item item) {
    item.currentStock = item.openingStock;
    _itemBox.add(item);
  }

  // Get current stock
  static double getCurrentStock(String itemId) {
    final item = getItemById(itemId);
    return item?.currentStock ?? 0.0;
  }

  // List all stock movements for an item
  static List<StockMovement> getStockLedger(String itemId) {
    return _movementBox.values
        .where((m) => m.itemId == itemId)
        .toList()
      ..sort((a, b) => a.dateTime.compareTo(b.dateTime));
  }
}
