import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:invoice_lite/core/widgets/quantity_selector.dart';
import 'package:invoice_lite/features/items/data/item_dao.dart';
import 'package:invoice_lite/features/items/data/item_model.dart';
import 'package:invoice_lite/features/items/data/items_provider.dart';

import '../../../../core/database/database.dart';

// A wrapper class to track selected items with quantities
class SelectedItem {
  final Item item;
  int quantity;
  
  SelectedItem({
    required this.item,
    this.quantity = 1,
  });
  
  SelectedItem copyWith({
    Item? item,
    int? quantity,
  }) {
    return SelectedItem(
      item: item ?? this.item,
      quantity: quantity ?? this.quantity,
    );
  }
  
  double get total => item.saleRate * quantity;
  
  Map<String, dynamic> toMap() {
    return {
      'item': item.toJson(),
      'quantity': quantity,
    };
  }
  
  factory SelectedItem.fromMap(Map<String, dynamic> map) {
    return SelectedItem(
      item: Item.fromJson(map['item']),
      quantity: map['quantity'] ?? 1,
    );
  }
  
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is SelectedItem &&
        other.item.id == item.id;
  }
  
  @override
  int get hashCode => item.id.hashCode;
}

class SelectItemScreen extends ConsumerStatefulWidget {
  static const String routeName = '/invoices/select-items';
  
  final List<SelectedItem> selectedItems;
  
  const SelectItemScreen({
    super.key,
    List<SelectedItem>? selectedItems,
  }) : selectedItems = selectedItems ?? [];

  @override
  ConsumerState<SelectItemScreen> createState() => _SelectItemScreenState();
}

class _SelectItemScreenState extends ConsumerState<SelectItemScreen> {
  final List<SelectedItem> _selectedItems = [];
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  
  @override
  void initState() {
    super.initState();
    // Initialize with any pre-selected items
    if (widget.selectedItems != null) {
      _selectedItems.addAll(widget.selectedItems!);
    }
  }
  
  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
  
  // Toggle item selection
  void _toggleItemSelection(Item item) {
    setState(() {
      final index = _selectedItems.indexWhere((i) => i.item.id == item.id);
      if (index >= 0) {
        _selectedItems.removeAt(index);
      } else {
        _selectedItems.add(SelectedItem(item: item, quantity: 1));
      }
    });
  }
  
  // Check if an item is selected
  bool _isItemSelected(Item item) {
    return _selectedItems.any((i) => i.item.id == item.id);
  }
  
  // Get quantity for a selected item
  int _getItemQuantity(Item item) {
    final selectedItem = _selectedItems.firstWhere(
      (i) => i.item.id == item.id,
      orElse: () => SelectedItem(item: item, quantity: 0),
    );
    return selectedItem.quantity;
  }
  
  // Update item quantity
  void _updateItemQuantity(Item item, int quantity) {
    setState(() {
      final index = _selectedItems.indexWhere((si) => si.item.id == item.id);
      if (index >= 0) {
        _selectedItems[index] = _selectedItems[index].copyWith(quantity: quantity);
      }
    });
  }
  
  // Show item details and quantity picker
  Future<void> _showItemDetails(Item item) async {
    final quantity = _selectedItems
        .firstWhere(
          (si) => si.item.id == item.id,
          orElse: () => SelectedItem(item: item, quantity: 1),
        )
        .quantity;
    
    final controller = TextEditingController(text: quantity.toString());
    
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
          left: 16,
          right: 16,
          top: 16,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              item.name,
              style: Theme.of(context).textTheme.titleLarge,
            ),
            if (item.description?.isNotEmpty == true) ...[
              const SizedBox(height: 8),
              Text(item.description!),
            ],
            const SizedBox(height: 16),
            Row(
              children: [
                Text(
                  'Rate: ₹${item.saleRate.toStringAsFixed(2)}',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const Spacer(),
                Text(
                  'In Stock: ${item.currentStock}',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ],
            ),
            const SizedBox(height: 24),
            TextField(
              controller: controller,
              decoration: const InputDecoration(
                labelText: 'Quantity',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
              onChanged: (value) {
                final qty = int.tryParse(value) ?? 0;
                _updateItemQuantity(item, qty);
              },
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Done'),
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
  
  // Check if an item is selected
  bool _isItemSelected(Item item) {
    return _selectedItems.any((si) => si.item.id == item.id);
  }
  
  // Get quantity of a selected item
  int _getItemQuantity(Item item) {
    return _selectedItems
        .firstWhere(
          (si) => si.item.id == item.id,
          orElse: () => SelectedItem(item: item, quantity: 0),
        )
        .quantity;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Select Items'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, _selectedItems),
            child: const Text('Done'),
          ),
        ],
      ),
      body: Column(
        children: [
          // Search Bar
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search items...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8.0),
                ),
                contentPadding: const EdgeInsets.symmetric(vertical: 0),
              ),
              onChanged: (value) {
                setState(() {
                  _searchQuery = value.toLowerCase();
                });
              },
            ),
          ),
          
          // Selected Items Chips
          if (_selectedItems.isNotEmpty) ...[
            SizedBox(
              height: 60,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 8.0),
                children: _selectedItems.map((selectedItem) {
                  final item = selectedItem.item;
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4.0),
                    child: Chip(
                      label: Text('${item.name} (${selectedItem.quantity})'),
                      deleteIcon: const Icon(Icons.close, size: 16),
                      onDeleted: () => _toggleItemSelection(item),
                      avatar: CircleAvatar(
                        backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                        child: Text(
                          '₹${(item.saleRate * selectedItem.quantity).toStringAsFixed(0)}',
                          style: TextStyle(
                            fontSize: 10,
                            color: Theme.of(context).colorScheme.onPrimaryContainer,
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
            const Divider(height: 1),
          ],
          
          // Items List
          Expanded(
            child: Consumer(
              builder: (context, ref, _) {
                final itemsAsync = ref.watch(itemsProvider);
                
                return itemsAsync.when(
                  loading: () => const Center(child: CircularProgressIndicator()),
                  error: (error, stack) => Center(
                    child: Text('Error loading items: $error'),
                  ),
                  data: (items) {
                    // Filter items based on search query
                    final filteredItems = _searchQuery.isEmpty
                        ? items
                        : items.where((item) {
                            final query = _searchQuery.toLowerCase();
                            return item.name.toLowerCase().contains(query) ||
                                (item.description?.toLowerCase().contains(query) ?? false) ||
                                item.barcode?.toLowerCase().contains(query) ?? false;
                          }).toList();
                    
                    if (filteredItems.isEmpty) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.search_off,
                              size: 64,
                              color: Theme.of(context).disabledColor,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'No items found',
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Try a different search term',
                              style: Theme.of(context).textTheme.bodyMedium,
                            ),
                          ],
                        ),
                      );
                    }
                    
                    return ListView.builder(
                      itemCount: filteredItems.length,
                      itemBuilder: (context, index) {
                        final item = filteredItems[index];
                        final isSelected = _isItemSelected(item);
                        final quantity = isSelected ? _getItemQuantity(item) : 1;
                        
                        return Card(
                          margin: const EdgeInsets.symmetric(
                            horizontal: 8.0,
                            vertical: 4.0,
                          ),
                          child: ListTile(
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16.0,
                              vertical: 8.0,
                            ),
                            leading: CircleAvatar(
                              backgroundColor: isSelected 
                                  ? Theme.of(context).colorScheme.primaryContainer
                                  : Theme.of(context).colorScheme.surfaceVariant,
                              child: Text(
                                '₹${item.saleRate.toStringAsFixed(0)}',
                                style: TextStyle(
                                  color: isSelected
                                      ? Theme.of(context).colorScheme.onPrimaryContainer
                                      : Theme.of(context).colorScheme.onSurfaceVariant,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            title: Text(
                              item.name,
                              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            subtitle: item.description?.isNotEmpty == true
                                ? Text(
                                    item.description!,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  )
                                : null,
                            trailing: isSelected
                                ? Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      IconButton(
                                        icon: const Icon(Icons.remove_circle_outline),
                                        onPressed: () {
                                          final newQuantity = quantity - 1;
                                          if (newQuantity <= 0) {
                                            _toggleItemSelection(item);
                                          } else {
                                            _updateItemQuantity(item, newQuantity);
                                          }
                                        },
                                      ),
                                      Text(
                                        '$quantity',
                                        style: Theme.of(context).textTheme.titleMedium,
                                      ),
                                      IconButton(
                                        icon: const Icon(Icons.add_circle_outline),
                                        onPressed: () {
                                          _updateItemQuantity(item, quantity + 1);
                                        },
                                      ),
                                    ],
                                  )
                                : null,
                            onTap: () => _showItemDetails(item),
                            onLongPress: () => _toggleItemSelection(item),
                          ),
                        );
                      },
                    );
                  },
                );
              },
            ),
          ),
          
          // Bottom Bar
          Container(
            padding: const EdgeInsets.all(8.0),
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 4,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${_selectedItems.length} ${_selectedItems.length == 1 ? 'item' : 'items'} selected',
                  style: theme.textTheme.titleMedium,
                ),
                FilledButton(
                  onPressed: _selectedItems.isEmpty ? null : () {
                    Navigator.pop(context, _selectedItems);
                  },
                  child: const Text('Add to Invoice'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
  
  void _toggleItemSelection(Item item) {
    setState(() {
      final existingIndex = _tempSelectedItems.indexWhere((i) => i.id == item.id);
      
      if (existingIndex >= 0) {
        // Item already selected, remove it
        _tempSelectedItems.removeAt(existingIndex);
      } else {
        // Add item with quantity 1 if not already in the list
        _tempSelectedItems.add(item.copyWith(quantity: 1));
      }
    });
  }
  
  void _updateItemQuantity(Item item, int newQuantity) {
    setState(() {
      final existingIndex = _tempSelectedItems.indexWhere((i) => i.id == item.id);
      
      if (existingIndex >= 0) {
        // Update quantity of existing item
        if (newQuantity > 0) {
          _tempSelectedItems[existingIndex] = 
              _tempSelectedItems[existingIndex].copyWith(quantity: newQuantity);
        } else {
          // Remove if quantity is 0 or less
          _tempSelectedItems.removeAt(existingIndex);
        }
      } else if (newQuantity > 0) {
        // Add new item with specified quantity
        _tempSelectedItems.add(item.copyWith(quantity: newQuantity));
      }
    });
  }
  
  void _showItemDetails(BuildContext context, Item item) {
    final isSelected = _tempSelectedItems.any((i) => i.id == item.id);
    final selectedItem = isSelected
        ? _tempSelectedItems.firstWhere((i) => i.id == item.id)
        : item.copyWith(quantity: 1);
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16.0)),
      ),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with close button
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Item Details',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const Divider(),
            
            // Item name and price
            Text(
              item.name,
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Text(
              '\$${item.saleRate.toStringAsFixed(2)}',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: Theme.of(context).colorScheme.primary,
                fontWeight: FontWeight.bold,
              ),
            ),
            
            // Item description
            if (item.description?.isNotEmpty ?? false) ...[
              const SizedBox(height: 16),
              Text(
                item.description!,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ],
            
            // Quantity selector
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Quantity',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                QuantitySelector(
                  quantity: isSelected ? selectedItem.quantity : 0,
                  onChanged: (newQuantity) {
                    _updateItemQuantity(item, newQuantity);
                    if (newQuantity > 0 && !isSelected) {
                      Navigator.pop(context);
                    }
                  },
                ),
              ],
            ),
            
            // Add/Update button
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: () {
                  if (!isSelected) {
                    _toggleItemSelection(item);
                  }
                  Navigator.pop(context);
                },
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8.0),
                  ),
                ),
                child: Text(
                  isSelected ? 'Update Item' : 'Add to Invoice',
                  style: const TextStyle(fontSize: 16),
                ),
              ),
            ),
            
            // Extra bottom padding for devices with notches
            SizedBox(height: MediaQuery.of(context).viewInsets.bottom + 16),
          ],
        ),
      ),
    );
  }
}
