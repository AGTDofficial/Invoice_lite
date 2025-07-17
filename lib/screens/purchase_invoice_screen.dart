import 'dart:async';
import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:uuid/uuid.dart';
import '../models/item_model.dart';
import '../models/invoice_item.dart';
import '../models/invoice.dart';
import '../models/account.dart';
import '../enums/invoice_type.dart';
import '../enums/stock_movement_type.dart';
import '../services/item_service.dart';

class PurchaseInvoiceScreen extends StatefulWidget {
  const PurchaseInvoiceScreen({super.key});

  @override
  PurchaseInvoiceScreenState createState() => PurchaseInvoiceScreenState();
}

class PurchaseInvoiceScreenState extends State<PurchaseInvoiceScreen> {
  final List<Item> _allItems = [];
  final List<InvoiceItem> _selectedItems = [];
  String _purchaseType = 'Cash';
  DateTime _invoiceDate = DateTime.now();
  bool _isLoading = false;
  double _roundOff = 0.0;

  // Search
  bool _isLoadingMore = false;
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  Timer? _searchDebounce;

  // Controllers
  final TextEditingController _notesController = TextEditingController();
  final TextEditingController _invoiceNumberController = TextEditingController();
  final TextEditingController _dateController = TextEditingController();
  final TextEditingController _discountController = TextEditingController();
  final TextEditingController _roundOffController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  
  Account? _selectedAccount;
  final List<Account> _availableSuppliers = [];
  final List<Account> _filteredSuppliers = [];

  // Getters for calculated values
  double get _subTotal => _selectedItems.fold(
    0.0, 
    (sum, item) => sum + (item.quantity * item.price) - (item.discount)
  );
  
  double get _totalAmount => _subTotal + _roundOff;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    _searchController.addListener(_onSearchChanged);
    _loadSuppliers();
    _loadMoreItems();
    _generateInvoiceNumber();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _searchController.dispose();
    _searchDebounce?.cancel();
    _notesController.dispose();
    _invoiceNumberController.dispose();
    _dateController.dispose();
    _discountController.dispose();
    _roundOffController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    if (_searchDebounce?.isActive ?? false) _searchDebounce!.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 500), () {
      if (_searchQuery != _searchController.text) {
        _searchQuery = _searchController.text;
        _allItems.clear();
        _loadMoreItems();
      }
    });
  }

  void _onScroll() {
    if (_scrollController.position.pixels >= 
        _scrollController.position.maxScrollExtent - 200) {
      _loadMoreItems();
    }
  }

  Future<void> _generateInvoiceNumber() async {
    try {
      final invoiceBox = await Hive.openBox<Invoice>('invoices');
      final now = DateTime.now();
      final formattedDate = '${now.year}${now.month.toString().padLeft(2, '0')}';
      
      // Find the highest invoice number with PINV prefix
      final lastInvoice = invoiceBox.values
          .where((inv) => inv.invoiceNumber.startsWith('PINV$formattedDate'))
          .toList()
          .lastOrNull;
      
      int nextNumber = 1;
      if (lastInvoice != null) {
        final lastNumber = int.tryParse(
          lastInvoice.invoiceNumber.replaceAll('PINV$formattedDate-', '')
        ) ?? 0;
        nextNumber = lastNumber + 1;
      }
      
      final newNumber = 'PINV$formattedDate-${nextNumber.toString().padLeft(4, '0')}';
      
      if (mounted) {
        setState(() {
          _invoiceNumberController.text = newNumber;
        });
      }
    } catch (e) {
      print('Error generating invoice number: $e');
    }
  }

  Future<void> _loadSuppliers() async {
    if (!mounted) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final supplierBox = await Hive.openBox<Account>('accounts');
      final suppliers = supplierBox.values
          .where((account) => account.isSupplier)
          .toList();
      
      if (mounted) {
        setState(() {
          _availableSuppliers.addAll(suppliers);
          _filteredSuppliers.addAll(suppliers);
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Error loading suppliers: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _loadMoreItems() async {
    if (_isLoadingMore) return;

    _safeSetState(() {
      _isLoadingMore = true;
    });

    try {
      final itemBox = await Hive.openBox<Item>('items');
      final allItems = itemBox.values.toList();
      
      // Apply search filter if there's a query
      final filteredItems = _searchQuery.isEmpty
          ? allItems
          : allItems.where((item) => 
                item.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
                (item.itemCode?.toLowerCase().contains(_searchQuery.toLowerCase()) ?? false)
             ).toList();

      _safeSetState(() {
        _allItems.clear();
        _allItems.addAll(filteredItems);
        _isLoadingMore = false;
      });
    } catch (e) {
      print('Error loading items: $e');
      _safeSetState(() {
        _isLoadingMore = false;
      });
    }
  }

  Future<void> _addOrEditItem([int? index]) async {
    final InvoiceItem? item = index != null ? _selectedItems[index] : null;
    
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => _AddPurchaseItemDialog(
        item: item,
        items: _allItems.map((item) => InvoiceItem(
          name: item.name,
          quantity: 1,
          unit: item.unit,
          price: item.purchaseRate ?? 0.0,
          discount: 0.0,
        )).toList(),
      ),
    );

    if (result != null) {
      _safeSetState(() {
        final newItem = InvoiceItem(
          name: result['name'],
          quantity: result['quantity'],
          unit: result['unit'],
          price: result['price'],
          discount: result['discount'] ?? 0.0,
        );
        
        if (index != null) {
          _selectedItems[index] = newItem;
        } else {
          _selectedItems.add(newItem);
        }
        _updateTotals();
      });
    }
  }

  // Removed _editItem as it's now handled by _addOrEditItem

  void _removeItem(int index) {
    _safeSetState(() {
      _selectedItems.removeAt(index);
    });
  }

  Future<void> _saveInvoice() async {
    if (_selectedItems.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please add at least one item')),
      );
      return;
    }

    if (_selectedAccount == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a supplier')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final invoiceBox = await Hive.openBox<Invoice>('invoices');
      final now = DateTime.now();

      final invoice = Invoice(
        id: const Uuid().v4(),
        type: InvoiceType.purchase,
        partyName: _selectedAccount!.name,
        accountKey: _selectedAccount!.key as int?,
        date: now,
        invoiceNumber: _invoiceNumberController.text,
        items: _selectedItems,
        total: _totalAmount,
        notes: _notesController.text,
        discount: 0.0, // Add discount if needed
        roundOff: 0.0, // Add round off if needed
        saleType: 'Purchase',
      );

      // Save invoice
      await invoiceBox.add(invoice);

      // Update stock for each item
      for (final item in _selectedItems) {
        try {
          // Find the item in _allItems to get its ID
          final itemData = _allItems.firstWhere(
            (i) => i.name == item.name,
          );
          
          // Update stock without awaiting to avoid void expression error
          ItemService.updateStock(
            itemId: itemData.id,
            quantity: item.quantity,
            movementType: StockMovementType.purchase,
            date: now,
            referenceId: invoice.id,
            narration: 'Purchase Invoice: ${invoice.invoiceNumber}',
          );
        } catch (e) {
          debugPrint('Error updating stock for item ${item.name}: $e');
          // Skip this item if not found in inventory
          continue;
        }
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Purchase invoice saved successfully')),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      print('Error saving invoice: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to save purchase invoice')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _updateRoundOff(String value) {
    final roundOff = double.tryParse(value) ?? 0.0;
    _safeSetState(() {
      _roundOff = roundOff;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Purchase Invoice'),
        actions: [
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: _isLoading ? null : _saveInvoice,
            tooltip: 'Save',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Invoice header
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _invoiceNumberController,
                            decoration: const InputDecoration(
                              labelText: 'Invoice Number',
                              border: OutlineInputBorder(),
                            ),
                            readOnly: true,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: TextFormField(
                            controller: _dateController,
                            decoration: const InputDecoration(
                              labelText: 'Date',
                              border: OutlineInputBorder(),
                              suffixIcon: Icon(Icons.calendar_today),
                            ),
                            readOnly: true,
                            onTap: () async {
                              final date = await showDatePicker(
                                context: context,
                                initialDate: _invoiceDate,
                                firstDate: DateTime(2000),
                                lastDate: DateTime(2100),
                              );
                              if (date != null) {
                                setState(() {
                                  _invoiceDate = date;
                                  _dateController.text =
                                      '${date.day}/${date.month}/${date.year}';
                                });
                              }
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Supplier selection
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        TextFormField(
                          controller: _searchController,
                          decoration: InputDecoration(
                            labelText: 'Search Supplier',
                            hintText: 'Search by name or phone',
                            prefixIcon: const Icon(Icons.search),
                            border: const OutlineInputBorder(),
                            suffixIcon: _searchController.text.isNotEmpty
                                ? IconButton(
                                    icon: const Icon(Icons.clear),
                                    onPressed: () {
                                      _searchController.clear();
                                      setState(() {
                                        _filteredSuppliers.clear();
                                        _filteredSuppliers
                                            .addAll(_availableSuppliers);
                                      });
                                    },
                                  )
                                : null,
                          ),
                          onChanged: (value) {
                            setState(() {
                              _filteredSuppliers.clear();
                              if (value.isEmpty) {
                                _filteredSuppliers.addAll(_availableSuppliers);
                              } else {
                                _filteredSuppliers.addAll(
                                  _availableSuppliers.where((supplier) =>
                                      supplier.name
                                          .toLowerCase()
                                          .contains(value.toLowerCase()) ||
                                      (supplier.phone.toLowerCase())
                                          .contains(value.toLowerCase())),
                                );
                              }
                            });
                          },
                        ),
                        if (_selectedAccount != null) ...[
                          const SizedBox(height: 12),
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.grey.shade300),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _selectedAccount!.name,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                                if (_selectedAccount!.phone.isNotEmpty) ...[
                                  const SizedBox(height: 4),
                                  Text('Phone: ${_selectedAccount!.phone}'),
                                ],
                                if (_selectedAccount!.email != null) ...[
                                  const SizedBox(height: 4),
                                  Text('Email: ${_selectedAccount!.email}'),
                                ],
                                if (_selectedAccount!.address != null) ...[
                                  const SizedBox(height: 4),
                                  Text('Address: ${_selectedAccount!.address}'),
                                ],
                              ],
                            ),
                          ),
                        ],
                        const SizedBox(height: 8),
                        if (_filteredSuppliers.isNotEmpty &&
                            _selectedAccount == null)
                          Container(
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.grey.shade300),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: ListView.builder(
                              shrinkWrap: true,
                              itemCount: _filteredSuppliers.length,
                              itemBuilder: (context, index) {
                                final supplier = _filteredSuppliers[index];
                                return ListTile(
                                  title: Text(supplier.name),
subtitle: Text(supplier.phone),
                                  onTap: () {
                                    setState(() {
                                      _selectedAccount = supplier;
                                      _searchController.clear();
                                    });
                                  },
                                );
                              },
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Purchase type
                    DropdownButtonFormField<String>(
                      value: _purchaseType,
                      decoration: const InputDecoration(
                        labelText: 'Payment Method',
                        border: OutlineInputBorder(),
                      ),
                      items: ['Cash', 'Credit', 'Bank Transfer', 'UPI', 'Other']
                          .map((type) => DropdownMenuItem(
                                value: type,
                                child: Text(type),
                              ))
                          .toList(),
                      onChanged: (value) {
                        if (value != null) {
                          setState(() {
                            _purchaseType = value;
                          });
                        }
                      },
                    ),
                    const SizedBox(height: 16),

                    // Items list
                    const Text(
                      'Items',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    ..._selectedItems.asMap().entries.map((entry) {
                      final index = entry.key;
                      final item = entry.value;
                      return Card(
                        margin: const EdgeInsets.only(bottom: 8),
                        child: ListTile(
                          title: Text(item.name),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Qty: ${item.quantity} ${item.unit}'),
                              Text('Rate: ₹${item.price.toStringAsFixed(2)}'),
                              if (item.discount > 0)
                                Text(
                                    'Discount: ₹${item.discount.toStringAsFixed(2)}'),
                              Text(
                                'Total: ₹${(item.quantity * item.price - item.discount).toStringAsFixed(2)}',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.edit, size: 20),
                                onPressed: () => _addOrEditItem(index),
                                tooltip: 'Edit',
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete, size: 20, color: Colors.red),
                                onPressed: () => _removeItem(index),
                                tooltip: 'Remove',
                              ),
                            ],
                          ),
                        ),
                      );
                    }),
                    const SizedBox(height: 8),
                    ElevatedButton.icon(
                      onPressed: _addOrEditItem,
                      icon: const Icon(Icons.add),
                      label: const Text('Add Item'),
                    ),
                    const SizedBox(height: 16),

                    // Summary
                    const Text(
                      'Summary',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          children: [
                            _buildSummaryRow('Subtotal', _subTotal),
                            const Divider(),
                            TextFormField(
                              controller: _roundOffController,
                              decoration: const InputDecoration(
                                labelText: 'Round Off',
                                border: OutlineInputBorder(),
                                prefixText: '₹ ',
                              ),
                              keyboardType: const TextInputType.numberWithOptions(
                                decimal: true,
                                signed: true,
                              ),
                              onChanged: _updateRoundOff,
                            ),
                            const Divider(),
                            _buildSummaryRow(
                              'Total',
                              _totalAmount,
                              isTotal: true,
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Notes
                    TextFormField(
                      controller: _notesController,
                      decoration: const InputDecoration(
                        labelText: 'Notes',
                        border: OutlineInputBorder(),
                        hintText: 'Any additional notes...',
                      ),
                      maxLines: 3,
                    ),
                    const SizedBox(height: 24),

                    // Save button
                    ElevatedButton(
                      onPressed: _isLoading ? null : _saveInvoice,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        textStyle: const TextStyle(fontSize: 16),
                      ),
                      child: _isLoading
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                            )
                          : const Text('Save Purchase Invoice'),
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildSummaryRow(String label, double amount, {bool isTotal = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 16,
              fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
            ),
          ),
          Text(
            '₹${amount.toStringAsFixed(2)}',
            style: TextStyle(
              fontSize: 16,
              fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
              color: isTotal ? Theme.of(context).primaryColor : null,
            ),
          ),
        ],
      ),
    );
  }

  void _safeSetState(VoidCallback callback) {
    if (mounted) {
      setState(callback);
    }
  }

  // Update subtotal and total amounts
  void _updateTotals() {
    // No need to update _subTotal and _totalAmount here as they are getters
    // Just trigger a rebuild to reflect the updated values
    if (mounted) {
      setState(() {
        // Just trigger a rebuild, the getters will calculate the values
      });
    }
  }
}

// Dialog for adding/editing items in the purchase invoice
class _AddPurchaseItemDialog extends StatefulWidget {
  final List<InvoiceItem> items;
  final InvoiceItem? item;

  const _AddPurchaseItemDialog({
    required this.items,
    this.item,
  });

  @override
  _AddPurchaseItemDialogState createState() => _AddPurchaseItemDialogState();
}

class _AddPurchaseItemDialogState extends State<_AddPurchaseItemDialog> {
  final _formKey = GlobalKey<FormState>();
  final _searchController = TextEditingController();
  final _quantityController = TextEditingController();
  final _priceController = TextEditingController();
  final _discountController = TextEditingController();
  
  late List<InvoiceItem> _filteredItems;
  InvoiceItem? _selectedItem;
  String _selectedUnit = 'pcs';
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _filteredItems = List.from(widget.items);
    
    if (widget.item != null) {
      _selectedItem = widget.item;
      _quantityController.text = widget.item!.quantity.toString();
      _priceController.text = widget.item!.price.toString();
      _discountController.text = widget.item!.discount.toString();
      _selectedUnit = widget.item!.unit;
      _searchController.text = widget.item!.name;
    } else {
      _quantityController.text = '1';
      _discountController.text = '0.00';
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    _quantityController.dispose();
    _priceController.dispose();
    _discountController.dispose();
    super.dispose();
  }

  void _filterItems(String query) {
    setState(() {
      _filteredItems = widget.items.where((item) {
        return item.name.toLowerCase().contains(query.toLowerCase()) ||
            (item.name.toLowerCase().contains(query.toLowerCase()));
      }).toList();
    });
  }

  void _updateTotal() {
    if (_selectedItem != null &&
        _quantityController.text.isNotEmpty &&
        _priceController.text.isNotEmpty) {
      final quantity = double.tryParse(_quantityController.text) ?? 0;
      final price = double.tryParse(_priceController.text) ?? 0;
      final discount = double.tryParse(_discountController.text) ?? 0;
      
      setState(() {
        _selectedItem = _selectedItem!.copyWith(
          quantity: quantity,
          price: price,
          discount: discount,
          unit: _selectedUnit,
        );
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.item == null ? 'Add Item' : 'Edit Item'),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Item search and selection
              TextFormField(
                controller: _searchController,
                decoration: InputDecoration(
                  labelText: 'Search Items',
                  hintText: 'Search by name',
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon: _searchController.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear),
                          onPressed: () {
                            _searchController.clear();
                            _filterItems('');
                          },
                        )
                      : null,
                ),
                onChanged: _filterItems,
                readOnly: _selectedItem != null,
              ),
              
              if (_filteredItems.isNotEmpty && _selectedItem == null) ...[
                const SizedBox(height: 8),
                SizedBox(
                  height: 200,
                  child: ListView.builder(
                    itemCount: _filteredItems.length,
                    itemBuilder: (context, index) {
                      final item = _filteredItems[index];
                      return ListTile(
                        title: Text(item.name),
                        subtitle: Text('Unit: ${item.unit}'),
                        trailing: Text('₹${item.price.toStringAsFixed(2)}'),
                        onTap: () {
                          setState(() {
                            _selectedItem = item;
                            _quantityController.text = '1';
                            _priceController.text = item.price.toStringAsFixed(2);
                            _discountController.text = '0.00';
                            _selectedUnit = item.unit;
                            _searchController.text = item.name;
                          });
                          _updateTotal();
                        },
                      );
                    },
                  ),
                ),
              ],
              
              if (_selectedItem != null) ...[
                const SizedBox(height: 16),
                Text(
                  _selectedItem!.name,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Unit: ${_selectedItem!.unit}',
                  style: TextStyle(color: Colors.grey[600]),
                ),
                const SizedBox(height: 16),
                
                // Quantity and Unit
                Row(
                  children: [
                    Expanded(
                      flex: 3,
                      child: TextFormField(
                        controller: _quantityController,
                        decoration: const InputDecoration(
                          labelText: 'Quantity',
                          border: OutlineInputBorder(),
                        ),
                        keyboardType: TextInputType.number,
                        onChanged: (_) => _updateTotal(),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter quantity';
                          }
                          final qty = double.tryParse(value);
                          if (qty == null || qty <= 0) {
                            return 'Quantity must be greater than 0';
                          }
                          return null;
                        },
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      flex: 2,
                      child: DropdownButtonFormField<String>(
                        value: _selectedUnit,
                        decoration: const InputDecoration(
                          labelText: 'Unit',
                          border: OutlineInputBorder(),
                        ),
                        items: const [
                          DropdownMenuItem(value: 'pcs', child: Text('pcs')),
                          DropdownMenuItem(value: 'kg', child: Text('kg')),
                          DropdownMenuItem(value: 'g', child: Text('g')),
                          DropdownMenuItem(value: 'l', child: Text('l')),
                          DropdownMenuItem(value: 'm', child: Text('m')),
                          DropdownMenuItem(value: 'box', child: Text('box')),
                          DropdownMenuItem(value: 'pack', child: Text('pack')),
                        ],
                        onChanged: (value) {
                          if (value != null) {
                            setState(() {
                              _selectedUnit = value;
                              _updateTotal();
                            });
                          }
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                
                // Price and Discount
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _priceController,
                        decoration: const InputDecoration(
                          labelText: 'Price',
                          border: OutlineInputBorder(),
                          prefixText: '₹ ',
                        ),
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        onChanged: (_) => _updateTotal(),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter price';
                          }
                          final price = double.tryParse(value);
                          if (price == null || price < 0) {
                            return 'Price must be 0 or more';
                          }
                          return null;
                        },
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextFormField(
                        controller: _discountController,
                        decoration: const InputDecoration(
                          labelText: 'Discount',
                          border: OutlineInputBorder(),
                          prefixText: '₹ ',
                        ),
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        onChanged: (_) => _updateTotal(),
                        validator: (value) {
                          if (value != null && value.isNotEmpty) {
                            final discount = double.tryParse(value);
                            if (discount == null || discount < 0) {
                              return 'Invalid discount';
                            }
                          }
                          return null;
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                
                // Total
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Total:',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      Text(
                        '₹${_selectedItem != null ? (_selectedItem!.quantity * _selectedItem!.price - _selectedItem!.discount).toStringAsFixed(2) : '0.00'}',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: Colors.green,
                        ),
                      ),
                    ],
                  ),
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
          onPressed: _isLoading
              ? null
              : () {
                  if (_formKey.currentState?.validate() == true && _selectedItem != null) {
                    setState(() => _isLoading = true);
                    // Return the item data as a map
                    Navigator.of(context).pop({
                      'name': _selectedItem!.name,
                      'quantity': double.tryParse(_quantityController.text) ?? 1,
                      'unit': _selectedUnit,
                      'price': double.tryParse(_priceController.text) ?? 0.0,
                      'discount': double.tryParse(_discountController.text) ?? 0.0,
                    });
                  } else if (_selectedItem == null) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Please select an item')),
                    );
                  }
                },
          child: _isLoading
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                )
              : const Text('SAVE'),
        ),
      ],
    );
  }
}
