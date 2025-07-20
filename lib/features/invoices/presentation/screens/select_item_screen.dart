import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:invoice_lite/core/widgets/searchable_dropdown.dart';
import 'package:invoice_lite/features/items/data/item_dao.dart';
import 'package:invoice_lite/features/items/data/item_model.dart';
import 'package:invoice_lite/core/widgets/quantity_selector.dart';

class SelectItemScreen extends ConsumerStatefulWidget {
  static const String routeName = '/invoices/select-items';
  
  final List<Item> selectedItems;
  
  const SelectItemScreen({
    super.key,
    this.selectedItems = const [],
  });

  @override
  ConsumerState<SelectItemScreen> createState() => _SelectItemScreenState();
}

class _SelectItemScreenState extends ConsumerState<SelectItemScreen> {
  final List<Item> _tempSelectedItems = [];
  final _searchController = TextEditingController();
  String _searchQuery = '';
  
  @override
  void initState() {
    super.initState();
    _tempSelectedItems.addAll(widget.selectedItems);
  }
  
  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Select Items'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, _tempSelectedItems),
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
          if (_tempSelectedItems.isNotEmpty) ...[
            SizedBox(
              height: 50,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 8.0),
                children: _tempSelectedItems.map((item) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4.0),
                    child: Chip(
                      label: Text('${item.name} (${item.quantity})'),
                      deleteIcon: const Icon(Icons.close, size: 16),
                      onDeleted: () => _toggleItemSelection(item),
                    ),
                  );
                }).toList(),
              ),
            ),
            const Divider(),
          ],
          
          // Items List
          Expanded(
            child: Consumer(
              builder: (context, ref, child) {
                final itemsAsync = ref.watch(itemDaoProvider).getAllItems();
                
                return itemsAsync.when(
                  data: (items) {
                    // Filter items based on search query
                    final filteredItems = items.where((item) {
                      if (_searchQuery.isEmpty) return true;
                      return item.name.toLowerCase().contains(_searchQuery) ||
                          (item.description?.toLowerCase().contains(_searchQuery) ?? false);
                    }).toList();
                    
                    if (filteredItems.isEmpty) {
                      return Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.search_off, size: 48, color: Colors.grey),
                            const SizedBox(height: 16),
                            Text(
                              'No items found',
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                            if (_searchQuery.isNotEmpty) ...[
                              const SizedBox(height: 8),
                              Text(
                                'No items match "$_searchQuery"',
                                style: Theme.of(context).textTheme.bodyMedium,
                              ),
                            ],
                          ],
                        ),
                      );
                    }
                    
                    return ListView.builder(
                      itemCount: filteredItems.length,
                      itemBuilder: (context, index) {
                        final item = filteredItems[index];
                        final isSelected = _tempSelectedItems.any((i) => i.id == item.id);
                        
                        final selectedItem = _tempSelectedItems.firstWhere(
                          (i) => i.id == item.id,
                          orElse: () => item.copyWith(quantity: 1),
                        );
                        
                        return ListTile(
                          title: Text(item.name),
                          subtitle: Text('\$${item.saleRate.toStringAsFixed(2)}'),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              QuantitySelector(
                                quantity: isSelected ? selectedItem.quantity : 0,
                                onChanged: (newQuantity) {
                                  _updateItemQuantity(item, newQuantity);
                                },
                              ),
                              const SizedBox(width: 8),
                              Checkbox(
                                value: isSelected,
                                onChanged: (_) => _toggleItemSelection(item),
                              ),
                            ],
                          ),
                          onTap: () => _showItemDetails(context, item),
                        );
                      },
                    );
                  },
                  loading: () => const Center(child: CircularProgressIndicator()),
                  error: (error, stack) => Center(child: Text('Error: $error')),
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
                  '${_tempSelectedItems.length} ${_tempSelectedItems.length == 1 ? 'item' : 'items'} selected',
                  style: theme.textTheme.titleMedium,
                ),
                FilledButton(
                  onPressed: _tempSelectedItems.isEmpty ? null : () {
                    Navigator.pop(context, _tempSelectedItems);
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
