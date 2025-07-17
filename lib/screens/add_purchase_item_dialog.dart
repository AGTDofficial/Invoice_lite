import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import '../models/item_model.dart';
import '../models/invoice_item.dart';

class AddPurchaseItemDialog extends StatefulWidget {
  const AddPurchaseItemDialog({super.key});

  @override
  State<AddPurchaseItemDialog> createState() => _AddPurchaseItemDialogState();
}

class _AddPurchaseItemDialogState extends State<AddPurchaseItemDialog> {
  final _formKey = GlobalKey<FormState>();
  final _quantityController = TextEditingController(text: '1');
  final _priceController = TextEditingController();
  final _searchController = TextEditingController();
  
  List<Item> _items = [];
  List<Item> _filteredItems = [];
  Item? _selectedItem;
  bool _isLoading = true;
  
  @override
  void initState() {
    super.initState();
    _loadItems();
  }
  
  @override
  void dispose() {
    _quantityController.dispose();
    _priceController.dispose();
    _searchController.dispose();
    super.dispose();
  }
  
  Future<void> _loadItems() async {
    try {
      final box = await Hive.openBox<Item>('items');
      setState(() {
        _items = box.values.toList();
        _filteredItems = List.from(_items);
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading items: $e')),
        );
      }
    }
  }
  
  void _filterItems(String query) {
    setState(() {
      _filteredItems = _items
          .where((item) =>
              item.name.toLowerCase().contains(query.toLowerCase()) ||
              item.description?.toLowerCase().contains(query.toLowerCase()) == true)
          .toList();
    });
  }
  
  void _selectItem(Item item) {
    setState(() {
      _selectedItem = item;
      _priceController.text = item.purchaseRate?.toString() ?? '';
    });
  }
  
  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Add Item to Invoice'),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Search field
              TextFormField(
                controller: _searchController,
                decoration: const InputDecoration(
                  labelText: 'Search Items',
                  prefixIcon: Icon(Icons.search),
                  border: OutlineInputBorder(),
                ),
                onChanged: _filterItems,
              ),
              const SizedBox(height: 16),
              
              // Items list
              if (_isLoading)
                const Center(child: CircularProgressIndicator())
              else if (_filteredItems.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 16.0),
                  child: Text('No items found'),
                )
              else
                SizedBox(
                  height: 200,
                  child: ListView.builder(
                    itemCount: _filteredItems.length,
                    itemBuilder: (context, index) {
                      final item = _filteredItems[index];
                      return ListTile(
                        title: Text(item.name),
                        subtitle: Text(item.description ?? ''),
                        trailing: Text(item.purchaseRate != null ? '₹${item.purchaseRate!.toStringAsFixed(2)}' : 'N/A'),
                        selected: _selectedItem?.id == item.id,
                        selectedTileColor: Colors.blue[50],
                        onTap: () => _selectItem(item),
                      );
                    },
                  ),
                ),
              
              const SizedBox(height: 16),
              
              // Selected item details
              if (_selectedItem != null) ...[
                const Divider(),
                Text(
                  'Selected Item: ${_selectedItem!.name}',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                
                // Quantity
                TextFormField(
                  controller: _quantityController,
                  decoration: const InputDecoration(
                    labelText: 'Quantity',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.number,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter quantity';
                    }
                    final quantity = double.tryParse(value);
                    if (quantity == null || quantity <= 0) {
                      return 'Please enter a valid quantity';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                
                // Rate
                TextFormField(
                  controller: _priceController,
                  decoration: const InputDecoration(
                    labelText: 'Price',
                    border: OutlineInputBorder(),
                    prefixText: '₹ ',
                  ),
                  keyboardType: TextInputType.number,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter price';
                    }
                    final price = double.tryParse(value);
                    if (price == null || price < 0) {
                      return 'Please enter a valid price';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 8),
                
                // Total
                Text(
                  'Total: ₹${_calculateTotal()}',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.right,
                ),
              ],
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('CANCEL'),
        ),
        ElevatedButton(
          onPressed: _selectedItem == null ? null : _saveItem,
          child: const Text('ADD'),
        ),
      ],
    );
  }
  
  String _calculateTotal() {
    final quantity = double.tryParse(_quantityController.text) ?? 0;
    final price = double.tryParse(_priceController.text) ?? 0;
    return (quantity * price).toStringAsFixed(2);
  }
  
  void _saveItem() {
    if (_formKey.currentState!.validate() && _selectedItem != null) {
      final quantity = double.tryParse(_quantityController.text) ?? 1.0;
      final price = double.tryParse(_priceController.text) ?? 0.0;
      
      final invoiceItem = InvoiceItem(
        name: _selectedItem!.name,
        quantity: quantity,
        unit: _selectedItem!.unit,
        price: price,
        discount: 0.0, // Default discount
        returnReason: null,
        originalInvoiceItemId: null,
        isFreeItem: false,
      );
      
      Navigator.of(context).pop(invoiceItem);
    }
  }
}
