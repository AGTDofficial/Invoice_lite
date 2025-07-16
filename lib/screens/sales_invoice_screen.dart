import 'dart:async';

import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:flutter/rendering.dart';
import 'package:uuid/uuid.dart';
import '../models/item_model.dart';
import '../models/invoice_item.dart';
import '../models/invoice.dart';
import '../models/account.dart';
import '../enums/invoice_type.dart';
import '../services/item_service.dart';
import '../constants/app_constants.dart';
import '../models/stock_movement.dart';
import '../enums/stock_movement_type.dart';
import 'package:provider/provider.dart';
import '../providers/account_provider.dart';

class SalesInvoiceScreen extends StatefulWidget {
  const SalesInvoiceScreen({super.key});

  @override
  SalesInvoiceScreenState createState() => SalesInvoiceScreenState();
}

class _AddItemDialog extends StatefulWidget {
  final List<Item> items;
  final String searchQuery;
  final int currentPage;
  final List<Item> allItems;
  final Function() loadMoreItems;
  final Function(String) onSearchChanged;
  
  const _AddItemDialog({
    required this.items,
    required this.searchQuery,
    required this.currentPage,
    required this.allItems,
    required this.loadMoreItems,
    required this.onSearchChanged,
  });
  
  @override
  _AddItemDialogState createState() => _AddItemDialogState();
}

class _AddItemDialogState extends State<_AddItemDialog> {
  Item? _selectedItem;
  final _quantityController = TextEditingController(text: '1.0');
  final _priceController = TextEditingController();
  final _discountController = TextEditingController(text: '0.00');
  final _taxRateController = TextEditingController();
  final _searchController = TextEditingController();
  List<Item> _filteredItems = [];
  bool _isFreeItem = false;
  bool _isManualPrice = false;
  String _selectedTaxType = 'GST'; // GST, IGST, Exempt, Tax Incl.
  bool _isSearching = false;

  @override
  void initState() {
    super.initState();
    _filteredItems = List.from(widget.items);
    _taxRateController.text = '18.0'; // Default tax rate
  }

  @override
  void dispose() {
    _quantityController.dispose();
    _priceController.dispose();
    _discountController.dispose();
    _taxRateController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _filterItems(String query) {
    setState(() {
      _isSearching = query.isNotEmpty;
      if (query.isEmpty) {
        _filteredItems = List<Item>.from(widget.items);
      } else {
        final queryLower = query.toLowerCase();
        _filteredItems = widget.items.where((item) {
          return item.name.toLowerCase().contains(queryLower) ||
              (item.hsnCode?.toLowerCase().contains(queryLower) ?? false) ||
              (item.itemCode?.toLowerCase().contains(queryLower) ?? false);
        }).toList();
      }
    });
  }
  
  void _updatePrice() {
    if (_selectedItem != null && !_isManualPrice && !_isFreeItem) {
      setState(() {
        _priceController.text = _selectedItem!.saleRate?.toStringAsFixed(2) ?? '0.00';
      });
    } else if (_isFreeItem) {
      setState(() {
        _priceController.text = '0.00';
      });
    }
  }
  
  void _updateTaxRate() {
    if (_selectedItem != null) {
      setState(() {
        _taxRateController.text = _selectedItem!.taxRate.toStringAsFixed(2);
        // Default to GST since Item doesn't have taxType
        _selectedTaxType = 'GST';
      });
    } else {
      setState(() {
        _taxRateController.text = '0.00';
        _selectedTaxType = 'GST';
      });
    }
  }
  
  double _calculateSubtotal() {
    final quantity = double.tryParse(_quantityController.text) ?? 0;
    final price = double.tryParse(_priceController.text) ?? 0;
    final discount = double.tryParse(_discountController.text) ?? 0;
    return (quantity * price) - discount;
  }
  
  double _calculateTax() {
    final subtotal = _calculateSubtotal();
    final taxRate = double.tryParse(_taxRateController.text) ?? 0;
    
    if (_selectedTaxType == 'Exempt') {
      return 0.0;
    } else if (_selectedTaxType == 'Tax Incl.') {
      // For tax-inclusive pricing, we need to back-calculate the tax
      final taxAmount = subtotal - (subtotal / (1 + (taxRate / 100)));
      return taxAmount;
    } else {
      // Regular GST/IGST calculation
      return (subtotal * taxRate) / 100;
    }
  }
  
  double _calculateTotal() {
    if (_selectedTaxType == 'Tax Incl.') {
      // For tax-inclusive pricing, the total is just the subtotal
      return _calculateSubtotal();
    } else {
      // For regular pricing, add tax to subtotal
      return _calculateSubtotal() + _calculateTax();
    }
  }
  
  @override
  Widget build(BuildContext context) {
    // Ensure filtered items are up to date with current search
    if (!_isSearching) {
      _filteredItems = List<Item>.from(widget.items);
    }
    
    return AlertDialog(
      title: const Text('Add Item to Sale'),
      content: SizedBox(
        width: double.maxFinite,
        height: MediaQuery.of(context).size.height * 0.7, // 70% of screen height
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
            TextField(
              controller: _searchController,
              decoration: InputDecoration(
                labelText: 'Search Items',
                hintText: 'Search by name, HSN, or code',
                prefixIcon: const Icon(Icons.search),
                border: const OutlineInputBorder(),
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
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 200,
              child: _filteredItems.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.search_off, size: 48, color: Colors.grey),
                          const SizedBox(height: 8),
                          Text(
                            _isSearching 
                                ? 'No items match your search'
                                : 'No items available',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          if (!_isSearching) ...[
                            const SizedBox(height: 8),
                            const Text('Add items from the Items section first'),
                          ],
                        ],
                      ),
                    )
                  : ListView.builder(
                      itemCount: _filteredItems.length,
                      itemBuilder: (context, index) {
                        final item = _filteredItems[index];
                        return Card(
                          margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 0),
                          elevation: 0,
                          child: ListTile(
                            title: Text(
                              item.name,
                              style: const TextStyle(fontWeight: FontWeight.w500),
                            ),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                if (item.hsnCode?.isNotEmpty ?? false)
                                  Text('HSN: ${item.hsnCode}'),
                                if (item.itemCode?.isNotEmpty ?? false)
                                  Text('Code: ${item.itemCode}'),
                                Text('Stock: ${item.currentStock} ${item.unit}'),
                              ],
                            ),
                            trailing: Text(
                              '₹${item.saleRate?.toStringAsFixed(2) ?? '0.00'}',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            onTap: () {
                              setState(() {
                                _selectedItem = item;
                                _selectedTaxType = 'GST';
                                _updatePrice();
                                _updateTaxRate();
                              });
                            },
                            tileColor: _selectedItem == item
                                ? Theme.of(context).primaryColor.withOpacity(0.1)
                                : null,
                          ),
                        );
                      },
                    ),
            ),
            const SizedBox(height: 16),
            // Quantity Field
            TextField(
              controller: _quantityController,
              decoration: InputDecoration(
                labelText: 'Quantity',
                border: const OutlineInputBorder(),
                suffixText: _selectedItem?.unit ?? 'pcs',
              ),
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              onChanged: (value) {
                final qty = double.tryParse(value) ?? 0;
                if (qty > (_selectedItem?.currentStock ?? 0)) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Only ${_selectedItem?.currentStock ?? 0} ${_selectedItem?.unit ?? ''} available'),
                      backgroundColor: Colors.orange,
                    ),
                  );
                }
              },
            ),
            const SizedBox(height: 12),
            
            // Price Row with Toggle
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _priceController,
                    decoration: InputDecoration(
                      labelText: 'Selling Price (₹)',
                      border: const OutlineInputBorder(),
                      enabled: !_isFreeItem,
                    ),
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    style: _isFreeItem ? const TextStyle(color: Colors.grey) : null,
                  ),
                ),
                const SizedBox(width: 8),
                Tooltip(
                  message: _isManualPrice ? 'Autofill Price' : 'Edit Price Manually',
                  child: IconButton(
                    icon: Icon(_isManualPrice ? Icons.auto_awesome : Icons.edit),
                    onPressed: () {
                      setState(() {
                        _isManualPrice = !_isManualPrice;
                        _updatePrice();
                      });
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            
            // Tax Type Dropdown
            DropdownButtonFormField<String>(
              value: _selectedTaxType,
              decoration: const InputDecoration(
                labelText: 'Tax Type',
                border: OutlineInputBorder(),
              ),
              items: AppConstants.taxTypes.map((type) {
                return DropdownMenuItem(
                  value: type,
                  child: Text(type),
                );
              }).toList(),
              onChanged: (value) {
                if (value != null) {
                  setState(() {
                    _selectedTaxType = value;
                    if (value == 'Exempt') {
                      _taxRateController.text = '0';
                    } else if (value == 'Tax Incl.') {
                      // Keep current tax rate but show it's inclusive
                    }
                    _updateTaxRate();
                  });
                }
              },
            ),
            const SizedBox(height: 12),
            
            // Tax Rate Field (only show if not exempt)
            if (_selectedTaxType != 'Exempt')
              TextField(
                controller: _taxRateController,
                decoration: InputDecoration(
                  labelText: _selectedTaxType == 'Tax Incl.' ? 'Included Tax Rate (%)' : 'Tax Rate (%)',
                  border: const OutlineInputBorder(),
                  suffixText: '%',
                ),
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                onChanged: (value) {
                  final rate = double.tryParse(value) ?? 0;
                  if (rate < 0 || rate > 100) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Tax rate must be between 0 and 100'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                  setState(() {}); // Update the UI
                },
              ),
            const SizedBox(height: 12),
            
            // Discount Field
            TextField(
              controller: _discountController,
              decoration: const InputDecoration(
                labelText: 'Discount (₹)',
                border: OutlineInputBorder(),
                prefixText: '-₹',
              ),
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
            ),
            const SizedBox(height: 8),
            
            // Free Item Toggle
            CheckboxListTile(
              title: const Text('Mark as Free Item'),
              value: _isFreeItem,
              onChanged: (bool? value) {
                setState(() {
                  _isFreeItem = value ?? false;
                  _updatePrice();
                });
              },
              secondary: const Icon(Icons.money_off, color: Colors.green),
              controlAffinity: ListTileControlAffinity.leading,
            ),
            
            // Summary Card
            Card(
              margin: const EdgeInsets.symmetric(vertical: 8),
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Column(
                  children: [
                    _buildSummaryRow('Subtotal', '₹${_calculateSubtotal().toStringAsFixed(2)}'),
                    if (_selectedTaxType != 'Exempt')
                      _buildSummaryRow(
                        '${_selectedTaxType == 'Tax Incl.' ? 'Included ' : ''}Tax (${_taxRateController.text}%)', 
                        '₹${_calculateTax().toStringAsFixed(2)}',
                      ),
                    if (_selectedTaxType == 'Tax Incl.')
                      _buildSummaryRow('Taxable Amount', '₹${(_calculateSubtotal() - _calculateTax()).toStringAsFixed(2)}'),
                    const Divider(),
                    _buildSummaryRow(
                      'Total',
                      '₹${_calculateTotal().toStringAsFixed(2)}',
                      isBold: true,
                    ),
                  ],
                ),
              ),
            )
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _saveItem,
          child: const Text('Add'),
        ),
        Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: _searchController,
              onChanged: (value) {
                widget.onSearchChanged(value);
              },
              decoration: InputDecoration(
                labelText: 'Search items',
                prefixIcon: const Icon(Icons.search),
                border: const OutlineInputBorder(),
                suffixIcon: widget.searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          widget.onSearchChanged('');
                        },
                      )
                    : null,
              ),
            ),
            const SizedBox(height: 8),
            // Removed Add Item button and loading indicator as they're not needed in this dialog
          ],
        ),
      ],
    );
  }
  
  // Helper method to build summary rows
  Widget _buildSummaryRow(String label, String value, {bool isBold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: isBold ? const TextStyle(fontWeight: FontWeight.bold) : null),
          Text(value, style: isBold ? const TextStyle(fontWeight: FontWeight.bold) : null),
        ],
      ),
    );
  }

  void _saveItem() {
    if (_selectedItem == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select an item')),
      );
      return;
    }
    
    // Validate quantity
    final quantity = double.tryParse(_quantityController.text) ?? 0;
    if (quantity <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Quantity must be greater than 0')),
      );
      return;
    }
    
    // Check stock availability
    if (_selectedItem!.isStockTracked && !_selectedItem!.hasSufficientStock(quantity)) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Insufficient Stock'),
          content: Text(
            'Only ${_selectedItem!.currentStock} ${_selectedItem!.unit} of ${_selectedItem!.name} available.\n\n'
            'Do you want to proceed with the available quantity?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                _createAndReturnItem(quantity);
              },
              child: const Text('Proceed'),
            ),
          ],
        ),
      );
      return;
    }
    
    // Show low stock warning
    if (_selectedItem!.isStockTracked && _selectedItem!.isCriticallyLowStock) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Low Stock Warning'),
          content: Text(
            '${_selectedItem!.name} is running low. Current stock: ${_selectedItem!.currentStock} ${_selectedItem!.unit}\n\n'
            'Consider restocking soon.',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                _createAndReturnItem(quantity);
              },
              child: const Text('Continue'),
            ),
          ],
        ),
      );
      return;
    }
    
    // Check stock with warning but allow override
    if (quantity > _selectedItem!.currentStock) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Low Stock Warning'),
          content: Text(
            'Only ${_selectedItem!.currentStock} ${_selectedItem!.unit} of ${_selectedItem!.name} available.\n\n'
            'Do you want to proceed with the current quantity?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                _createAndReturnItem(quantity);
              },
              child: const Text('Proceed'),
            ),
          ],
        ),
      );
      return;
    }
    
    _createAndReturnItem();
  }
  
  void _createAndReturnItem([double? quantityParam]) {
    final quantity = quantityParam ?? (double.tryParse(_quantityController.text) ?? 1.0);
    final price = _isFreeItem ? 0.0 : (double.tryParse(_priceController.text) ?? 0.0);
    final discount = double.tryParse(_discountController.text) ?? 0.0;
    final taxRate = double.tryParse(_taxRateController.text) ?? 0.0;
    
    final item = InvoiceItem(
      name: _selectedItem!.name,
      hsnCode: _selectedItem!.hsnCode,
      quantity: quantity,
      unit: _selectedItem!.unit,
      price: price,
      taxRate: taxRate,
      taxType: _selectedTaxType, // Use the selected tax type
      discount: discount,
      isFreeItem: _isFreeItem,
      isTaxInclusive: _selectedTaxType == 'Tax Incl.', // Set if tax is inclusive
    );
    
    // Calculate CGST/SGST/IGST based on tax type
    if (_selectedTaxType == 'GST') {
      final taxAmount = (price * quantity * (taxRate / 100));
      item.cgst = taxAmount / 2;
      item.sgst = taxAmount / 2;
    } else if (_selectedTaxType == 'IGST') {
      item.igst = (price * quantity * (taxRate / 100));
    }
    
    Navigator.pop(context, item);
  }
}

class SalesInvoiceScreenState extends State<SalesInvoiceScreen> {
  // Item and invoice data
  final List<Item> _allItems = [];
  final List<InvoiceItem> _selectedItems = [];
  
  // UI state
  String _saleType = 'Cash';
  String _taxType = 'GST';
  bool _isLoading = false;
  bool _isDisposed = false;
  
  // Pagination and search
  int _currentPage = 0;
  bool _hasMoreItems = true;
  bool _isLoadingMore = false;
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  Timer? _searchDebounce;
  
  // Invoice details
  String _invoiceNumber = '';
  DateTime _invoiceDate = DateTime.now();
  double _globalDiscount = 0.0;
  double _roundOff = 0.0;
  
  // Controllers
  final TextEditingController _notesController = TextEditingController();
  final TextEditingController _invoiceNumberController = TextEditingController();
  final TextEditingController _dateController = TextEditingController();
  final TextEditingController _discountController = TextEditingController();
  final TextEditingController _roundOffController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  Account? _selectedAccount;

  @override
  void initState() {
    super.initState();
    _generateInvoiceNumber();
    _scrollController.addListener(_onScroll);
    _searchController.addListener(_onSearchChanged);
    _initializeData();
  }
  
  @override
  void dispose() {
    _isDisposed = true;
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
  
  // Search and pagination methods
  void _onSearchChanged() {
    if (_searchDebounce?.isActive ?? false) _searchDebounce!.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 500), () {
      if (_searchQuery != _searchController.text) {
        _searchQuery = _searchController.text;
        _currentPage = 0;
        _hasMoreItems = true;
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

  Future<void> _loadMoreItems() async {
    if (_isLoadingMore || !_hasMoreItems) return;
    
    _safeSetState(() {
      _isLoadingMore = true;
    });

    try {
      final result = await ItemService.getItems(
        page: _currentPage,
        searchQuery: _searchQuery,
      );

      _safeSetState(() {
        _allItems.addAll(result.items);
        _hasMoreItems = result.hasMore;
        _currentPage++;
      });
    } catch (e) {
      debugPrint('Error loading more items: $e');
    } finally {
      _safeSetState(() {
        _isLoadingMore = false;
      });
    }
  }

  Future<void> _generateInvoiceNumber() async {
    try {
      final invoiceBox = await Hive.openBox<Invoice>('invoices');
      final invoiceCount = invoiceBox.length + 1;
      final now = DateTime.now();
      final formattedDate = '${now.year}${now.month.toString().padLeft(2, '0')}';
      setState(() {
        _invoiceNumber = 'INV-$formattedDate-${invoiceCount.toString().padLeft(4, '0')}';
        _invoiceNumberController.text = _invoiceNumber;
      });
    } catch (e) {
      debugPrint('Error generating invoice number: $e');
      // Fallback to timestamp-based number if there's an error
      setState(() {
        _invoiceNumber = 'INV-${DateTime.now().millisecondsSinceEpoch}';
        _invoiceNumberController.text = _invoiceNumber;
      });
    }
  }

  Future<void> _initializeData() async {
    _safeSetState(() {
      _isLoading = true;
    });

    try {
      // Generate invoice number if not already set
      if (_invoiceNumber.isEmpty) {
        await _generateInvoiceNumber();
      }
      
      // Initialize date controller
      _dateController.text = '${_invoiceDate.day}/${_invoiceDate.month}/${_invoiceDate.year}';
      
      // Open Hive boxes
      if (!Hive.isBoxOpen('invoices')) {
        await Hive.openBox<Invoice>('invoices');
      }
      
      if (!Hive.isBoxOpen('items')) {
        await Hive.openBox<Item>('items');
      }
      
      // Load first page of items
      await _loadMoreItems();
      
      if (_allItems.isEmpty) {
        if (!_isDisposed && context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('No items found. Please add items first.')),
          );
        }
      }
    } catch (e) {
      debugPrint('Error initializing sales invoice: $e');
      if (!_isDisposed && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Error initializing sales invoice')),
        );
      }
    } finally {
      _safeSetState(() {
        _isLoading = false;
      });
    }
  }

  void _safeSetState(VoidCallback fn) {
    if (mounted && !_isDisposed) {
      setState(fn);
    }
  }

  Future<void> _addItem() async {
    // Show loading indicator
    _safeSetState(() {
      _isLoading = true;
    });

    try {
      // Reset search and load first page
      _searchController.clear();
      _currentPage = 0;
      _hasMoreItems = true;
      _allItems.clear();
      
      // Ensure we have fresh data
      await _loadMoreItems();
      
      if (_allItems.isEmpty) {
        if (!_isDisposed && mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('No items available. Please add items first.'),
              duration: Duration(seconds: 2),
            ),
          );
        }
        return;
      }
      
      // Create a local copy of items for the dialog
      final dialogItems = List<Item>.from(_allItems);
      
      final item = await showDialog<InvoiceItem>(
        context: context,
        builder: (context) => _AddItemDialog(
          items: dialogItems,
          searchQuery: _searchQuery,
          currentPage: _currentPage,
          allItems: dialogItems,
          loadMoreItems: () async {
            await _loadMoreItems();
            // Update the dialog with new items if any
            if (context.mounted) {
              (context as Element).markNeedsBuild();
            }
          },
          onSearchChanged: (query) {
            // Local search within the dialog
            _searchQuery = query;
            if (context.mounted) {
              (context as Element).markNeedsBuild();
            }
          },
        ),
        barrierDismissible: false,
      );
      
      if (item != null && !_isDisposed && mounted) {
        _safeSetState(() {
          _selectedItems.add(item);
        });
      }
    } catch (e) {
      debugPrint('Error in _addItem: $e');
      if (!_isDisposed && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } finally {
      if (!_isDisposed && mounted) {
        _safeSetState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _saveInvoice() async {
    if (_selectedItems.isEmpty) {
      if (!_isDisposed) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please add at least one item')),
        );
      }
      return;
    }

    _safeSetState(() {
      _isLoading = true;
    });

    try {
      if (!Hive.isBoxOpen('invoices')) {
        await Hive.openBox<Invoice>('invoices');
      }
      final invoiceBox = Hive.box<Invoice>('invoices');
      
      if (!Hive.isBoxOpen('items')) {
        await Hive.openBox<Item>('items');
      }
      var itemBox = Hive.box<Item>('items');
      
      // Create new invoice items with references to original items
      final newInvoiceItems = _selectedItems.map((item) {
        return InvoiceItem(
          name: item.name,
          hsnCode: item.hsnCode,
          quantity: item.quantity,
          unit: item.unit,
          price: item.price,
          taxRate: item.taxRate,
          taxType: item.taxType,
          discount: item.discount,
          cgst: item.cgst,
          sgst: item.sgst,
          igst: item.igst,
          isTaxInclusive: item.isTaxInclusive,
          isFreeItem: item.isFreeItem,
        )..originalItemKey = item.key; // Store reference to original item
      }).toList();

      // Create new invoice
      final invoice = Invoice(
        id: const Uuid().v4(),
        type: InvoiceType.sale,
        partyName: _selectedAccount?.name ?? 'Unknown Customer',
        date: _invoiceDate,
        invoiceNumber: _invoiceNumberController.text,
        taxType: _taxType,
        items: newInvoiceItems,
        total: _totalAmount,
        notes: _notesController.text,
        discount: _totalDiscount,
        roundOff: _roundOff,
        totalTaxAmount: _taxAmount,
        saleType: _saleType,
        accountKey: _selectedAccount?.key,
      );



      // Update stock for sale items with stock movements
      itemBox = await Hive.openBox<Item>('itemsBox');
      for (var item in _selectedItems) {
        if (item.key != null && item.quantity > 0) {
          final originalItem = itemBox.get(item.key!);
          if (originalItem != null && originalItem.isStockTracked) {
            // Update stock using the Item's stock update methods
            originalItem.addStockMovement(StockMovement(
              itemId: originalItem.id,
              quantity: -item.quantity, // Negative for sales
              dateTime: DateTime.now(),
              referenceId: invoice.id,
              type: StockMovementType.sale,
            ));

            await itemBox.put(item.key!, originalItem);
          }
        }
      }

      // Save the invoice
      await invoiceBox.add(invoice);

      if (!_isDisposed) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Invoice saved successfully')),
        );
        Navigator.pop(context, true); // Return success
      }
    } catch (e) {
      if (!_isDisposed) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving invoice: $e')),
        );
      }
    } finally {
      _safeSetState(() {
        _isLoading = false;
      });
    }
  }

  void _removeItem(int index) {
    _safeSetState(() {
      _selectedItems.removeAt(index);
    });
  }

  double get _subTotal {
    return _selectedItems.fold(0, (sum, item) => sum + (item.price * item.quantity));
  }

  double get _totalDiscount {
    return _selectedItems.fold(0.0, (sum, item) => sum + (item.discount));
  }

  double get _taxableAmount {
    return _subTotal - _totalDiscount;
  }

  double get _taxAmount {
    return _selectedItems.fold(0, (sum, item) {
      return sum + ((item.price * item.quantity - item.discount) * (item.taxRate / 100));
    });
  }

  double get _totalAmount {
    return _taxableAmount + _taxAmount - _globalDiscount + _roundOff;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Sales Invoice'),
        actions: [
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: _saveInvoice,
            tooltip: 'Save Invoice',
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              _currentPage = 0;
              _allItems.clear();
              _loadMoreItems();
            },
            tooltip: 'Refresh Items',
          ),
          IconButton(
            icon: const Icon(Icons.list),
            onPressed: () {
              Navigator.pushNamed(context, '/sales-list');
            },
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
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _invoiceNumberController,
                            decoration: const InputDecoration(labelText: 'Invoice No.'),
                            readOnly: true,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: TextFormField(
                            controller: _dateController,
                            decoration: const InputDecoration(labelText: 'Date'),
                            readOnly: true,
                            onTap: () async {
                              final date = await showDatePicker(
                                context: context,
                                initialDate: _invoiceDate,
                                firstDate: DateTime(2000),
                                lastDate: DateTime(2100),
                              );
                              if (date != null) {
                                _safeSetState(() {
                                  _invoiceDate = date;
                                  _dateController.text = '${date.day}/${date.month}/${date.year}';
                                });
                              }
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Consumer<AccountProvider>(
                      builder: (context, accountProvider, _) {
                        final customers = accountProvider.customers;
                        return Autocomplete<Account>(
                          optionsBuilder: (TextEditingValue textEditingValue) {
                            if (textEditingValue.text == '') {
                              return const Iterable<Account>.empty();
                            }
                            return customers.where((account) =>
                              account.name.toLowerCase().contains(textEditingValue.text.toLowerCase()) ||
                              account.phone.toLowerCase().contains(textEditingValue.text.toLowerCase())
                            );
                          },
                          displayStringForOption: (Account option) => '${option.name} (${option.phone})',
                          fieldViewBuilder: (
                            BuildContext context,
                            TextEditingController fieldTextEditingController,
                            FocusNode fieldFocusNode,
                            VoidCallback onFieldSubmitted,
                          ) {
                            return TextFormField(
                              controller: fieldTextEditingController,
                              focusNode: fieldFocusNode,
                              decoration: const InputDecoration(
                                labelText: 'Customer',
                                hintText: 'Search customer by name or phone',
                                border: OutlineInputBorder(),
                                suffixIcon: Icon(Icons.search),
                              ),
                              validator: (value) {
                                if (_selectedAccount == null) {
                                  return 'Please select a customer';
                                }
                                return null;
                              },
                            );
                          },
                          onSelected: (Account selection) {
                            setState(() {
                              _selectedAccount = selection;
                            });
                          },
                          optionsViewBuilder: (
                            BuildContext context,
                            AutocompleteOnSelected<Account> onSelected,
                            Iterable<Account> options,
                          ) {
                            return Align(
                              alignment: Alignment.topLeft,
                              child: Material(
                                elevation: 4.0,
                                child: ConstrainedBox(
                                  constraints: const BoxConstraints(maxHeight: 200),
                                  child: ListView.builder(
                                    padding: EdgeInsets.zero,
                                    itemCount: options.length,
                                    itemBuilder: (BuildContext context, int index) {
                                      final Account option = options.elementAt(index);
                                      return InkWell(
                                        onTap: () {
                                          onSelected(option);
                                        },
                                        child: Padding(
                                          padding: const EdgeInsets.all(16.0),
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                option.name,
                                                style: Theme.of(context).textTheme.titleMedium,
                                              ),
                                              Text(
                                                option.phone,
                                                style: Theme.of(context).textTheme.bodySmall,
                                              ),
                                            ],
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                                ),
                              ),
                            );
                          },
                        );
                      },
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            value: _saleType,
                            decoration: const InputDecoration(
                              labelText: 'Sale Type',
                              border: OutlineInputBorder(),
                            ),
                            items: ['Cash', 'Credit'].map((type) {
                              return DropdownMenuItem(
                                value: type,
                                child: Text(type),
                              );
                            }).toList(),
                            onChanged: (value) {
                              if (value != null) {
                                _safeSetState(() {
                                  _saleType = value;
                                });
                              }
                            },
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            value: _taxType,
                            decoration: const InputDecoration(
                              labelText: 'Tax Type',
                              border: OutlineInputBorder(),
                            ),
                            items: ['GST', 'VAT', 'None'].map((type) {
                              return DropdownMenuItem(
                                value: type,
                                child: Text(type),
                              );
                            }).toList(),
                            onChanged: (value) {
                              if (value != null) {
                                _safeSetState(() {
                                  _taxType = value;
                                });
                              }
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    const Divider(),
                    const Text('Items', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    if (_selectedItems.isEmpty)
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 16.0),
                        child: Center(child: Text('No items added')),
                      )
                    else
                      ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: _selectedItems.length,
                        itemBuilder: (context, index) {
                          final item = _selectedItems[index];
                          return Card(
                            margin: const EdgeInsets.symmetric(vertical: 4.0),
                            child: ListTile(
                              title: Text(item.name),
                              subtitle: Text('${item.quantity} ${item.unit} × ₹${item.price} = ₹${(item.quantity * item.price).toStringAsFixed(2)}'),
                              trailing: IconButton(
                                icon: const Icon(Icons.delete, color: Colors.red),
                                onPressed: () => _removeItem(index),
                              ),
                            ),
                          );
                        },
                      ),
                    const SizedBox(height: 8),
                    ElevatedButton.icon(
                      onPressed: _addItem,
                      icon: const Icon(Icons.add),
                      label: const Text('Add Item'),
                    ),
                    const SizedBox(height: 16),
                    const Divider(),
                    const Text('Summary', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    _buildSummaryRow('Subtotal', _subTotal),
                    _buildSummaryRow('Total Discount', -_totalDiscount),
                    _buildSummaryRow('Taxable Amount', _taxableAmount),
                    _buildSummaryRow('Tax Amount', _taxAmount),
                    _buildSummaryRow('Global Discount', -_globalDiscount),
                    _buildSummaryRow('Round Off', _roundOff),
                    const Divider(),
                    _buildSummaryRow('Total', _totalAmount, isBold: true),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _notesController,
                      decoration: const InputDecoration(
                        labelText: 'Notes',
                        border: OutlineInputBorder(),
                      ),
                      maxLines: 3,
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: _saveInvoice,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: const Text('Save Invoice'),
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildSummaryRow(String label, double amount, {bool isBold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: isBold ? const TextStyle(fontWeight: FontWeight.bold) : null,
          ),
          Text(
            '₹${amount.toStringAsFixed(2)}',
            style: isBold ? const TextStyle(fontWeight: FontWeight.bold) : null,
          ),
        ],
      ),
    );
  }
}
