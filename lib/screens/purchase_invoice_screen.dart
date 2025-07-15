import 'dart:async';
import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
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

class PurchaseInvoiceScreen extends StatefulWidget {
  const PurchaseInvoiceScreen({super.key});

  @override
  PurchaseInvoiceScreenState createState() => PurchaseInvoiceScreenState();
}

class PurchaseInvoiceScreenState extends State<PurchaseInvoiceScreen> {
  PurchaseInvoiceScreenState();

  final List<Item> _allItems = [];
  final List<InvoiceItem> _selectedItems = [];
  final List<Account> _availableSuppliers = [];
  List<Account> _filteredSuppliers = [];
  String _purchaseType = 'Cash';
  String _taxType = 'GST';
  DateTime _invoiceDate = DateTime.now();
  
  // Summary amounts
  bool _isLoading = false;
  bool _isDisposed = false;
  double _roundOff = 0.0;

  // Pagination and Search
  int _currentPage = 0;
  bool _hasMoreItems = true;
  bool _isLoadingMore = false;
  final ScrollController _scrollController = ScrollController();
  String _searchQuery = '';
  Timer? _searchDebounce;
  final TextEditingController _itemSearchController = TextEditingController();
  final TextEditingController _supplierSearchController = TextEditingController();

  // Controllers
  final TextEditingController _notesController = TextEditingController();
  final TextEditingController _invoiceNumberController = TextEditingController();
  final TextEditingController _priceController = TextEditingController();
  final TextEditingController _discountController = TextEditingController();
  Account? _selectedAccount;
  final TextEditingController _roundOffController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  final List<Item> _availableItems = [];


  // Getters for calculated values
  double get _subTotal => _selectedItems.fold(0.0, (sum, item) => sum + (item.quantity * item.price));
  double get _totalDiscount => double.tryParse(_discountController.text) ?? 0.0;
  double get _taxableAmount => _subTotal - _totalDiscount;
  double get _taxAmount {
    return _selectedItems.fold(0.0, (sum, item) {
      final itemTotal = item.quantity * item.price;
      return sum + (itemTotal * (item.taxRate / 100));
    });
  }
  double get _totalAmount => _taxableAmount + _taxAmount + _roundOff;

  void _safeSetState(VoidCallback callback) {
    if (mounted && !_isDisposed) {
      setState(callback);
    }
  }

  @override
  void initState() {
    super.initState();
    _initializeData();  // This should be the only initialization method called here
    _scrollController.addListener(_onScroll);
    _itemSearchController.addListener(_onItemSearchChanged);
    _supplierSearchController.addListener(_onSupplierSearchChanged);
    _notesController.addListener(() {});
    _invoiceNumberController.addListener(() {});
    _priceController.addListener(() {});
    _discountController.addListener(() {});
    _roundOffController.addListener(() {});
  }

  void _onItemSearchChanged() {
    if (_searchDebounce != null && _searchDebounce!.isActive) _searchDebounce!.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 500), () {
      final query = _itemSearchController.text.toLowerCase();
      
      _safeSetState(() {
        if (query.isEmpty) {
          // If search query is empty, show all items
          _availableItems.clear();
          _availableItems.addAll(_allItems);
        } else {
          // Otherwise, filter the items
          final filtered = _allItems.where((item) {
            return item.name.toLowerCase().contains(query) ||
                   (item.hsnCode?.toLowerCase().contains(query) ?? false) ||
                   (item.itemCode?.toLowerCase().contains(query) ?? false);
          }).toList();
          _availableItems.clear();
          _availableItems.addAll(filtered);
        }
      });
      
      // If no items found in current list, try to load more
      if (_availableItems.isEmpty && _hasMoreItems) {
        _loadMoreItems();
      }
    });
  }
  
  void _onSupplierSearchChanged() {
    final query = _supplierSearchController.text.toLowerCase();
    _filterSuppliers(query);
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      _loadMoreItems();
    }
  }
  
  void _filterSuppliers(String query) {
    if (query.isEmpty) {
      setState(() {
        _filteredSuppliers.clear();
        _filteredSuppliers.addAll(_availableSuppliers);
      });
      return;
    }
    
    setState(() {
      _filteredSuppliers = _availableSuppliers.where((supplier) {
        return supplier.name.toLowerCase().contains(query) ||
            supplier.phone.toLowerCase().contains(query) ||
            (supplier.gstinUin?.toLowerCase().contains(query) ?? false);
      }).toList();
    });
  }
  Future<void> _generateInvoiceNumber() async {
    try {
      final invoiceBox = await Hive.openBox<Invoice>('invoices');
      final now = DateTime.now();
      final formattedDate = '${now.year}${now.month.toString().padLeft(2, '0')}';

      // Find the highest invoice number with PINV prefix
      int maxNumber = 0;
      for (var invoice in invoiceBox.values) {
        if (invoice.invoiceNumber.startsWith('PINV')) {
          try {
            final numberStr = invoice.invoiceNumber.split('-').last;
            final number = int.tryParse(numberStr) ?? 0;
            if (number > maxNumber) {
              maxNumber = number;
            }
          } catch (e) {
            // Skip if number parsing fails
          }
        }
      }

      final newNumber = maxNumber + 1;
      if (mounted) {
        setState(() {
          _invoiceNumberController.text = 'PINV-${formattedDate}-${newNumber.toString().padLeft(4, '0')}';
        });
      }
    } catch (e) {
      debugPrint('Error generating invoice number: $e');
      // Fallback to timestamp-based number if there's an error
      if (mounted) {
        setState(() {
          _invoiceNumberController.text = 'PINV-${DateTime.now().millisecondsSinceEpoch}';
        });
      }
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
        // Only add items that aren't already in the list
        final newItems = result.items.where((item) => 
          !_allItems.any((existing) => existing.id == item.id)
        ).toList();
        
        _allItems.addAll(newItems);
        _hasMoreItems = result.hasMore;
        _currentPage++;
        
        // Update available items based on current search
        if (_searchQuery.isEmpty) {
          _availableItems.clear();
          _availableItems.addAll(_allItems);
        } else {
          // Re-apply search filter to include new items
          final filtered = _allItems.where((item) {
            return item.name.toLowerCase().contains(_searchQuery) ||
                   (item.hsnCode?.toLowerCase().contains(_searchQuery) ?? false) ||
                   (item.itemCode?.toLowerCase().contains(_searchQuery) ?? false);
          }).toList();
          _availableItems.clear();
          _availableItems.addAll(filtered);
        }
      });
    } catch (e) {
      debugPrint('Error loading more items: $e');
    } finally {
      _safeSetState(() {
        _isLoadingMore = false;
      });
    }
  }

  Future<void> _loadSuppliers() async {
    if (!mounted) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final box = await Hive.openBox<Account>('accounts');
      if (mounted) {
        setState(() {
          _availableSuppliers.clear();
          // Load all accounts
          _availableSuppliers.addAll(box.values);
          _filteredSuppliers.clear();
          _filteredSuppliers.addAll(_availableSuppliers);
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading accounts: $e')),
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

  Future<void> _initializeData() async {
    _safeSetState(() {
      _isLoading = true;
    });

    try {
      // Generate invoice number and load initial data
      await Future.wait([
        _generateInvoiceNumber(),
        _loadSuppliers(),
      ]);
      
      // Load initial items
      await _loadMoreItems();

      if (_allItems.isEmpty) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('No items found. Please add items first.')),
          );
        }
      }
    } catch (e) {
      debugPrint('Error initializing data: $e');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading items: $e')),
        );
      }
    } finally {
      _safeSetState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Purchase Invoice', style: TextStyle(fontSize: 20)),
        actions: [
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: _isLoading ? null : _saveInvoice,
            tooltip: 'Save Invoice',
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
                          child: InkWell(
                            onTap: () async {
                              final date = await showDatePicker(
                                context: context,
                                initialDate: _invoiceDate,
                                firstDate: DateTime(2000),
                                lastDate: DateTime(2100),
                              );
                              if (date != null && mounted) {
                                setState(() => _invoiceDate = date);
                              }
                            },
                            child: InputDecorator(
                              decoration: const InputDecoration(
                                labelText: 'Date',
                                border: OutlineInputBorder(),
                              ),
                              child: Text(
                                '${_invoiceDate.day}/${_invoiceDate.month}/${_invoiceDate.year}',
                              ),
                            ),
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
                          controller: _supplierSearchController,
                          decoration: InputDecoration(
                            labelText: 'Search Supplier',
                            hintText: 'Search by name, phone, or GSTIN',
                            border: const OutlineInputBorder(),
                            prefixIcon: const Icon(Icons.search),
                            suffixIcon: IconButton(
                              icon: const Icon(Icons.add_circle_outline),
                              onPressed: () {
                                // TODO: Implement add new supplier
                              },
                            ),
                          ),
                          onChanged: (_) => _onSupplierSearchChanged(),
                        ),
                        if (_supplierSearchController.text.isNotEmpty && _filteredSuppliers.isNotEmpty)
                          Container(
                            margin: const EdgeInsets.only(top: 4),
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.grey[300]!),
                              borderRadius: BorderRadius.circular(4),
                              color: Colors.white,
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.grey.withOpacity(0.2),
                                  spreadRadius: 1,
                                  blurRadius: 3,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            constraints: const BoxConstraints(maxHeight: 200),
                            child: ListView.builder(
                              shrinkWrap: true,
                              itemCount: _filteredSuppliers.length,
                              itemBuilder: (context, index) {
                                final supplier = _filteredSuppliers[index];
                                return ListTile(
                                  title: Text(
                                    supplier.name,
                                    style: const TextStyle(fontWeight: FontWeight.w500),
                                  ),
                                  subtitle: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      if (supplier.phone.isNotEmpty)
                                        Text('Phone: ${supplier.phone}'),
                                      if (supplier.gstinUin != null && supplier.gstinUin!.isNotEmpty)
                                        Text('GSTIN: ${supplier.gstinUin}'),
                                    ],
                                  ),
                                  onTap: () {
                                    setState(() {
                                      _selectedAccount = supplier;
                                      _supplierSearchController.text = supplier.name;
                                      // Clear the filtered list to hide the dropdown
                                      _filteredSuppliers.clear();
                                    });
                                  },
                                );
                              },
                            ),
                          ),
                        if (_selectedAccount != null) ...[
                          const SizedBox(height: 12),
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.green[50],
                              border: Border.all(color: Colors.green[100]!),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _selectedAccount!.name,
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                    color: Colors.green[900],
                                  ),
                                ),
                                if (_selectedAccount!.phone.isNotEmpty)
                                  Padding(
                                    padding: const EdgeInsets.only(top: 4),
                                    child: Text(
                                      'Phone: ${_selectedAccount!.phone}',
                                      style: TextStyle(color: Colors.green[800]),
                                    ),
                                  ),
                                if (_selectedAccount!.gstinUin?.isNotEmpty ?? false)
                                  Padding(
                                    padding: const EdgeInsets.only(top: 2),
                                    child: Text(
                                      'GSTIN: ${_selectedAccount!.gstinUin}',
                                      style: TextStyle(color: Colors.green[800]),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Purchase type and tax type
                    Row(
                      children: [
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            value: _purchaseType,
                            items: ['Cash', 'Credit'].map((type) {
                              return DropdownMenuItem(
                                value: type,
                                child: Text(type),
                              );
                            }).toList(),
                            onChanged: (value) {
                              setState(() {
                                _purchaseType = value!;
                              });
                            },
                            decoration: const InputDecoration(
                              labelText: 'Purchase Type',
                              border: OutlineInputBorder(),
                            ),
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
                                setState(() {
                                  _taxType = value;
                                });
                              }
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Items section
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
                              subtitle: Text('${item.quantity} × ${item.price} = ${(item.quantity * item.price).toStringAsFixed(2)}'),
                              trailing: IconButton(
                                icon: const Icon(Icons.delete, color: Colors.red),
                                onPressed: () => _removeItemAt(index),
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

                    // Summary section
                    const Divider(),
                    const Text('Summary', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    _buildSummaryRow('Subtotal', _subTotal.toStringAsFixed(2)),
                    _buildSummaryRow('Total Discount', (-_totalDiscount).toStringAsFixed(2)),
                    _buildSummaryRow('Taxable Amount', _taxableAmount.toStringAsFixed(2)),
                    _buildSummaryRow('Tax Amount', _taxAmount.toStringAsFixed(2)),
                    _buildSummaryRow('Round Off', _roundOff.toStringAsFixed(2)),
                    const Divider(),
                    _buildSummaryRow(
                      'Total',
                      _totalAmount.toStringAsFixed(2),
                      isBold: true,
                    ),
                    const SizedBox(height: 16),

                    // Notes
                    TextFormField(
                      controller: _notesController,
                      decoration: const InputDecoration(
                        labelText: 'Notes',
                        border: OutlineInputBorder(),
                      ),
                      maxLines: 3,
                    ),
                    const SizedBox(height: 24),

                    // Save button
                    ElevatedButton(
                      onPressed: _isLoading ? null : _saveInvoice,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: const Text('Save Purchase Invoice'),
                    ),
                  ],
                ),
              ),
            ),
    );
  }





  void _updateTotals() {
    if (!mounted) return;

    setState(() {
      // Force UI to update by calling the getters
      _subTotal;
      _totalDiscount;
      _taxableAmount;
      _taxAmount;
      _totalAmount;
    });
  }

  void _removeItemAt(int index) {
    setState(() {
      _selectedItems.removeAt(index);
      _updateTotals();
    });
  }



  Future<void> _addItem() async {
    final result = await showDialog<InvoiceItem?>(
      context: context,
      builder: (context) => _AddPurchaseItemDialog(
        items: _availableItems,
        existingItems: _selectedItems,
        itemToEdit: null,
        itemIndex: -1,
      ),
    );

    if (result != null && mounted) {
      setState(() {
        _selectedItems.add(result);
        _updateTotals();
      });
    }
  }


  Future<void> _saveInvoice() async {
    if (!_formKey.currentState!.validate()) return;
    
    _safeSetState(() {
      _isLoading = true;
    });
    
    try {
      final taxAmount = _taxAmount;
      final totalDiscount = _totalDiscount;
      final roundOff = _roundOff;
      final total = _totalAmount;

      // First, update stock levels
      final itemBox = await Hive.openBox<Item>('itemsBox');
      
      // Check for duplicate items in the current selection first
      final seenNames = <String>{};
      for (var item in _selectedItems) {
        if (!seenNames.add(item.name)) {
          if (context.mounted) {
            await showDialog(
              context: context,
              builder: (context) => AlertDialog(
                title: const Text('Duplicate Item'),
                content: Text('Item "${item.name}" appears multiple times in this invoice. Please merge quantities before saving.'),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('OK'),
                  ),
                ],
              ),
            );
          }
          return; // Don't proceed with saving
        }
      }
      
      for (var invoiceItem in _selectedItems) {
        try {
          // Find the item in the database by name (case-insensitive)
          Item? itemToUpdate;
          String? itemKey;
          
          // Search for existing item by name
          for (var key in itemBox.keys) {
            final item = itemBox.get(key);
            if (item != null && item.name.toLowerCase() == invoiceItem.name.toLowerCase()) {
              itemToUpdate = item;
              itemKey = key as String;
              break;
            }
          }
          
          // If item doesn't exist, create a new one
          if (itemToUpdate == null) {
            // Check again with case-insensitive comparison to be extra safe
            final duplicateExists = itemBox.values.any(
              (item) => item.name.toLowerCase() == invoiceItem.name.toLowerCase()
            );
            
            if (duplicateExists) {
              if (context.mounted) {
                await showDialog(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text('Item Exists'),
                    content: Text('An item with the name "${invoiceItem.name}" already exists with different letter casing.'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('OK'),
                      ),
                    ],
                  ),
                );
              }
              continue; // Skip this item
            }
            
            itemToUpdate = Item(
              name: invoiceItem.name.trim(), // Trim whitespace
              unit: invoiceItem.unit,
              taxRate: invoiceItem.taxRate,
              hsnCode: invoiceItem.hsnCode,
              purchaseRate: invoiceItem.price,
              saleRate: invoiceItem.price,
              isStockTracked: true,
            );
            // Generate a new key for the new item
            itemKey = const Uuid().v4();
          }
          
          // Update stock and create stock movement
          if (itemToUpdate.isStockTracked && invoiceItem.quantity > 0) {
            // Create stock movement record
            final stockMovement = StockMovement(
              itemId: itemToUpdate.id,
              quantity: invoiceItem.quantity, // Positive for purchases
              dateTime: DateTime.now(),
              referenceId: _invoiceNumberController.text,
              type: StockMovementType.purchase,
              balance: itemToUpdate.currentStock + invoiceItem.quantity,
            );
            
            // Update item stock and add movement
            itemToUpdate.currentStock += invoiceItem.quantity;
            itemToUpdate.stockMovements.add(stockMovement);
            
            await itemBox.put(itemKey, itemToUpdate);
            debugPrint('Updated stock for ${invoiceItem.name}: +${invoiceItem.quantity} (New stock: ${itemToUpdate.currentStock})');
          }
        } catch (e) {
          debugPrint('Error updating stock for item ${invoiceItem.name}: $e');
          // Continue with other items even if one fails
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Error updating stock for ${invoiceItem.name}: $e')),
            );
          }
        }
      }

      // Create and save the invoice
      final invoice = Invoice(
        id: const Uuid().v4(),
        type: InvoiceType.purchase,
        partyName: _selectedAccount?.name ?? 'Unknown Supplier',
        date: _invoiceDate,
        invoiceNumber: _invoiceNumberController.text,
        taxType: _taxType,
        items: List<InvoiceItem>.from(_selectedItems),
        total: total,
        notes: _notesController.text,
        discount: totalDiscount,
        roundOff: roundOff,
        totalTaxAmount: taxAmount,
        saleType: 'Purchase',
        accountKey: _selectedAccount?.key,
      );
      
      final invoiceBox = await Hive.openBox<Invoice>('invoices');
      await invoiceBox.put(invoice.id, invoice);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Purchase saved successfully')),
        );
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      if (mounted) {
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

  @override
  void dispose() {
    _isDisposed = true;
    _scrollController.dispose();
    _itemSearchController.dispose();
    _supplierSearchController.dispose();
    _notesController.dispose();
    _invoiceNumberController.dispose();
    _priceController.dispose();
    _discountController.dispose();
    _roundOffController.dispose();
    if (_searchDebounce != null && _searchDebounce!.isActive) {
      _searchDebounce!.cancel();
    }
    super.dispose();
  }

  Widget _buildSummaryRow(String label, String value, {bool isBold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: isBold 
                ? const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)
                : null,
          ),
          Text(
            value,
            style: isBold 
                ? const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)
                : null,
          ),
        ],
      ),
    );
  }
}

class _AddPurchaseItemDialog extends StatefulWidget {
  final List<Item> items;
  final List<InvoiceItem> existingItems;
  final InvoiceItem? itemToEdit;
  final int itemIndex;

  const _AddPurchaseItemDialog({
    required this.items,
    required this.existingItems,
    this.itemToEdit,
    required this.itemIndex,
  });

  @override
  _AddPurchaseItemDialogState createState() => _AddPurchaseItemDialogState();
}

class _AddPurchaseItemDialogState extends State<_AddPurchaseItemDialog> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _quantityController = TextEditingController(text: '1');
  final TextEditingController _priceController = TextEditingController();
  final TextEditingController _discountController = TextEditingController(text: '0');
  final TextEditingController _taxRateController = TextEditingController(text: '18');
  final TextEditingController _itemSearchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  Timer? _searchDebounce;
  List<Item> _filteredItems = [];
  Item? _selectedItem;
  String _selectedTaxType = 'GST'; // GST, IGST, Exempt, Tax Incl.
  String _selectedGSTRate = '18%'; // Default GST rate
  bool _isTaxInclusive = false;

  double _total = 0;
  double _taxAmount = 0;
  double _discountAmount = 0;
  double _finalTotal = 0;
  bool _isFreeItem = false;
  bool _isManualPrice = false;

  void _onItemSelected(Item item) {
    setState(() {
      _selectedItem = item;
      _priceController.text = (item.purchaseRate ?? 0.0).toStringAsFixed(2);
      _itemSearchController.text = item.name;
      _calculateTotals();
    });
  }

  @override
  void initState() {
    super.initState();
    _taxRateController.text = '18.0'; // Default tax rate
    _filteredItems = List.from(widget.items);

    // Initialize with item to edit if provided
    if (widget.itemToEdit != null) {
      _selectedItem = widget.items.firstWhere(
            (item) => item.name == widget.itemToEdit?.name,
        orElse: () =>
            Item(
              name: widget.itemToEdit?.name ?? 'New Item',
              hsnCode: widget.itemToEdit?.hsnCode,
              unit: widget.itemToEdit?.unit ?? 'PCS',
              purchaseRate: widget.itemToEdit?.price ?? 0.0,
              taxRate: widget.itemToEdit?.taxRate ?? 0.0,
            ),
      );
      _quantityController.text = (widget.itemToEdit?.quantity ?? 1).toString();
      _priceController.text =
          (widget.itemToEdit?.price ?? 0.0).toStringAsFixed(2);
      _discountController.text =
          (widget.itemToEdit?.discount ?? 0.0).toStringAsFixed(2);

      // Set tax type and rate from the item being edited
      _selectedTaxType = widget.itemToEdit?.taxType ?? 'GST';
      _isTaxInclusive = widget.itemToEdit?.isTaxInclusive ?? false;
      _selectedGSTRate = '${widget.itemToEdit?.taxRate ?? 18.0}%';

      _isFreeItem = widget.itemToEdit?.isFreeItem ?? false;
      _isManualPrice = true;
    } else {
      // Set default quantity for new items
      _quantityController.text = '1';
      _priceController.text = '0.00';
      _discountController.text = '0.00';
    }
  }

  void _updatePrice() {
    if (_selectedItem != null && !_isManualPrice && !_isFreeItem) {
      setState(() {
        _priceController.text =
            _selectedItem!.purchaseRate?.toStringAsFixed(2) ?? '0.00';
        _calculateTotals();
      });
    } else if (_isFreeItem) {
      setState(() {
        _priceController.text = '0.00';
        _calculateTotals();
      });
    }
  }

  void _calculateTotals() {
    final quantity = double.tryParse(_quantityController.text) ?? 0;
    final price = double.tryParse(_priceController.text) ?? 0;
    final discount = double.tryParse(_discountController.text) ?? 0;

    // Get the actual tax rate from the selected GST rate
    final taxRate = _selectedGSTRate == 'Item Wise' ||
        _selectedGSTRate == 'Exempt' || _selectedGSTRate == 'Tax Incl.'
        ? 0.0
        : double.tryParse(_selectedGSTRate.replaceAll('%', '')) ?? 0.0;

    double subtotal = quantity * price;
    double discountAmount = (subtotal * discount) / 100;
    double taxableAmount = subtotal - discountAmount;
    double taxAmount = 0.0;
    double total;

    // Handle different tax types
    if (_selectedTaxType == 'Exempt') {
      taxAmount = 0.0;
      total = taxableAmount;
    } else if (_isTaxInclusive) {
      // For tax inclusive pricing, calculate the pre-tax amount
      double rate = taxRate / 100;
      double preTaxAmount = taxableAmount / (1 + rate);
      taxAmount = taxableAmount - preTaxAmount;
      total = taxableAmount; // Total includes tax already
    } else {
      // Standard tax calculation (tax exclusive)
      taxAmount = (taxableAmount * taxRate) / 100;
      total = taxableAmount + taxAmount;
    }

    if (mounted) {
      setState(() {
        _total = subtotal;
        _discountAmount = discountAmount;
        _taxAmount = taxAmount;
        _finalTotal = total;
      });
    }
  }

  void _filterItems(String query) {
    if (widget.items.isEmpty) {
      setState(() {
        _filteredItems = [];
      });
      return;
    }
    
    // If query is empty, show all items
    if (query.isEmpty) {
      setState(() {
        _filteredItems = List<Item>.from(widget.items);
      });
      return;
    }

    setState(() {
      if (query.isEmpty) {
        _filteredItems = List<Item>.from(widget.items);
      } else {
        final queryLower = query.toLowerCase();
        _filteredItems = widget.items.where((item) {
          return item.name.toLowerCase().contains(queryLower) ||
              (item.hsnCode?.toLowerCase().contains(queryLower) ?? false) ||
              (item.itemCode?.toLowerCase().contains(queryLower) ?? false) ||
              (item.purchaseRate?.toString().contains(queryLower) ?? false);
        }).toList();
      }
      
      // If there's a selected item that matches the search, keep it selected
      if (_selectedItem != null &&
          !_filteredItems.any((item) => item.name == _selectedItem!.name)) {
        _selectedItem = null;
      }

      // Debug log
      debugPrint('Searching for: $query');
      debugPrint('Total items: ${widget.items.length}');
      debugPrint('Filtered items: ${_filteredItems.length}');
      if (_filteredItems.isNotEmpty) {
        debugPrint('First filtered item: ${_filteredItems.first.name}');
      }
    });
  }

  @override
  void dispose() {
    _quantityController.dispose();
    _priceController.dispose();
    _discountController.dispose();
    _taxRateController.dispose();
    _itemSearchController.dispose();
    _scrollController.dispose();
    if (_searchDebounce != null && _searchDebounce!.isActive) {
      _searchDebounce!.cancel();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.9,
          maxWidth: MediaQuery.of(context).size.width * 0.9,
        ),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header with title and close button
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      widget.itemToEdit == null ? 'Add Item' : 'Edit Item',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
              
              // Scrollable content
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
              // Combined Search and Select Item
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Select Item',
                      style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Container(
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey.shade300),
                      borderRadius: BorderRadius.circular(4.0),
                    ),
                    child: Column(
                      children: [
                        // Search field
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 12.0),
                          child: TextField(
                            controller: _itemSearchController,
                            decoration: const InputDecoration(
                              hintText: 'Search items...',
                              border: InputBorder.none,
                              prefixIcon: Icon(Icons.search, size: 20),
                              contentPadding: EdgeInsets.symmetric(
                                  vertical: 12),
                              isDense: true,
                            ),
                            onChanged: _filterItems,
                          ),
                        ),
                        const Divider(height: 1, thickness: 1),
                        // Selected item display
                        if (_selectedItem != null)
                          ListTile(
                            dense: true,
                            contentPadding: const EdgeInsets.symmetric(
                                horizontal: 12),
                            title: Text(
                              _selectedItem!.name,
                              style: const TextStyle(
                                  fontWeight: FontWeight.w500),
                            ),
                            subtitle: _selectedItem!.hsnCode?.isNotEmpty == true
                                ? Text(
                              'HSN: ${_selectedItem!
                                  .hsnCode} | Rate: ?${_selectedItem!
                                  .purchaseRate?.toStringAsFixed(2) ?? '0.00'}',
                              style: Theme
                                  .of(context)
                                  .textTheme
                                  .bodySmall
                                  ?.copyWith(
                                color: Colors.grey[600],
                              ),
                            )
                                : null,
                            trailing: IconButton(
                              icon: const Icon(Icons.close, size: 18),
                              onPressed: () {
                                setState(() {
                                  _selectedItem = null;
                                  _itemSearchController.clear();
                                  _filterItems('');
                                  _calculateTotals();
                                });
                              },
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                            ),
                          ),
                        // Items list
                        if (_selectedItem == null)
                          SizedBox(
                            height: 200,
                            child: _filteredItems.isEmpty
                                ? const Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.search_off, size: 48,
                                      color: Colors.grey),
                                  SizedBox(height: 8),
                                  Text('No items found'),
                                ],
                              ),
                            )
                                : ListView.builder(
                              itemCount: _filteredItems.length,
                              itemBuilder: (context, index) {
                                final item = _filteredItems[index];
                                return Card(
                                  margin: const EdgeInsets.symmetric(
                                      vertical: 4, horizontal: 0),
                                  elevation: 0,
                                  child: ListTile(
                                    title: Text(
                                      item.name,
                                      style: const TextStyle(
                                          fontWeight: FontWeight.w500),
                                    ),
                                    subtitle: Column(
                                      crossAxisAlignment: CrossAxisAlignment
                                          .start,
                                      children: [
                                        if (item.hsnCode?.isNotEmpty ?? false)
                                          Text('HSN: ${item.hsnCode}'),
                                        Text('Rate: ?${item.purchaseRate
                                            ?.toStringAsFixed(2) ?? '0.00'}')
                                      ],
                                    ),
                                    trailing: Text(
                                      '${item.currentStock} ${item.unit}',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 14,
                                      ),
                                    ),
                                    onTap: () {
                                      _onItemSelected(item);
                                    },
                                    tileColor: _selectedItem == item
                                        ? Theme
                                        .of(context)
                                        .primaryColor
                                        .withOpacity(0.1)
                                        : null,
                                  ),
                                );
                              },
                            ),
                          ),
                      ],
                    ),
                  ),
                  if (_filteredItems.isEmpty &&
                      _itemSearchController.text.isNotEmpty)
                    const Padding(
                      padding: EdgeInsets.only(top: 8.0, left: 4.0),
                      child: Text(
                        'No matching items found',
                        style: TextStyle(color: Colors.red, fontSize: 12),
                      ),
                    ),
                ],
              ),

              const SizedBox(height: 16),

              // Quantity Field
              TextFormField(
                controller: _quantityController,
                decoration: InputDecoration(
                  labelText: 'Quantity',
                  border: const OutlineInputBorder(),
                  suffixText: _selectedItem?.unit ?? 'pcs',
                  hintText: 'Enter quantity',
                ),
                keyboardType: const TextInputType.numberWithOptions(
                    decimal: true),
                onChanged: (value) => _calculateTotals(),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter quantity';
                  }
                  final qty = double.tryParse(value);
                  if (qty == null || qty <= 0) {
                    return 'Please enter a valid quantity';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 16),

              // Price Row with Toggle
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _priceController,
                      decoration: InputDecoration(
                        labelText: 'Price',
                        border: const OutlineInputBorder(),
                        enabled: !_isFreeItem,
                      ),
                      keyboardType: const TextInputType.numberWithOptions(
                          decimal: true),
                      style: _isFreeItem
                          ? const TextStyle(color: Colors.grey)
                          : null,
                      onChanged: (value) => _calculateTotals(),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Tooltip(
                    message: _isManualPrice
                        ? 'Autofill Price'
                        : 'Edit Price Manually',
                    child: IconButton(
                      icon: Icon(
                          _isManualPrice ? Icons.auto_awesome : Icons.edit),
                      onPressed: () {
                        setState(() {
                          _isManualPrice = !_isManualPrice;
                          _updatePrice();
                          _calculateTotals();
                        });
                      },
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 16),

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
                        _isTaxInclusive = false;
                        _selectedGSTRate = '0%';
                      } else if (value == 'Tax Incl.') {
                        _isTaxInclusive = true;
                      }
                      _calculateTotals();
                    });
                  }
                },
              ),

              const SizedBox(height: 16),

              // GST Rate Dropdown (only show if not Exempt)
              if (_selectedTaxType != 'Exempt')
                DropdownButtonFormField<String>(
                  value: _selectedGSTRate,
                  decoration: const InputDecoration(
                    labelText: 'GST Rate',
                    border: OutlineInputBorder(),
                  ),
                  items: AppConstants.gstRates.map((rate) {
                    return DropdownMenuItem(
                      value: rate,
                      child: Text(rate),
                    );
                  }).toList(),
                  onChanged: (value) {
                    if (value != null) {
                      setState(() {
                        _selectedGSTRate = value;
                        _calculateTotals();
                      });
                    }
                  },
                ),

              const SizedBox(height: 16),

              // Discount Field
              TextField(
                controller: _discountController,
                decoration: const InputDecoration(
                  labelText: 'Discount (?)',
                  border: OutlineInputBorder(),
                  prefixText: '-?',
                ),
                keyboardType: const TextInputType.numberWithOptions(
                    decimal: true),
                onChanged: (value) => _calculateTotals(),
              ),

              const SizedBox(height: 8),

              // Tax Inclusive Checkbox (only show if not Exempt)
              if (_selectedTaxType != 'Exempt' &&
                  _selectedTaxType != 'Tax Incl.')
                CheckboxListTile(
                  title: const Text('Tax Inclusive'),
                  value: _isTaxInclusive,
                  onChanged: (value) {
                    setState(() {
                      _isTaxInclusive = value ?? false;
                      _calculateTotals();
                    });
                  },
                ),

              // Free Item Toggle
              CheckboxListTile(
                title: const Text('Mark as Free Item'),
                value: _isFreeItem,
                onChanged: (bool? value) {
                  setState(() {
                    _isFreeItem = value ?? false;
                    _updatePrice();
                    _calculateTotals();
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
                      _buildSummaryRow(
                          'Subtotal', '?${_total.toStringAsFixed(2)}'),
                      _buildSummaryRow('Discount',
                          '-?${_discountAmount.toStringAsFixed(2)}'),
                      _buildSummaryRow('Taxable Amount',
                          '?${(_total - _discountAmount).toStringAsFixed(2)}'),
                      _buildSummaryRow(
                          'Tax (${_selectedTaxType == 'Exempt'
                              ? '0'
                              : _selectedGSTRate})',
                          '?${_taxAmount.toStringAsFixed(2)}'
                      ),
                      const Divider(),
                      _buildSummaryRow(
                        'Total',
                        '?${_finalTotal.toStringAsFixed(2)}',
                        isBold: true,
                      ),
                    ],
                  ),
                ),
              ),
                    ],  // End of ScrollView Column children
                  ),
                ),
              ),
              
              // Dialog actions
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: Theme.of(context).cardColor,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 4,
                      offset: const Offset(0, -2),
                    ),
                  ],
                ),
                child: SafeArea(
                  top: false,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('CANCEL'),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton(
                        onPressed: _saveItem,
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                        ),
                        child: const Text('ADD ITEM'),
                      ),
                    ],
                  ),
                ),
              ),
            ],  // End of main Column children
          ),
        ),
      ),
    );
  }

  Widget _buildSummaryRow(String label, String value, {bool isBold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: isBold 
                ? const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)
                : null,
          ),
          Text(
            value,
            style: isBold 
                ? const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)
                : null,
          ),
        ],
      ),
    );
  }

  void _saveItem() {
    if (_formKey.currentState?.validate() ?? false) {
      if (_selectedItem == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please select an item')),
        );
        return;
      }

      final quantity = int.tryParse(_quantityController.text) ?? 1;
      if (quantity <= 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please enter a valid quantity')),
        );
        return;
      }
      // Get the tax rate from the selected GST rate
      final taxRate = _selectedGSTRate == 'Item Wise' ||
          _selectedGSTRate == 'Exempt' || _selectedGSTRate == 'Tax Incl.'
          ? 0.0
          : double.tryParse(_selectedGSTRate.replaceAll('%', '')) ?? 0.0;

      // Create the invoice item with all tax-related fields
      final item = InvoiceItem(
        name: _selectedItem!.name,
        hsnCode: _selectedItem!.hsnCode,
        quantity: int.parse(_quantityController.text),
        unit: _selectedItem!.unit,
        price: double.parse(_priceController.text),
        taxRate: taxRate,
        taxType: _selectedTaxType,
        discount: double.tryParse(_discountController.text) ?? 0.0,
        cgst: 0.0,
        // Will be calculated in applyGST
        sgst: 0.0,
        // Will be calculated in applyGST
        igst: 0.0,
        // Will be calculated in applyGST
        isFreeItem: _isFreeItem,
        isTaxInclusive: _isTaxInclusive,
      );

      // Apply GST based on whether it's an intra-state transaction
      // In a real app, you would get this from the company settings
      final isIntraState = true; // Default to intra-state
      item.applyGST(isIntraState);

      if (mounted) {
        Navigator.of(context).pop(item);
      }
    }
  }
}