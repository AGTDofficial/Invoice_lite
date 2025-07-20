import 'package:drift/drift.dart';

// This is the table definition for items
@DataClassName('Item')
class Items extends Table {
  // Auto-incrementing integer ID
  IntColumn get id => integer().autoIncrement()();
  
  // Item details
  TextColumn get name => text().withLength(min: 1, max: 100)();
  TextColumn get description => text().nullable()();
  TextColumn get itemCode => text().withLength(min: 1, max: 50)();
  
  // Pricing
  RealColumn get saleRate => real()();
  RealColumn get purchaseRate => real()();
  
  // Stock management
  RealColumn get currentStock => real().withDefault(const Constant(0))();
  RealColumn get minStockLevel => real().withDefault(const Constant(0))();
  
  // Unit of measurement (e.g., PCS, KG, LTR)
  TextColumn get unit => text().withDefault(const Constant('PCS'))();
  
  // Timestamps
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();
  
  // Ensure item codes are unique
  @override
  List<Set<Column<Object>>>? get uniqueKeys => [
    {itemCode},
  ];
}
