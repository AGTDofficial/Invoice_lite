import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';
import '../models/item_model.dart';

// Define a class to hold paginated items result
class PaginatedItems {
  final List<Item> items;
  final bool hasMore;
  
  PaginatedItems({required this.items, required this.hasMore});
}

class ItemService {
  static const String _boxName = 'itemsBox';
  static const int _pageSize = 20;
  static final Map<String, Item> _itemCache = {};
  static DateTime? _lastCacheUpdate;
  
  // Get item by ID with caching
  static Future<Item?> getItem(String id) async {
    // Check in-memory cache first
    if (_itemCache.containsKey(id)) {
      return _itemCache[id];
    }
    
    // Check if cache is stale (older than 5 minutes)
    if (_lastCacheUpdate == null || 
        DateTime.now().difference(_lastCacheUpdate!) > const Duration(minutes: 5)) {
      await _warmUpCache();
      return _itemCache[id];
    }
    
    // Fall back to Hive
    final box = await Hive.openBox<Item>(_boxName);
    final item = box.get(id);
    if (item != null) {
      _itemCache[id] = item;
    }
    return item;
  }
  
  // Get paginated items with search
  static Future<PaginatedItems> getItems({
    int page = 0,
    String searchQuery = '',
  }) async {
    try {
      debugPrint('Opening Hive box: $_boxName');
      final box = await Hive.openBox<Item>(_boxName);
      
      // Get all items from the box
      List<Item> allItems = box.values.toList();
      debugPrint('Total items in box: ${allItems.length}');
      
      if (allItems.isNotEmpty) {
        debugPrint('First item in box - ID: ${allItems.first.id}, Name: ${allItems.first.name}');
      }
      
      // Apply search filter if query is provided
      if (searchQuery.isNotEmpty) {
        debugPrint('Applying search filter for: $searchQuery');
        final query = searchQuery.toLowerCase();
        allItems = allItems.where((item) {
          final matches = item.name.toLowerCase().contains(query) ||
                 (item.hsnCode?.toLowerCase().contains(query) ?? false) ||
                 (item.itemCode?.toLowerCase().contains(query) ?? false);
          if (matches) {
            debugPrint('Item matches search: ${item.name}');
          }
          return matches;
        }).toList();
        debugPrint('Items after search filter: ${allItems.length}');
      }
      
      // Apply pagination
      final startIndex = page * _pageSize;
      debugPrint('Pagination - Start: $startIndex, Page: $page, PageSize: $_pageSize');
      
      if (startIndex >= allItems.length) {
        debugPrint('Start index ($startIndex) >= total items (${allItems.length}), returning empty');
        return PaginatedItems(items: const [], hasMore: false);
      }
      
      final endIndex = (startIndex + _pageSize).clamp(0, allItems.length);
      final paginatedItems = allItems.sublist(startIndex, endIndex);
      
      debugPrint('Returning ${paginatedItems.length} items (${startIndex} to ${endIndex-1})');
      
      // Update cache with paginated items
      for (final item in paginatedItems) {
        _itemCache[item.id] = item;
      }
      
      return PaginatedItems(
        items: paginatedItems,
        hasMore: endIndex < allItems.length,
      );
    } catch (e, stackTrace) {
      debugPrint('Error in ItemService.getItems: $e');
      debugPrint('Stack trace: $stackTrace');
      rethrow;
    }
  }
  
  // Warm up cache with frequently accessed items
  static Future<void> _warmUpCache() async {
    final box = await Hive.openBox<Item>(_boxName);
    _itemCache.clear();
    
    // Cache first page of items
    final firstPage = box.values.take(_pageSize);
    for (var item in firstPage) {
      _itemCache[item.id] = item;
    }
    
    _lastCacheUpdate = DateTime.now();
  }
  
  // Clear cache
  static void clearCache() {
    _itemCache.clear();
    _lastCacheUpdate = null;
  }
  
  // Debug method to list all items in the box
  static Future<void> listAllItems() async {
    try {
      debugPrint('Listing all items in box: $_boxName');
      final box = await Hive.openBox<Item>(_boxName);
      final allItems = box.values.toList();
      
      if (allItems.isEmpty) {
        debugPrint('No items found in the box');
        return;
      }
      
      debugPrint('Found ${allItems.length} items:');
      for (var i = 0; i < allItems.length; i++) {
        final item = allItems[i];
        debugPrint('Item $i:');
        debugPrint('  ID: ${item.id}');
        debugPrint('  Name: ${item.name}');
        debugPrint('  Item Code: ${item.itemCode}');
        debugPrint('  HSN Code: ${item.hsnCode}');
        debugPrint('  Price: ${item.saleRate}');
        debugPrint('  Purchase Rate: ${item.purchaseRate}');
        debugPrint('  Stock: ${item.currentStock}');
        debugPrint('  --------------------');
      }
    } catch (e) {
      debugPrint('Error listing items: $e');
    }
  }
}
