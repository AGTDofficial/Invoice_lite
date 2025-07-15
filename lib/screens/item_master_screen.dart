import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import '../models/item_model.dart';
import '../models/item_group.dart';
import 'item_form_screen.dart';
import 'item_group_screen.dart';

class ItemMasterScreen extends StatefulWidget {
  final Box<Item> itemsBox;
  final Box<ItemGroup> itemGroupsBox;
  
  const ItemMasterScreen({
    Key? key,
    required this.itemsBox,
    required this.itemGroupsBox,
  }) : super(key: key);

  @override
  _ItemMasterScreenState createState() => _ItemMasterScreenState();
}

class _ItemMasterScreenState extends State<ItemMasterScreen> {
  late Box<Item> itemsBox;
  late Box<ItemGroup> itemGroupsBox;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  bool _sortAscending = true;
  String? _selectedGroup;
  bool _showLowStockOnly = false;

  @override
  void initState() {
    super.initState();
    itemsBox = widget.itemsBox;
    itemGroupsBox = widget.itemGroupsBox;
    _searchController.addListener(_onSearchChanged);
  }

  void _onSearchChanged() {
    setState(() {
      _searchQuery = _searchController.text.toLowerCase().trim();
    });
  }

  List<Item> get _filteredItems {
    return itemsBox.values.where((item) {
      final matchesSearch = item.name.toLowerCase().contains(_searchQuery) ||
          (item.itemCode?.toLowerCase().contains(_searchQuery) ?? false) ||
          (item.hsnCode?.toLowerCase().contains(_searchQuery) ?? false);
      
      final matchesGroup = _selectedGroup == null || item.itemGroup == _selectedGroup;
      final matchesLowStockFilter = !_showLowStockOnly || item.isLowStock;
      
      return matchesSearch && matchesGroup && matchesLowStockFilter;
    }).toList()
      ..sort((a, b) => _sortAscending
          ? a.name.compareTo(b.name)
          : b.name.compareTo(a.name));
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _addOrEditItem([Item? item, int? index]) async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (ctx) => ItemFormScreen(
          item: item,
          itemsBox: itemsBox,
          onSave: (updatedItem, {bool isDelete = false}) {
            if (isDelete) {
              // Handle delete operation
              itemsBox.deleteAt(index!);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Item deleted successfully')),
              );
            } else if (item == null) {
              // Add new item
              itemsBox.add(updatedItem);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Item added successfully')),
              );
            } else {
              // Update existing item
              itemsBox.putAt(index!, updatedItem);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Item updated successfully')),
              );
            }
          },
        ),
      ),
    );
  }

  Future<void> _deleteItem(int index) async {
    final item = itemsBox.getAt(index);
    if (item == null) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Item'),
        content: Text('Are you sure you want to delete ${item.name}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('CANCEL'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('DELETE', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    ) ?? false;

    if (confirmed && mounted) {
      await itemsBox.deleteAt(index);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Item deleted')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Items'),
        actions: [
          IconButton(
            icon: Icon(_sortAscending ? Icons.arrow_upward : Icons.arrow_downward),
            tooltip: 'Sort ${_sortAscending ? 'A-Z' : 'Z-A' }',
            onPressed: () {
              setState(() {
                _sortAscending = !_sortAscending;
              });
            },
          ),
          IconButton(
            icon: const Icon(Icons.group_work),
            tooltip: 'Item Groups',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const ItemGroupScreen(),
                ),
              ).then((_) => setState(() {}));
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Search and Filters
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(
              children: [
                // Search Bar
                TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    labelText: 'Search items...',
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () {
                        _searchController.clear();
                        setState(() {
                          _searchQuery = '';
                        });
                      },
                    ),
                    border: const OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 8),
                // Filters Row
                Row(
                  children: [
                    // Group Filter
                    Expanded(
                      child: ValueListenableBuilder<Box<ItemGroup>>(
                        valueListenable: Hive.box<ItemGroup>('itemGroups').listenable(),
                        builder: (context, box, _) {
                          final groups = box.values.map((g) => g.name).toList();
                          return DropdownButtonFormField<String>(
                            value: _selectedGroup,
                            decoration: InputDecoration(
                              labelText: 'Filter by Group',
                              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 0),
                              border: const OutlineInputBorder(),
                              suffixIcon: _selectedGroup != null
                                  ? IconButton(
                                      icon: const Icon(Icons.clear, size: 18),
                                      onPressed: () {
                                        setState(() {
                                          _selectedGroup = null;
                                        });
                                      },
                                    )
                                  : null,
                            ),
                            items: [
                              const DropdownMenuItem<String>(
                                value: null,
                                child: Text('All Groups'),
                              ),
                              ...groups.map((group) {
                                return DropdownMenuItem<String>(
                                  value: group,
                                  child: Text(group),
                                );
                              }).toList(),
                            ],
                            onChanged: (value) {
                              setState(() {
                                _selectedGroup = value;
                              });
                            },
                            isExpanded: true,
                          );
                        },
                      ),
                    ),
                    const SizedBox(width: 8),
                    // Low Stock Toggle
                    Tooltip(
                      message: 'Show Low Stock Only',
                      child: FilterChip(
                        label: const Text('Low Stock'),
                        selected: _showLowStockOnly,
                        onSelected: (selected) {
                          setState(() {
                            _showLowStockOnly = selected;
                          });
                        },
                        avatar: _showLowStockOnly
                            ? const Icon(Icons.check, size: 16)
                            : const Icon(Icons.warning_amber, size: 16),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          // Items List
          Expanded(
            child: ValueListenableBuilder<Box<Item>>(
              valueListenable: itemsBox.listenable(),
              builder: (context, box, _) {
                final items = _filteredItems;
                
                if (items.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.inventory_2_outlined, size: 64, color: Colors.grey),
                        const SizedBox(height: 16),
                        Text(
                          _searchQuery.isNotEmpty || _selectedGroup != null || _showLowStockOnly
                              ? 'No matching items found'
                              : 'No items yet',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        if (_searchQuery.isEmpty && _selectedGroup == null && !_showLowStockOnly) ...[
                          const SizedBox(height: 8),
                          ElevatedButton.icon(
                            onPressed: () => _addOrEditItem(),
                            icon: const Icon(Icons.add),
                            label: const Text('Add Your First Item'),
                          ),
                        ],
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  itemCount: items.length,
                  itemBuilder: (ctx, index) {
                    final item = items[index];
                    final itemKey = box.keyAt(box.values.toList().indexOf(item));
                    
                    return Slidable(
                      key: ValueKey(itemKey),
                      endActionPane: ActionPane(
                        motion: const ScrollMotion(),
                        children: [
                          // Edit action
                          SlidableAction(
                            onPressed: (_) => _addOrEditItem(item, index),
                            backgroundColor: Colors.blue,
                            foregroundColor: Colors.white,
                            icon: Icons.edit,
                            label: 'Edit',
                          ),
                          // Delete action
                          SlidableAction(
                            onPressed: (_) => _deleteItem(index),
                            backgroundColor: Colors.red,
                            foregroundColor: Colors.white,
                            icon: Icons.delete,
                            label: 'Delete',
                          ),
                        ],
                      ),
                      child: ListTile(
                        title: Text(
                          item.name,
                          style: TextStyle(
                            fontWeight: FontWeight.w500,
                            color: item.isLowStock ? Colors.red : null,
                          ),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (item.itemCode?.isNotEmpty ?? false)
                              Text('Code: ${item.itemCode!}'),
                            if (item.hsnCode?.isNotEmpty ?? false)
                              Text('HSN: ${item.hsnCode!} • ${item.taxRate}%'),
                            if (item.isStockTracked) ...[
                              const SizedBox(height: 2),
                              Row(
                                children: [
                                  Text(
                                    'Stock: ${item.currentStock} ${item.unit}',
                                    style: TextStyle(
                                      color: item.isLowStock ? Colors.red : null,
                                      fontWeight: item.isLowStock ? FontWeight.bold : null,
                                    ),
                                  ),
                                  if (item.minStockLevel > 0) ...[
                                    const SizedBox(width: 8),
                                    Text(
                                      '(Min: ${item.minStockLevel})',
                                      style: const TextStyle(fontSize: 12, color: Colors.grey),
                                    ),
                                  ],
                                ],
                              ),
                            ],
                          ],
                        ),
                        trailing: Container(
                          height: 56,
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              if (item.saleRate != null)
                                Expanded(
                                  child: Text(
                                    '₹${item.saleRate!.toStringAsFixed(2)}',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              if (item.purchaseRate != null)
                                Text(
                                  'Cost: ₹${item.purchaseRate!.toStringAsFixed(2)}',
                                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                                ),
                              if (item.isStockTracked && item.purchaseRate != null)
                                Text(
                                  'Value: ₹${(item.currentStock * item.purchaseRate!).toStringAsFixed(2)}',
                                  style: const TextStyle(fontSize: 12, color: Colors.green),
                                ),
                            ],
                          ),
                        ),
                        onTap: () => _addOrEditItem(item, index),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _addOrEditItem(),
        icon: const Icon(Icons.add),
        label: const Text('Add Item'),
      ),
    );
  }
}
