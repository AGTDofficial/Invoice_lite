import 'package:drift/drift.dart';
import 'package:invoice_lite/features/items/data/item_model.dart';

part 'item_dao.g.dart';

/// Data Access Object for the Items table
@DriftAccessor(tables: [Items])
class ItemDao extends DatabaseAccessor<AppDatabase> with _$ItemDaoMixin {
  final AppDatabase db;

  ItemDao(this.db) : super(db);

  /// Get all items
  Future<List<Item>> getAllItems() => select(items).get();

  /// Watch all items for changes
  Stream<List<Item>> watchAllItems() => select(items).watch();

  /// Get a single item by ID
  Future<Item?> getItem(int id) => (select(items)..where((tbl) => tbl.id.equals(id))).getSingleOrNull();

  /// Add a new item
  Future<int> addItem(ItemsCompanion entry) => into(items).insert(entry);

  /// Update an existing item
  Future<bool> updateItem(ItemsCompanion entry) => update(items).replace(entry);

  /// Delete an item
  Future<int> deleteItem(int id) => (delete(items)..where((tbl) => tbl.id.equals(id))).go();

  /// Search items by name or code
  Future<List<Item>> searchItems(String query) {
    return (select(items)
      ..where((tbl) =>
          tbl.name.like('%$query%') | tbl.itemCode.like('%$query%'))
      ..orderBy([(t) => OrderingTerm(expression: tbl.name)]))
        .get();
  }
}
