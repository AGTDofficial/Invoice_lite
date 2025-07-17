import 'dart:async';
import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:uuid/uuid.dart';
import '../models/item_model.dart';
import '../models/invoice_item.dart';
import '../models/invoice.dart';
import '../models/account.dart';
import '../enums/invoice_type.dart';
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
  final InvoiceItem? initialItem;
  final Item? selectedItem;
  
  const _AddItemDialog({
    required this.items,
    required this.searchQuery,
    required this.currentPage,
    required this.allItems,
    required this.loadMoreItems,
    required this.onSearchChanged,
    this.initialItem,
    this.selectedItem,
  });
  
  @override
  _AddItemDialogState createState() => _AddItemDialogState();
}

class _AddItemDialogState extends State<_AddItemDialog> {
  Item? _selectedItem;
  final TextEditingController _quantityController = TextEditingController(text: '1.0');
  final TextEditingController _priceController = TextEditingController();
  final TextEditingController _discountController = TextEditingController(text: '0.00');
  final _itemSearchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  final FocusNode _quantityFocusNode = FocusNode();
  final FocusNode _priceFocusNode = FocusNode();
  final FocusNode _discountFocusNode = FocusNode();

  bool _isManualPrice = false;

  @override
  void initState() {
    super.initState();
    _searchFocusNode.addListener(() {
      if (!_searchFocusNode.hasFocus && _selectedItem == null) {
        _itemSearchController.clear();
        widget.onSearchChanged('');
      }
    });
    
    // If editing an existing item, initialize with its values
    if (widget.initialItem != null) {
      _selectedItem = widget.allItems.firstWhere(
        (item) => item.name == widget.initialItem!.name,
        orElse: () => widget.items.isNotEmpty ? widget.items.first : Item(name: '', unit: 'pcs'),
      );
      _itemSearchController.text = _selectedItem?.name ?? '';
      _quantityController.text = widget.initialItem!.quantity.toString();
      _priceController.text = widget.initialItem!.price.toStringAsFixed(2);
      _discountController.text = widget.initialItem!.discount.toStringAsFixed(2);
      _isManualPrice = true; // Allow editing the price by default when editing
    } 
    // If a selected item is provided, use it
    else if (widget.selectedItem != null) {
      _selectedItem = widget.selectedItem;
      _itemSearchController.text = _selectedItem?.name ?? '';
      _priceController.text = _selectedItem!.saleRate?.toStringAsFixed(2) ?? '0.00';
      _quantityController.text = '1'; // Default quantity for new selection
    }
    // Otherwise use the first item in the list if available
    else if (widget.items.isNotEmpty) {
      _selectedItem = widget.items.first;
      _itemSearchController.text = _selectedItem?.name ?? '';
      _priceController.text = _selectedItem!.saleRate?.toStringAsFixed(2) ?? '0.00';
    }
  }

  @override
  void dispose() {
    _itemSearchController.dispose();
    _quantityController.dispose();
    _priceController.dispose();
    _discountController.dispose();
    _searchFocusNode.dispose();
    _quantityFocusNode.dispose();
    _priceFocusNode.dispose();
    _discountFocusNode.dispose();
    super.dispose();
  }
  
  void _updatePrice() {
    if (_selectedItem != null && !_isManualPrice) {
      setState(() {
        _priceController.text = _selectedItem!.saleRate?.toStringAsFixed(2) ?? '0.00';
      });
    }
  }

  double _calculateSubtotal() {
    final quantity = double.tryParse(_quantityController.text) ?? 0;
    final price = double.tryParse(_priceController.text) ?? 0;
    final discount = double.tryParse(_discountController.text) ?? 0;
    return (quantity * price) - discount;
  }
  
  double _calculateTotal() {
    return _calculateSubtotal();
  }
  
  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Add Item to Sale'),
      content: SizedBox(
        width: double.maxFinite,
        height: MediaQuery.of(context).size.height * 0.7,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildItemSearchField(),
              const SizedBox(height: 16),
              
              // Quantity Field
              TextField(
                controller: _quantityController,
                focusNode: _quantityFocusNode,
                decoration: InputDecoration(
                  labelText: 'Quantity',
                  border: const OutlineInputBorder(),
                  suffixText: _selectedItem?.unit ?? 'pcs',
                ),
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                textInputAction: TextInputAction.next,
                onChanged: (_) => _updatePrice(),
                onSubmitted: (_) => FocusScope.of(context).requestFocus(_priceFocusNode),
              ),
              const SizedBox(height: 12),
              
              // Price Field with Lock Toggle
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _priceController,
                      focusNode: _priceFocusNode,
                      readOnly: !_isManualPrice,
                      decoration: InputDecoration(
                        labelText: 'Price',
                        border: const OutlineInputBorder(),
                        prefixText: '₹ ',
                        suffixIcon: IconButton(
                          icon: Icon(_isManualPrice ? Icons.lock_open : Icons.lock_outline),
                          tooltip: _isManualPrice ? 'Lock price' : 'Unlock to edit',
                          onPressed: () {
                            setState(() {
                              _isManualPrice = !_isManualPrice;
                              if (!_isManualPrice && _selectedItem != null) {
                                // Revert to item's default price when locking
                                _priceController.text = _selectedItem!.saleRate?.toStringAsFixed(2) ?? '0.00';
                              }
                            });
                          },
                        ),
                        filled: !_isManualPrice,
                        fillColor: !_isManualPrice ? Colors.grey[100] : null,
                        hintText: !_isManualPrice ? 'Tap the lock to edit' : null,
                      ),
                      style: !_isManualPrice 
                          ? TextStyle(color: Colors.grey[700], fontWeight: FontWeight.w500)
                          : null,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      textInputAction: TextInputAction.next,
                      onChanged: (_) => _updatePrice(),
                      onSubmitted: (_) => FocusScope.of(context).requestFocus(_discountFocusNode),
                      onTap: () {
                        if (!_isManualPrice) {
                          // Auto-unlock when tapping on the field
                          setState(() {
                            _isManualPrice = true;
                          });
                        }
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              
              // Discount Field
              TextField(
                controller: _discountController,
                focusNode: _discountFocusNode,
                decoration: const InputDecoration(
                  labelText: 'Discount',
                  border: OutlineInputBorder(),
                  prefixText: '₹ ',
                ),
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                textInputAction: TextInputAction.done,
                onChanged: (_) => _updatePrice(),
                onSubmitted: (_) => _submitForm(),
              ),
              const SizedBox(height: 16),
              
              // Summary Card
              Card(
                margin: const EdgeInsets.symmetric(vertical: 8),
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Column(
                    children: [
                      _buildSummaryRow('Subtotal', _calculateSubtotal()),
                      const SizedBox(height: 4),
                      _buildSummaryRow(
                        'Discount',
                        (double.tryParse(_discountController.text) ?? 0) * -1,
                        textColor: Colors.red,
                      ),
                      const Divider(),
                      _buildSummaryRow(
                        'Total',
                        _calculateTotal(),
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
          onPressed: _submitForm,
          child: const Text('Add'),
        ),
      ],
    );
  }
  
  Widget _buildItemSearchField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          controller: _itemSearchController,
          focusNode: _searchFocusNode,
          textInputAction: TextInputAction.next,
          autofocus: true,
          onChanged: (value) {
            widget.onSearchChanged(value);
            setState(() {
              // Clear selection when search text changes
              if (value.isEmpty) {
                _selectedItem = null;
              }
            });
          },
          onTap: () {
            // Show dropdown when field is tapped
            if (_itemSearchController.text.isEmpty) {
              widget.onSearchChanged('');
            }
          },
          decoration: InputDecoration(
            labelText: 'Item',
            hintText: 'Search by name or code',
            border: const OutlineInputBorder(),
            suffixIcon: _itemSearchController.text.isNotEmpty
                ? IconButton(
                    icon: const Icon(Icons.clear, size: 20),
                    onPressed: () {
                      _itemSearchController.clear();
                      setState(() {
                        _selectedItem = null;
                        widget.onSearchChanged('');
                      });
                    },
                  )
                : null,
          ),
        ),
        // Show dropdown only when there's a search query and no item is selected
        if (_itemSearchController.text.isNotEmpty && widget.items.isNotEmpty && _selectedItem == null)
          Card(
            elevation: 4.0,
            margin: const EdgeInsets.only(top: 4.0),
            child: SizedBox(
              height: 200,
              child: _buildItemList(),
            ),
          ),
      ],
    );
  }
  
  Widget _buildItemList() {
    final filteredItems = widget.items.where((item) {
      final searchText = _itemSearchController.text.toLowerCase();
      final itemName = item.name.toLowerCase();
      final itemCode = item.itemCode?.toLowerCase() ?? '';
      return itemName.contains(searchText) || 
             itemCode.contains(searchText);
    }).toList();

    if (filteredItems.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(16.0),
          child: Text('No items found'),
        ),
      );
    }

    return ListView.builder(
      padding: EdgeInsets.zero,
      shrinkWrap: true,
      itemCount: filteredItems.length,
      itemBuilder: (context, index) {
        final item = filteredItems[index];
        return Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () {
              setState(() {
                _selectedItem = item;
                _itemSearchController.text = item.name;
                if (!_isManualPrice) {
                  _priceController.text = item.saleRate?.toStringAsFixed(2) ?? '0.00';
                }
                widget.onSearchChanged('');
              });
              FocusScope.of(context).requestFocus(_quantityFocusNode);
            },
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.name,
                    style: const TextStyle(
                      fontWeight: FontWeight.w500,
                      fontSize: 15,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${item.itemCode ?? 'No Code'} • ${item.unit} • ₹${item.saleRate?.toStringAsFixed(2) ?? '0.00'}',
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey[600],
                    ),
                  ),
                  if (index < filteredItems.length - 1)
                    const Divider(height: 20, thickness: 0.5),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  void _submitForm() {
    if (_selectedItem != null) {
      final quantity = double.tryParse(_quantityController.text) ?? 0;
      final price = double.tryParse(_priceController.text) ?? 0;
      final discount = double.tryParse(_discountController.text) ?? 0;

      final item = InvoiceItem(
        name: _selectedItem!.name,
        quantity: quantity,
        unit: _selectedItem!.unit,
        price: price,
        discount: discount,
      );
      
      // Return both the item and whether it's an edit
      Navigator.pop(context, {
        'item': item,
        'isEdit': widget.initialItem != null,
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select an item'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Widget _buildSummaryRow(String label, double amount, {bool isBold = false, Color? textColor}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
              fontSize: isBold ? 16 : 14,
              color: textColor,
            ),
          ),
          Text(
            '₹${amount.toStringAsFixed(2)}',
            style: TextStyle(
              fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
              fontSize: isBold ? 16 : 14,
              color: textColor,
            ),
          ),
        ],
      ),
    );
  }
}

class SalesInvoiceScreenState extends State<SalesInvoiceScreen> {
  // Item and invoice data
  final List<Item> _allItems = [];
  final List<InvoiceItem> _selectedItems = [];
  
  // UI state
  String _saleType = 'Cash';
  DateTime _dueDate = DateTime.now().add(const Duration(days: 30));
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
  double _roundOff = 0.0;
  double _grandDiscountPercent = 0.0;
  double _grandDiscountAmount = 0.0;
  
  // Controllers
  final TextEditingController _notesController = TextEditingController();
  final TextEditingController _invoiceNumberController = TextEditingController();
  final TextEditingController _dateController = TextEditingController();
  final TextEditingController _discountController = TextEditingController();
  final TextEditingController _roundOffController = TextEditingController();
  final TextEditingController _customerController = TextEditingController();
  final TextEditingController _grandDiscountPercentController = TextEditingController();
  final TextEditingController _grandDiscountAmountController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  Account? _selectedAccount;

  @override
  void initState() {
    super.initState();
    _generateInvoiceNumber();
    _scrollController.addListener(_onScroll);
    _searchController.addListener(_onSearchChanged);
    _initializeData();
    
    // Initialize date controller
    _dateController.text = '${_invoiceDate.day}/${_invoiceDate.month}/${_invoiceDate.year}';
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
    _customerController.dispose();
    _grandDiscountPercentController.dispose();
    _grandDiscountAmountController.dispose();
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
      // Get all items from Hive box
      final items = Hive.box<Item>('itemsBox').values.toList();
      
      // Apply search filter if query exists
      if (_searchQuery.isNotEmpty) {
        final query = _searchQuery.toLowerCase();
        items.retainWhere((item) => 
          item.name.toLowerCase().contains(query)
        );
      }

      _safeSetState(() {
        _allItems.clear();
        _allItems.addAll(items);
        _hasMoreItems = false; // Since we're loading all items at once
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

  Future<void> _addItem({int? editIndex}) async {
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
      
      // If editing, find the original item
      InvoiceItem? itemToEdit;
      Item? selectedItem;
      
      if (editIndex != null && editIndex < _selectedItems.length) {
        itemToEdit = _selectedItems[editIndex];
        // Find the corresponding item in the dialog items
        selectedItem = dialogItems.firstWhere(
          (item) => item.name == itemToEdit!.name,
          orElse: () => Item(name: itemToEdit!.name, unit: itemToEdit.unit),
        );
      }
      
      final result = await showDialog<Map<String, dynamic>>(
        context: context,
        builder: (context) => _AddItemDialog(
          items: dialogItems,
          searchQuery: _searchQuery,
          currentPage: _currentPage,
          allItems: dialogItems,
          selectedItem: selectedItem, // Pass the selected item to the dialog
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
          initialItem: itemToEdit,
        ),
        barrierDismissible: false,
      );
      
      if (result != null && !_isDisposed && mounted) {
        _safeSetState(() {
          if (editIndex != null && editIndex < _selectedItems.length) {
            // Update existing item
            _selectedItems[editIndex] = result['item'] as InvoiceItem;
          } else {
            // Add new item
            _selectedItems.add(result['item'] as InvoiceItem);
          }
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
    
    if (_selectedAccount == null) {
      if (!_isDisposed) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please select a customer')),
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
          quantity: item.quantity,
          unit: item.unit,
          price: item.price,
          discount: item.discount,

        )..originalItemKey = item.key; // Store reference to original item
      }).toList();

      // Create new invoice
      final invoice = Invoice(
        id: const Uuid().v4(),
        type: InvoiceType.sale,
        partyName: _selectedAccount?.name ?? 'Unknown Customer',
        date: _invoiceDate,
        dueDate: _dueDate,
        invoiceNumber: _invoiceNumberController.text,
        items: newInvoiceItems,
        total: _totalAmount,
        notes: _notesController.text,
        discount: _totalDiscount,
        roundOff: _roundOff,
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
    return _selectedItems.fold(0.0, (sum, item) => sum + item.discount);
  }

  double get _totalAmount => _subTotal - _totalDiscount - _grandDiscountAmount + _roundOff;
  
  void _updateGrandDiscountFromPercent(String value) {
    final percent = double.tryParse(value) ?? 0.0;
    _grandDiscountPercent = percent;
    _grandDiscountAmount = (_subTotal * percent / 100);
    _grandDiscountAmountController.text = _grandDiscountAmount.toStringAsFixed(2);
    setState(() {});
  }

  void _updateGrandDiscountFromAmount(String value) {
    final amount = double.tryParse(value) ?? 0.0;
    _grandDiscountAmount = amount;
    _grandDiscountPercent = _subTotal > 0 ? (amount / _subTotal * 100) : 0.0;
    _grandDiscountPercentController.text = _grandDiscountPercent.toStringAsFixed(2);
    setState(() {});
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
                              (account.phone.toLowerCase().contains(textEditingValue.text.toLowerCase()))
                            );
                          },
                          displayStringForOption: (Account option) => option.name,
                          fieldViewBuilder: (
                            BuildContext context,
                            TextEditingController fieldTextEditingController,
                            FocusNode fieldFocusNode,
                            VoidCallback onFieldSubmitted,
                          ) {
                            // Update the controller text when _selectedAccount changes
                            if (_selectedAccount != null && fieldTextEditingController.text.isEmpty) {
                              fieldTextEditingController.text = _selectedAccount!.name;
                            }
                            
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
                            _selectedAccount = selection;
                            _customerController.text = selection.name;
                            setState(() {}); // Trigger a rebuild
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
                          child: InkWell(
                            onTap: () async {
                              final DateTime? picked = await showDatePicker(
                                context: context,
                                initialDate: _dueDate,
                                firstDate: DateTime.now(),
                                lastDate: DateTime(2100),
                              );
                              if (picked != null && picked != _dueDate) {
                                _safeSetState(() {
                                  _dueDate = picked;
                                });
                              }
                            },
                            child: InputDecorator(
                              decoration: const InputDecoration(
                                labelText: 'Due Date',
                                border: OutlineInputBorder(),
                                suffixIcon: Icon(Icons.calendar_today),
                              ),
                              child: Text(
                                '${_dueDate.day}/${_dueDate.month}/${_dueDate.year}',
                                style: const TextStyle(fontSize: 16),
                              ),
                            ),
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
                              onTap: () => _addItem(editIndex: index),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.edit, color: Colors.blue),
                                    onPressed: () => _addItem(editIndex: index),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.delete, color: Colors.red),
                                    onPressed: () => _removeItem(index),
                                  ),
                                ],
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
                    _buildSummaryRow('Total Items Discount', -_totalDiscount),
                    const SizedBox(height: 8),
                    // Grand Discount Row
                    Row(
                      children: [
                        const Text('Grand Discount:'),
                        const SizedBox(width: 8),
                        // Percentage input (smaller width)
                        SizedBox(
                          width: 120,
                          child: TextFormField(
                            controller: _grandDiscountPercentController,
                            textAlign: TextAlign.right,
                            decoration: const InputDecoration(
                              hintText: '0.0',
                              border: OutlineInputBorder(),
                              contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              isDense: true,
                              suffix: Text('%  '),
                            ),
                            keyboardType: TextInputType.numberWithOptions(decimal: true),
                            onChanged: _updateGrandDiscountFromPercent,
                          ),
                        ),
                        // Amount input
                        Expanded(
                          child: TextFormField(
                            controller: _grandDiscountAmountController,
                            decoration: const InputDecoration(
                              hintText: '0.00',
                              border: OutlineInputBorder(),
                              contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              isDense: true,
                              prefix: Text('  ₹  '),
                            ),
                            keyboardType: TextInputType.numberWithOptions(decimal: true),
                            onChanged: _updateGrandDiscountFromAmount,
                          ),
                        ),
                      ],
                    ),
                    // Display grand discount amount
                    if (_grandDiscountAmount > 0)
                      _buildSummaryRow('Grand Discount', -_grandDiscountAmount, textColor: Colors.red),
                    const SizedBox(height: 16), // Added more space here
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Round Off:'),
                        SizedBox(
                          width: 150, // Fixed width
                          child: TextFormField(
                            controller: _roundOffController,
                            textAlign: TextAlign.right,
                            decoration: const InputDecoration(
                              hintText: '0.00',
                              border: OutlineInputBorder(),
                              contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              isDense: true,
                              prefix: Text('  ₹  '),
                            ),
                            keyboardType: TextInputType.numberWithOptions(decimal: true, signed: true),
                            onChanged: (value) {
                              final roundOff = double.tryParse(value) ?? 0.0;
                              _safeSetState(() {
                                _roundOff = roundOff;
                              });
                            },
                          ),
                        ),
                      ],
                    ),
                    const Divider(),
                    _buildSummaryRow('Total', _totalAmount, isBold: true),
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

  Widget _buildSummaryRow(String label, double amount, {bool isBold = false, Color? textColor}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
              fontSize: isBold ? 16 : 14,
              color: textColor,
            ),
          ),
          Text(
            '₹${amount.toStringAsFixed(2)}',
            style: TextStyle(
              fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
              fontSize: isBold ? 16 : 14,
              color: textColor,
            ),
          ),
        ],
      ),
    );
  }
}
