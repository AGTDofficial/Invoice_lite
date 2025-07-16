import 'package:hive/hive.dart';
import 'package:uuid/uuid.dart';
import '../models/stock_movement.dart';
import '../enums/stock_movement_type.dart';

part 'item_model.g.dart';

// Register the adapters for Hive
void registerHiveAdapters() {
  // Register StockMovementType first since StockMovement depends on it
  if (!Hive.isAdapterRegistered(StockMovementTypeAdapter().typeId)) {
    Hive.registerAdapter(StockMovementTypeAdapter());
  }
  
  // Register StockMovement
  if (!Hive.isAdapterRegistered(StockMovementAdapter().typeId)) {
    Hive.registerAdapter(StockMovementAdapter());
  }
  
  // Finally register Item which depends on both
  if (!Hive.isAdapterRegistered(ItemAdapter().typeId)) {
    Hive.registerAdapter(ItemAdapter());
  }
  
  // Verify adapters are registered
  if (!Hive.isAdapterRegistered(103) ||
      !Hive.isAdapterRegistered(ItemAdapter().typeId)) {
    throw Exception('Failed to register Hive adapters');
  }
}



@HiveType(typeId: 22)
class Item extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  late String name;

  @HiveField(2)
  String? itemGroup;

  @HiveField(3)
  String? itemCode;

  @HiveField(4)
  late String unit;

  @HiveField(5)
  double taxRate = 0.0;

  @HiveField(6)
  String? hsnCode;

  @HiveField(7)
  double? saleRate;

  @HiveField(8)
  double? purchaseRate;

  
  @HiveField(9)
  double openingStock = 0.0;
  
  @HiveField(10)
  double currentStock = 0.0;
  
  @HiveField(11)
  bool isStockTracked = false;
  
  @HiveField(12)
  double minStockLevel = 0.0;
  
  @HiveField(13)
  DateTime? lastUpdated;
  
  @HiveField(14)
  String? barcode;
  
  @HiveField(15)
  String? description;
  
  // For tracking stock movement history
  @HiveField(16)
  List<StockMovement> stockMovements = [];

  Item({
    String? id,
    required String name,
    this.itemGroup,
    this.itemCode,
    this.unit = 'PCS',
    this.taxRate = 0.0,
    this.hsnCode,
    this.saleRate,
    this.purchaseRate,
    this.openingStock = 0.0,
    this.currentStock = 0.0,
    this.isStockTracked = false,
    this.minStockLevel = 0.0,
    this.barcode,
    this.description,
  }) : id = id ?? const Uuid().v4(),
       name = name;

  // Copy with method for easy updates
  Item copyWith({
    String? id,
    String? name,
    String? itemGroup,
    String? itemCode,
    String? unit,
    double? taxRate,
    String? hsnCode,
    double? saleRate,
    double? purchaseRate,
    double? openingStock,
    double? currentStock,
    bool? isStockTracked,
    double? minStockLevel,
    String? barcode,
    String? description,
  }) {
    return Item(
      id: id ?? this.id,
      name: name ?? this.name,
      itemGroup: itemGroup ?? this.itemGroup,
      itemCode: itemCode ?? this.itemCode,
      unit: unit ?? this.unit,
      taxRate: taxRate ?? this.taxRate,
      hsnCode: hsnCode ?? this.hsnCode,
      saleRate: saleRate ?? this.saleRate,
      purchaseRate: purchaseRate ?? this.purchaseRate,
      openingStock: openingStock ?? this.openingStock,
      currentStock: currentStock ?? this.currentStock,
      isStockTracked: isStockTracked ?? this.isStockTracked,
      minStockLevel: minStockLevel ?? this.minStockLevel,
      barcode: barcode ?? this.barcode,
      description: description ?? this.description,
    );
  }
  
  // Add stock movement
  void addStockMovement(StockMovement movement) {
    try {
      // Calculate balance based on movement type
      double newBalance;
      if (movement.type == StockMovementType.openingStock) {
        newBalance = movement.quantity;
      } else if (movement.type == StockMovementType.purchase || 
                  movement.type == StockMovementType.returnIn ||
                  movement.type == StockMovementType.productionIn) {
        newBalance = currentStock + movement.quantity;
      } else if (movement.type == StockMovementType.sale ||
                  movement.type == StockMovementType.returnOut ||
                  movement.type == StockMovementType.productionOut) {
        newBalance = currentStock - movement.quantity;
      } else {
        newBalance = currentStock;
      }
      
      // Create updated movement with balance
      final updatedMovement = StockMovement(
        itemId: movement.itemId,
        quantity: movement.quantity,
        dateTime: movement.dateTime,
        referenceId: movement.referenceId,
        type: movement.type,
        balance: newBalance,
      );
      
      // Update stock movements and current stock
      stockMovements.add(updatedMovement);
      currentStock = newBalance;
      lastUpdated = DateTime.now();
    } catch (e) {
      print('Error updating stock: $e');
      throw Exception('Error updating stock: $e');
    }
  }
  
  // Update stock quantity
  void updateStock(double quantity, String reference, StockMovementType type) {
    try {
      if (!isStockTracked) return;
      
      // Calculate new balance
      double newBalance;
      if (type == StockMovementType.openingStock) {
        newBalance = quantity;
      } else if (type == StockMovementType.purchase || 
                  type == StockMovementType.returnIn ||
                  type == StockMovementType.productionIn) {
        newBalance = currentStock + quantity;
      } else if (type == StockMovementType.sale ||
                  type == StockMovementType.returnOut ||
                  type == StockMovementType.productionOut) {
        newBalance = currentStock - quantity;
      } else {
        newBalance = currentStock;
      }
      
      final movement = StockMovement(
        itemId: id,
        quantity: quantity,
        dateTime: DateTime.now(),
        referenceId: reference,
        type: type,
        balance: newBalance,
      );
      
      addStockMovement(movement);
    } catch (e) {
      print('Error updating stock: $e');
      throw Exception('Error updating stock: $e');
    }
  }
  
  // Check if stock is low
  bool get isLowStock => isStockTracked && currentStock <= minStockLevel;
  
  // Calculate total value
  double get stockValue => (purchaseRate ?? 0) * currentStock;
  
  // Validate item data
  List<String> validate() {
    final errors = <String>[];
    
    if (name.isEmpty) {
      errors.add('Item name is required');
    }
    
    if (unit.isEmpty) {
      errors.add('Unit is required');
    }
    
    if (isStockTracked) {
      if (currentStock < 0) {
        errors.add('Stock cannot be negative');
      }
      if (minStockLevel < 0) {
        errors.add('Minimum stock level cannot be negative');
      }
    }
    
    if (taxRate < 0 || taxRate > 100) {
      errors.add('Tax rate must be between 0 and 100');
    }
    
    if (saleRate != null && saleRate! < 0) {
      errors.add('Sale rate cannot be negative');
    }
    
    if (purchaseRate != null && purchaseRate! < 0) {
      errors.add('Purchase rate cannot be negative');
    }
    
    return errors;
  }
  
  // Check if item has sufficient stock
  bool hasSufficientStock(double quantity) {
    return !isStockTracked || (currentStock - quantity) >= 0;
  }
  
  // Check if stock is critically low
  bool get isCriticallyLowStock {
    return isStockTracked && currentStock <= minStockLevel * 1.2; // 20% above min level
  }

  // Convert to JSON for serialization
  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'itemGroup': itemGroup,
        'itemCode': itemCode,
        'unit': unit,
        'taxRate': taxRate,
        'hsnCode': hsnCode,
        'saleRate': saleRate,
        'purchaseRate': purchaseRate,
        'openingStock': openingStock,
        'currentStock': currentStock,
        'isStockTracked': isStockTracked,
        'minStockLevel': minStockLevel,
        'barcode': barcode,
        'description': description,
        'lastUpdated': lastUpdated?.toIso8601String(),
      };

  // Create Item from JSON
  factory Item.fromJson(Map<String, dynamic> json) {
    return Item(
      id: json['id'] as String?,
      name: json['name'] as String? ?? 'New Item',
      itemGroup: json['itemGroup'] as String?,
      itemCode: json['itemCode'] as String?,
      unit: json['unit'] as String? ?? 'PCS',
      taxRate: (json['taxRate'] as double?) ?? 0.0,
      hsnCode: json['hsnCode'] as String?,
      saleRate: (json['saleRate'] as double?),
      purchaseRate: (json['purchaseRate'] as double?),
      openingStock: (json['openingStock'] as double?) ?? 0.0,
      currentStock: (json['currentStock'] as double?) ?? 0.0,
      isStockTracked: json['isStockTracked'] as bool? ?? false,
      minStockLevel: (json['minStockLevel'] as double?) ?? 0.0,
      barcode: json['barcode'] as String?,
      description: json['description'] as String?,
    );
  }
}
