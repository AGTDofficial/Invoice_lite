import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:invoice_lite/core/database/database.dart';
import 'package:invoice_lite/features/items/data/item_dao.dart';

import '../../../core/providers/database_provider.dart';

/// Provider for the ItemDao
final itemDaoProvider = Provider<ItemDao>((ref) {
  final db = ref.watch(databaseProvider);
  return ItemDao(db);
});

/// Provider to fetch all items
final itemsProvider = FutureProvider<List<Item>>((ref) async {
  final itemDao = ref.watch(itemDaoProvider);
  return await itemDao.getAllItems();
});

/// Provider to watch all items
final watchItemsProvider = StreamProvider<List<Item>>((ref) {
  final itemDao = ref.watch(itemDaoProvider);
  return itemDao.watchAllItems();
});

/// Provider to search items
final searchItemsProvider = FutureProvider.family<List<Item>, String>((ref, query) async {
  if (query.isEmpty) return [];
  final itemDao = ref.watch(itemDaoProvider);
  return await itemDao.searchItems(query);
});

/// Provider to get a single item by ID
final itemProvider = FutureProvider.family<Item?, int>((ref, id) async {
  final itemDao = ref.watch(itemDaoProvider);
  return await itemDao.getItem(id);
});
