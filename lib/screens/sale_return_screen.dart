import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';
import '../models/invoice.dart';
import '../models/invoice_item.dart';
import '../enums/invoice_type.dart';
import '../enums/account_type.dart';
import '../constants/app_constants.dart';

// Extension for enum to string conversion
extension InvoiceTypeExtension on InvoiceType {
  String get name => toString().split('.').last;
}

extension AccountTypeExtension on AccountType {
  String get name => toString().split('.').last;
}

class SaleReturnScreen extends StatefulWidget {
  final Invoice? originalInvoice;
  
  const SaleReturnScreen({
    super.key,
    this.originalInvoice,
  });

  @override
  _SaleReturnScreenState createState() => _SaleReturnScreenState();
}

class _SaleReturnScreenState extends State<SaleReturnScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _customerSearchController = TextEditingController();
  late final TextEditingController _invoiceNumberController = TextEditingController();
  late final TextEditingController _notesController = TextEditingController();
  late final TextEditingController _returnDateController = TextEditingController();
  
  // State variables
  bool _isLoading = false;
  List<dynamic> _filteredCustomers = [];
  List<dynamic> _availableCustomers = [];
  List<Invoice> _customerInvoices = [];
  List<InvoiceItem> _availableItems = [];
  dynamic _selectedCustomer;
  Invoice? _selectedInvoice;
  List<InvoiceItem> _selectedItems = [];
  double _globalDiscount = 0.0;
  double _roundOff = 0.0;
  DateTime _invoiceDate = DateTime.now();
  String _taxType = 'GST';
  
  // Calculate subtotal amount (sum of all items before tax and discounts)
  double get _subTotal {
    return _selectedItems.fold(0.0, (sum, item) {
      return sum + (item.quantity * item.price) - item.discount;
    });
  }
  
  // Calculate total tax amount
  double get _totalTax {
    return _selectedItems.fold(0.0, (sum, item) {
      final itemTotal = (item.quantity * item.price) - item.discount;
      return sum + (itemTotal * item.taxRate / 100);
    });
  }
  
  // Calculate total amount including tax, discount, and round off
  double get _calculatedTotalAmount {
    return (_subTotal + _totalTax - _globalDiscount) + _roundOff;
  }
  
  @override
  void initState() {
    super.initState();
    _loadData();
    _generateInvoiceNumber();
    _returnDateController.text = DateFormat('dd/MM/yyyy').format(DateTime.now());
    _invoiceDate = DateTime.now();
  }
  
  @override
  void dispose() {
    _customerSearchController.dispose();
    _invoiceNumberController.dispose();
    _notesController.dispose();
    _returnDateController.dispose();
    super.dispose();
  }
  
  void _updateSelectedInvoice(Invoice? invoice) {
    if (!mounted) return;
    
    setState(() {
      _selectedInvoice = invoice;
      if (invoice != null) {
        _availableItems = invoice.items.map((item) => item.copyWith(
          quantity: 0, // Reset quantity for return
        )).toList();
      } else {
        _availableItems.clear();
      }
      _selectedItems.clear();
      _updateCalculations();
    });
  }
  
  void _updateCalculations() {
    if (!mounted) return;
    setState(() {}); // Trigger a rebuild to update the UI with the latest calculations
  }

  Widget _buildCustomerSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Customer', style: TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        TextFormField(
          controller: _customerSearchController,
          decoration: InputDecoration(
            hintText: 'Search customer...',
            prefixIcon: const Icon(Icons.search),
            border: const OutlineInputBorder(),
            suffixIcon: _customerSearchController.text.isNotEmpty
                ? IconButton(
                    icon: const Icon(Icons.clear),
                    onPressed: () {
                      _customerSearchController.clear();
                      _filterCustomers('');
                    },
                  )
                : null,
          ),
          onChanged: _filterCustomers,
        ),
        const SizedBox(height: 8),
        if (_filteredCustomers.isNotEmpty)
          Container(
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey[300]!),
              borderRadius: BorderRadius.circular(4),
            ),
            constraints: const BoxConstraints(maxHeight: 200),
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: _filteredCustomers.length,
              itemBuilder: (context, index) {
                final customer = _filteredCustomers[index];
                final name = customer is Map ? customer['name'] : customer.name;
                final phone = customer is Map ? customer['phone'] : customer.phone;
                
                return ListTile(
                  title: Text(name.toString()),
                  subtitle: phone != null ? Text(phone.toString()) : null,
                  onTap: () {
                    setState(() {
                      _selectedCustomer = customer;
                      _customerSearchController.text = name.toString();
                      _loadCustomerInvoices(customer);
                    });
                  },
                );
              },
            ),
          ),
      ],
    );
  }
  
  Widget _buildInvoiceSection() {
    if (_selectedCustomer == null) return const SizedBox.shrink();
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Original Invoice', style: TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        _customerInvoices.isEmpty
            ? const Text('No invoices found for this customer')
            : DropdownButtonFormField<dynamic>(
                value: _selectedInvoice,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  hintText: 'Select original invoice',
                ),
                items: _customerInvoices.map<DropdownMenuItem<Invoice>>((invoice) {
                  final invNumber = invoice.invoiceNumber;
                  final invDate = DateFormat('dd/MM/yyyy').format(invoice.date);
                      
                  return DropdownMenuItem<Invoice>(
                    value: invoice,
                    child: Text('$invNumber - $invDate'),
                  );
                }).toList(),
                onChanged: (value) {
                  if (!mounted) return;
                  final invoice = value as Invoice?;
                  
                  _updateSelectedInvoice(invoice);
                },
              ),
      ],
    );
  }
  
  Widget _buildReturnItemsList() {
    if (_selectedItems.isEmpty) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(16.0),
          child: Center(child: Text('No items added for return')),
        ),
      );
    }
    
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Padding(
              padding: EdgeInsets.all(8.0),
              child: Text('Return Items', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            ),
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _selectedItems.length,
              itemBuilder: (context, index) {
                final item = _selectedItems[index];
                final name = item.name;
                final qty = item.quantity;
                final price = item.price;
                final total = qty * price;
                
                return ListTile(
                  title: Text(name.toString()),
                  subtitle: Text('Qty: $qty x ${NumberFormat.currency(symbol: '₹').format(price)} = ${NumberFormat.currency(symbol: '₹').format(total)}'),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete, color: Colors.red),
                    onPressed: () => _removeItem(index),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildSummarySection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text('Summary', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 8),
            _buildSummaryRow('Subtotal', _subTotal),
            _buildSummaryRow('Tax', _totalTax),
            if (_globalDiscount > 0) _buildSummaryRow('Discount', -_globalDiscount),
            if (_roundOff != 0) _buildSummaryRow('Round Off', _roundOff),
            const Divider(),
            _buildSummaryRow('Total', _calculatedTotalAmount, isBold: true, isTotal: true),
          ],
        ),
      ),
    );
  }
  

  
  Future<void> _loadData() async {
    if (mounted) setState(() => _isLoading = true);
    
    try {
      // Load items
      final itemBox = await Hive.openBox<dynamic>('items');
      _availableItems = itemBox.values.map((item) {
        if (item is InvoiceItem) return item;
        if (item is Map) {
          return InvoiceItem(
            name: item['name'] ?? '',
            quantity: item['quantity'] ?? 0,
            unit: item['unit'] ?? 'pcs',
            price: (item['price'] ?? 0.0).toDouble(),
            taxRate: (item['taxRate'] ?? 0.0).toDouble(),
            discount: (item['discount'] ?? 0.0).toDouble(),
            cgst: (item['cgst'] ?? 0.0).toDouble(),
            sgst: (item['sgst'] ?? 0.0).toDouble(),
            igst: (item['igst'] ?? 0.0).toDouble(),
            hsnCode: item['hsnCode'],
            returnReason: item['returnReason'],
            originalInvoiceItemId: item['originalInvoiceItemId'],
            isFreeItem: item['isFreeItem'] ?? false,
          );
        }
        throw Exception('Invalid item data type: ${item.runtimeType}');
      }).toList().cast<InvoiceItem>();
      
      // Load customers
      final accountBox = await Hive.openBox<dynamic>('accounts');
      _availableCustomers = accountBox.values
          .where((account) => account is Map 
              ? (account['type'] == 'customer' || account['type'] == 'both')
              : (account.type == 'customer' || account.type == 'both'))
          .toList();
      _filteredCustomers = List.from(_availableCustomers);
      
      if (widget.originalInvoice != null) {
        _selectedCustomer = _availableCustomers.firstWhere(
          (c) {
            final name = c is Map ? c['name'] : c.name;
            return name == widget.originalInvoice!.partyName;
          },
          orElse: () => null,
        );
        if (_selectedCustomer != null) {
          await _loadCustomerInvoices(_selectedCustomer!);
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading data: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }
  
  Future<void> _loadCustomerInvoices(dynamic customer) async {
    if (mounted) setState(() => _isLoading = true);
    
    try {
      final invoiceBox = await Hive.openBox<Invoice>('invoices');
      final customerName = customer is Map ? customer['name'] : customer.name;
      
      _customerInvoices = invoiceBox.values.where((invoice) {
        final invPartyName = invoice.partyName;
        final invType = invoice.type.toString().toLowerCase();
        return invPartyName == customerName && invType.contains('sale');
      }).toList();
          
      if (widget.originalInvoice != null) {
        _selectedInvoice = _customerInvoices.cast<Invoice?>().firstWhere(
          (inv) => inv?.id == widget.originalInvoice!.id,
          orElse: () => null,
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading invoices: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }
  
  void _filterCustomers(String query) {
    setState(() {
      _filteredCustomers = _availableCustomers
          .where((customer) {
            final name = customer is Map ? customer['name'] : customer.name;
            final phone = customer is Map ? customer['phone'] : customer.phone;
            return name.toString().toLowerCase().contains(query.toLowerCase()) ||
                   (phone?.toString() ?? '').toLowerCase().contains(query.toLowerCase());
          })
          .toList();
    });
  }
  
  Future<void> _generateInvoiceNumber() async {
    try {
      final invoiceBox = await Hive.openBox<dynamic>('invoices');
      final now = DateTime.now();
      final year = now.year.toString().substring(2);
      final month = now.month.toString().padLeft(2, '0');
      final prefix = 'SR$year$month';
      
      // Find the highest invoice number with this prefix
      int maxNumber = 0;
      for (var invoice in invoiceBox.values) {
        final invNumber = invoice is Map ? invoice['invoiceNumber'] : invoice.invoiceNumber;
        if (invNumber.toString().startsWith(prefix)) {
          try {
            final number = int.parse(invNumber.toString().replaceAll(prefix, ''));
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
          _invoiceNumberController.text = '$prefix${newNumber.toString().padLeft(3, '0')}';
        });
      }
    } catch (e) {
      // Fallback to a default number if there's an error
      if (mounted) {
        setState(() {
          _invoiceNumberController.text = 'SR${DateTime.now().millisecondsSinceEpoch}';
        });
      }
    }
  }
  
  Future<void> _addReturnItem() async {
    if (_selectedCustomer == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please select a customer first')),
        );
      }
      return;
    }
    
    final result = await showDialog<InvoiceItem>(
      context: context,
      builder: (context) => _AddReturnItemDialog(
        availableItems: _availableItems,
        existingItems: _selectedItems,
        onItemAdded: (item) {
          // This will be called when an item is added from the dialog
          if (mounted) {
            setState(() {
              _selectedItems.add(item);
            });
          }
        },
        formKey: _formKey,
        buildSummaryRow: _buildSummaryRow,
      ),
    );
    
    if (result != null && mounted) {
      setState(() {
        _selectedItems.add(result);
      });
    }
  }
  
  void _removeItem(int index) {
    setState(() {
      _selectedItems.removeAt(index);
    });
  }
  
  Future<void> _saveReturn() async {
    if (!_formKey.currentState!.validate()) return;
    
    if (_selectedItems.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please add at least one item')),
        );
      }
      return;
    }

    if (!mounted) return;
    setState(() => _isLoading = true);

    try {
      final box = await Hive.openBox<Invoice>('invoices');
      
      // Calculate totals
      final subTotal = _selectedItems.fold(0.0, (sum, item) => sum + (item.quantity * item.price));
      final taxAmount = _selectedItems.fold(0.0, (sum, item) => sum + item.taxAmount);
      final totalDiscount = _globalDiscount;
      final roundOff = _roundOff;
      final total = subTotal + taxAmount - totalDiscount + roundOff;
      
      final invoice = Invoice(
        id: const Uuid().v4(),
        type: InvoiceType.saleReturn,
        partyName: _selectedCustomer is Map 
            ? _selectedCustomer['name'] 
            : _selectedCustomer?.name ?? 'Walk-in Customer',
        date: _invoiceDate,
        invoiceNumber: _invoiceNumberController.text,
        taxType: _taxType,
        items: List<InvoiceItem>.from(_selectedItems),
        total: total,
        notes: _notesController.text,
        discount: totalDiscount,
        roundOff: roundOff,
        totalTaxAmount: taxAmount,
        saleType: 'Sale Return',
        originalInvoiceNumber: _selectedInvoice?.invoiceNumber,
        isReturn: true,
        accountKey: _selectedCustomer is Map ? null : _selectedCustomer?.key,
      );

      await box.add(invoice);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Return saved successfully')),
        );
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving return: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('New Sale Return'),
        actions: [
          IconButton(
            icon: _isLoading 
                ? const CircularProgressIndicator(color: Colors.white)
                : const Icon(Icons.save),
            onPressed: _isLoading ? null : _saveReturn,
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
                    // Customer section
                    _buildCustomerSection(),
                    const SizedBox(height: 16),
                    
                    // Invoice section
                    _buildInvoiceSection(),
                    const SizedBox(height: 16),
                    
                    // Return items list
                    _buildReturnItemsList(),
                    const SizedBox(height: 16),
                    
                    // Add item button
                    ElevatedButton.icon(
                      onPressed: _addReturnItem,
                      icon: const Icon(Icons.add),
                      label: const Text('Add Item'),
                    ),
                    const SizedBox(height: 16),
                    
                    // Summary section
                    _buildSummarySection(),
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
                    SizedBox(
                      height: 50,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _saveReturn,
                        child: _isLoading
                            ? const SizedBox(
                                width: 24,
                                height: 24,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                ),
                              )
                            : const Text(
                                'SAVE RETURN',
                                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                              ),
                      ),
                    ),
                    
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ),
    );
  }
  
  Widget _buildSummaryRow(String label, double amount, {bool isBold = false, bool isTotal = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: isBold
                ? const TextStyle(fontWeight: FontWeight.bold)
                : null,
          ),
          Text(
            '₹${amount.toStringAsFixed(2)}',
            style: isBold || isTotal
                ? const TextStyle(fontWeight: FontWeight.bold)
                : null,
          ),
        ],
      ),
    );
  }
}

class _AddReturnItemDialog extends StatefulWidget {
  final List<dynamic> availableItems;
  final List<dynamic> existingItems;
  final Function(InvoiceItem) onItemAdded;
  final GlobalKey<FormState> formKey;
  final Widget Function(String label, double amount, {bool isBold, bool isTotal}) buildSummaryRow;

  const _AddReturnItemDialog({
    Key? key,
    required this.availableItems,
    required this.existingItems,
    required this.onItemAdded,
    required this.formKey,
    required this.buildSummaryRow,
  }) : super(key: key);

  @override
  _AddReturnItemDialogState createState() => _AddReturnItemDialogState();
}

class _AddReturnItemDialogState extends State<_AddReturnItemDialog> {
  final _formKey = GlobalKey<FormState>();
  dynamic _selectedItem;
  final TextEditingController _quantityController = TextEditingController(text: '1');
  final TextEditingController _priceController = TextEditingController();
  final TextEditingController _discountController = TextEditingController(text: '0');
  final TextEditingController _taxRateController = TextEditingController(text: '0');
  final TextEditingController _reasonController = TextEditingController();
  bool _isLoading = false;
  bool _isManualPrice = false;
  bool _isFreeItem = false;
  String _selectedTaxType = 'GST'; // GST, IGST, Exempt, Tax Incl.
  late List<dynamic> _availableItemsList;

  @override
  void initState() {
    super.initState();
    _availableItemsList = widget.availableItems;
    _setupListeners();
  }

  void _setupListeners() {
    _quantityController.addListener(_updateTotal);
    _priceController.addListener(_updateTotal);
    _discountController.addListener(_updateTotal);
    _taxRateController.addListener(_updateTotal);
    _priceController.addListener(_updatePrice);
    _taxRateController.addListener(_updateTaxRate);
  }

  void _updateTotal() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _quantityController.removeListener(_updateTotal);
    _priceController.removeListener(_updateTotal);
    _discountController.removeListener(_updateTotal);
    _taxRateController.removeListener(_updateTotal);
    _priceController.removeListener(_updatePrice);
    _taxRateController.removeListener(_updateTaxRate);
    
    _quantityController.dispose();
    _priceController.dispose();
    _discountController.dispose();
    _taxRateController.dispose();
    _reasonController.dispose();
    super.dispose();
  }
  


  // Calculate the tax amount based on tax type
  double get _taxAmount {
    final taxRate = double.tryParse(_taxRateController.text) ?? 0;
    
    if (_selectedTaxType == 'Exempt') {
      return 0.0;
    } else if (_selectedTaxType == 'Tax Incl.') {
      // For tax-inclusive pricing, back-calculate the tax
      return _subtotal - (_subtotal / (1 + (taxRate / 100)));
    } else {
      // Regular GST/IGST calculation
      return _subtotal * (taxRate / 100);
    }
  }

  // Calculate the total amount
  double get _totalAmount {
    if (_selectedTaxType == 'Tax Incl.') {
      // For tax-inclusive pricing, subtotal already includes tax
      return _subtotal;
    } else {
      // For regular pricing, add tax to subtotal
      return _subtotal + _taxAmount;
    }
  }

  // Handle form submission
  void _submitForm() {
    if (!_formKey.currentState!.validate()) return;
    
    if (_selectedItem == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select an item')),
      );
      return;
    }

    final quantity = int.tryParse(_quantityController.text) ?? 0;
    if (quantity <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid quantity')),
      );
      return;
    }

    // Calculate CGST/SGST or IGST based on tax type
    double cgst = 0.0, sgst = 0.0, igst = 0.0;
    final taxAmount = _taxAmount;
    
    if (_selectedTaxType == 'GST') {
      cgst = taxAmount / 2; // Split 50/50 for CGST/SGST
      sgst = taxAmount / 2;
    } else if (_selectedTaxType == 'IGST') {
      igst = taxAmount;
    }
    // For 'Exempt' and 'Tax Incl.', all tax values remain 0.0
    
    final returnItem = InvoiceItem(
      name: _getItemName(_selectedItem),
      quantity: quantity,
      unit: _selectedItem?.unit ?? 'pcs', // Default to 'pcs' if unit is not available
      price: double.parse(_priceController.text),
      taxRate: double.parse(_taxRateController.text),
      discount: double.tryParse(_discountController.text) ?? 0,
      returnReason: _reasonController.text,
      originalInvoiceItemId: _selectedItem?.id,
      cgst: cgst,
      sgst: sgst,
      igst: igst,
      taxType: _selectedTaxType,
    );

    widget.onItemAdded(returnItem);
    Navigator.of(context).pop();
  }
  
  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Add Return Item'),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Item selection dropdown
              InputDecorator(
                decoration: const InputDecoration(
                  labelText: 'Item',
                  border: OutlineInputBorder(),
                  contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<dynamic>(
                    value: _selectedItem,
                    isExpanded: true,
                    hint: const Text('Select an item'),
                    items: _availableItemsList.map<DropdownMenuItem<dynamic>>((dynamic item) {
                      final name = item is Map ? item['name']?.toString() : item?.name?.toString();
                      return DropdownMenuItem<dynamic>(
                        value: item,
                        child: Text(name ?? 'Unnamed Item'),
                      );
                    }).toList(),
                    onChanged: (dynamic value) {
                      if (value == null) return;
                      
                      setState(() {
                        _selectedItem = value;
                        if (!_isManualPrice) {
                          dynamic price = 0.0;
                          dynamic taxRate = 0.0;
                          
                          if (value is Map) {
                            price = value['price'] ?? 0.0;
                            taxRate = value['taxRate'] ?? 0.0;
                          } else if (value != null) {
                            price = value.price ?? 0.0;
                            taxRate = value.taxRate ?? 0.0;
                          }
                          
                          _priceController.text = (price is num ? price : 0.0).toStringAsFixed(2);
                          _taxRateController.text = (taxRate is num ? taxRate : 0.0).toStringAsFixed(2);
                          _updateTotal();
                        }
                      });
                    },
                  ),
                ),
              ),
              const SizedBox(height: 16),
              
              // Quantity field
              TextFormField(
                controller: _quantityController,
                decoration: const InputDecoration(
                  labelText: 'Quantity',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
                validator: (value) {
                  final qty = int.tryParse(value ?? '') ?? 0;
                  if (qty <= 0) return 'Enter a valid quantity';
                  return null;
                },
              ),
              const SizedBox(height: 16),
              
              // Price field
              TextFormField(
                controller: _priceController,
                decoration: InputDecoration(
                  labelText: 'Price',
                  border: const OutlineInputBorder(),
                  suffixIcon: IconButton(
                    icon: Icon(_isManualPrice ? Icons.lock_open : Icons.lock_outline),
                    onPressed: () {
                      setState(() {
                        _isManualPrice = !_isManualPrice;
                        if (!_isManualPrice && _selectedItem != null) {
                          final price = _selectedItem is Map 
                              ? _selectedItem['price'] 
                              : _selectedItem.price;
                          _priceController.text = price.toStringAsFixed(2);
                        }
                      });
                    },
                  ),
                ),
                keyboardType: TextInputType.number,
                readOnly: !_isManualPrice,
                validator: (value) {
                  final price = double.tryParse(value ?? '') ?? -1;
                  if (price < 0) return 'Enter a valid price';
                  return null;
                },
              ),
              const SizedBox(height: 16),
              
              // Discount field
              TextFormField(
                controller: _discountController,
                decoration: const InputDecoration(
                  labelText: 'Discount (%)',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
                onChanged: (_) => setState(() {}),
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
                TextFormField(
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
                    setState(() {});
                  },
                ),
              const SizedBox(height: 16),
              
              // Reason for return
              TextFormField(
                controller: _reasonController,
                decoration: const InputDecoration(
                  labelText: 'Reason for Return',
                  border: OutlineInputBorder(),
                ),
                maxLines: 2,
              ),
              const SizedBox(height: 16),
              
              // Summary
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text('Subtotal: ${_subtotal.toStringAsFixed(2)}'),
                      Text('Tax (${_taxRateController.text}%): ${_taxAmount.toStringAsFixed(2)}'),
                      const Divider(),
                      Text(
                        'Total: ${_totalAmount.toStringAsFixed(2)}',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _isLoading ? null : _submitForm,
          child: _isLoading 
              ? const CircularProgressIndicator()
              : const Text('Add Item'),
        ),
      ],
    );
  }


  String _getItemName(dynamic item) {
    return item is InvoiceItem ? item.name : item.toString();
  }

  void _updatePrice() {
    if (_selectedItem != null && !_isManualPrice) {
      final price = _isFreeItem ? 0.0 : _getItemPrice(_selectedItem);
      _priceController.text = price.toStringAsFixed(2);
      if (mounted) setState(() {});
    }
  }

  double _getItemPrice(dynamic item) {
    if (item is InvoiceItem) return item.price;
    if (item is Map) return (item['price'] ?? 0.0).toDouble();
    return 0.0;
  }

  double get _subtotal {
    final quantity = int.tryParse(_quantityController.text) ?? 0;
    final price = double.tryParse(_priceController.text) ?? 0;
    final discount = double.tryParse(_discountController.text) ?? 0;
    final discountAmount = (price * quantity) * (discount / 100);
    return (price * quantity) - discountAmount;
  }
  
  void _updateTaxRate() {
    if (_selectedItem != null) {
      dynamic taxRate = 0;
      dynamic taxType = 'GST';
      
      if (_selectedItem is Map) {
        taxRate = _selectedItem['taxRate'] ?? 0;
        taxType = _selectedItem['taxType'] ?? 'GST';
      } else {
        taxRate = _selectedItem.taxRate ?? 0;
        taxType = _selectedItem.taxType ?? 'GST';
      }
      
      setState(() {
        _taxRateController.text = taxRate.toStringAsFixed(2);
        _selectedTaxType = taxType;
      });
    } else {
      setState(() {
        _taxRateController.text = '0.00';
        _selectedTaxType = 'GST';
      });
    }
  }
  

  
  List<dynamic> get availableItems {
    return widget.availableItems.where((originalItem) {
      final itemName = originalItem is Map ? originalItem['name'] : originalItem.name;
      final itemQty = originalItem is Map ? (originalItem['quantity'] ?? 0) : originalItem.quantity;
      
      final alreadyReturnedQty = widget.existingItems
          .where((returnedItem) => returnedItem.name == itemName)
          .fold(0, (int sum, item) => sum + (item.quantity as int));
          
      return (itemQty as int) > alreadyReturnedQty;
    }).toList();
  }
  

  
  int get maxReturnableQty {
    if (_selectedItem == null) return 0;
    final originalItem = widget.availableItems.firstWhere(
      (item) => item.name == _selectedItem!.name,
    );
    final alreadyReturnedQty = widget.existingItems
        .where((item) =>
          item.name.toLowerCase().contains(_selectedItem!.name.toLowerCase()) ||
          (item.hsnCode?.toLowerCase().contains(_selectedItem!.hsnCode?.toLowerCase() ?? '') ?? false))
        .map((item) => (item.quantity is int) ? item.quantity as int : (item.quantity as num).toInt())
        .fold<int>(0, (int sum, int quantity) => sum + quantity);
    return originalItem.quantity - alreadyReturnedQty;
  }
  

}
