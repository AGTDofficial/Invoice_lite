import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:uuid/uuid.dart';
import '../models/item_model.dart';
import '../models/invoice_item.dart';
import '../models/account.dart';
import '../models/invoice.dart';
import '../enums/invoice_type.dart';

class PurchaseReturnScreen extends StatefulWidget {
  final Invoice? originalInvoice;
  
  const PurchaseReturnScreen({
    super.key,
    this.originalInvoice,
  });

  @override
  State<PurchaseReturnScreen> createState() => _PurchaseReturnScreenState(originalInvoice: originalInvoice);
}

class _PurchaseReturnScreenState extends State<PurchaseReturnScreen> {
  final Invoice? originalInvoice;
  final List<Item> _items = [];
  final List<InvoiceItem> _selectedItems = [];
  
  _PurchaseReturnScreenState({this.originalInvoice});
  final _formKey = GlobalKey<FormState>();
  final _partyController = TextEditingController();
  final _invoiceNoController = TextEditingController();
  final _searchController = TextEditingController();
  final _notesController = TextEditingController();
  DateTime _invoiceDate = DateTime.now();
  Account? _selectedSupplier;
  double _totalAmount = 0.0;
  double _totalDiscount = 0.0;
  double _roundOff = 0.0;

  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadItems();
    _generateInvoiceNumber();
    
    // Pre-fill with original invoice data if available
    if (originalInvoice != null) {
      _partyController.text = originalInvoice!.partyName;
      _invoiceNoController.text = 'RET-${originalInvoice!.invoiceNumber}';
      _selectedItems.addAll(originalInvoice!.items);
      _totalAmount = originalInvoice!.total;
      _totalDiscount = originalInvoice!.discount;
      _roundOff = originalInvoice!.roundOff;
      _invoiceDate = DateTime.now();
      
      // Update totals
      if (mounted) {
        setState(() {});
      }
    }
  }

  Future<void> _loadItems() async {
    final box = await Hive.openBox<Item>('itemsBox');
    setState(() {
      _items.addAll(box.values);
    });
  }

  Future<void> _generateInvoiceNumber() async {
    final box = await Hive.openBox<Invoice>('invoices');
    final prefix = InvoiceType.purchaseReturn.code;
    final existing = box.values.where((i) => i.invoiceNumber.startsWith(prefix)).toList();
    final last = existing.isNotEmpty
        ? int.tryParse(existing.last.invoiceNumber.replaceAll(RegExp(r'\D'), '')) ?? 0
        : 0;
    final newNumber = '$prefix${(last + 1).toString().padLeft(4, '0')}';
    _invoiceNoController.text = newNumber;
  }

  Future<void> _addItem() async {
    final result = await showDialog<InvoiceItem>(
      context: context,
      builder: (context) => _AddItemDialog(
        items: _items,
        onAdd: (item) {
          Navigator.of(context).pop(item);
        },
      ),
    );

    if (result != null) {
      setState(() {
        _selectedItems.add(result);
        _calculateTotals();
      });
    }
  }

  void _calculateTotals() {
    double subtotal = 0.0;
    
    for (var item in _selectedItems) {
      final itemTotal = item.quantity * item.price;
      subtotal += itemTotal;
    }
    
    final discount = _totalDiscount;
    final roundOff = _roundOff;
    
    setState(() {
      _totalAmount = subtotal - discount + roundOff;
    });
  }

  void _removeItem(int index) {
    setState(() {
      _selectedItems.removeAt(index);
      _calculateTotals();
    });
  }

  Future<void> _saveReturn() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedItems.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please add at least one item')),
      );
      return;
    }

    try {
      final invoice = Invoice(
        id: const Uuid().v4(),
        type: InvoiceType.purchaseReturn,
        partyName: _partyController.text.trim(),
        invoiceNumber: '${InvoiceType.purchaseReturn.code}-${_invoiceNoController.text.split('-').last}',
        date: _invoiceDate,
        items: _selectedItems,
        total: _totalAmount,
        notes: _notesController.text,
        discount: _totalDiscount,
        roundOff: _roundOff,
        accountKey: _selectedSupplier?.key,
      );

      final box = await Hive.openBox<Invoice>('invoices');
      await box.add(invoice);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Purchase return saved successfully')),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving purchase return: $e')),
        );
      }
    }
  }

  double get _subtotal => _selectedItems.fold(0, (sum, i) => sum + (i.price * i.quantity));
  double get _discount => _selectedItems.fold(0, (sum, i) => sum + i.discount);
  double get _total => _subtotal - _discount;

  @override
  void dispose() {
    _partyController.dispose();
    _invoiceNoController.dispose();
    _searchController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Purchase Return')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: _invoiceNoController,
              readOnly: true,
              decoration: const InputDecoration(labelText: 'Invoice No'),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _partyController,
              decoration: const InputDecoration(labelText: 'Supplier Name'),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                const Text('Date: '),
                TextButton(
                  onPressed: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: _invoiceDate,
                      firstDate: DateTime(2000),
                      lastDate: DateTime(2100),
                    );
                    if (picked != null) {
                      setState(() {
                        _invoiceDate = picked;
                      });
                    }
                  },
                  child: Text("${_invoiceDate.day}/${_invoiceDate.month}/${_invoiceDate.year}"),
                ),
              ],
            ),
            const SizedBox(height: 10),
            const Divider(),
            const Text("Items"),
            const SizedBox(height: 10),
            _selectedItems.isEmpty
                ? const Text("No items added.")
                : ListView.builder(
              itemCount: _selectedItems.length,
              shrinkWrap: true,
              itemBuilder: (_, i) {
                final item = _selectedItems[i];
                return ListTile(
                  title: Text(item.name),
                  subtitle: Text("${item.quantity} ${item.unit} x ₹${item.price}"),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete),
                    onPressed: () => _removeItem(i),
                  ),
                );
              },
            ),
            const SizedBox(height: 10),
            ElevatedButton.icon(
              onPressed: _addItem,
              icon: const Icon(Icons.add),
              label: const Text("Add Item"),
            ),
            const Divider(),
            const SizedBox(height: 10),
            _buildSummaryRow("Subtotal", _subtotal),
            _buildSummaryRow("Discount", -_discount),
            _buildSummaryRow("Total", _total, bold: true),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _saveReturn,
              child: const Text("Save Purchase Return"),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryRow(String label, double value, {bool bold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: bold ? const TextStyle(fontWeight: FontWeight.bold) : null),
          Text("₹${value.toStringAsFixed(2)}", style: bold ? const TextStyle(fontWeight: FontWeight.bold) : null),
        ],
      ),
    );
  }


}

class _AddItemDialog extends StatefulWidget {
  final List<Item> items;
  final Function(InvoiceItem) onAdd;

  const _AddItemDialog({
    required this.items,
    required this.onAdd,
  });

  @override
  _AddItemDialogState createState() => _AddItemDialogState();
}

class _AddItemDialogState extends State<_AddItemDialog> {
  final _formKey = GlobalKey<FormState>();
  Item? _selectedItem;
  int _quantity = 1;
  double _price = 0.0;
  double _discount = 0.0;
  final _discountController = TextEditingController();
  final _quantityController = TextEditingController(text: '1');
  final _priceController = TextEditingController();


  @override
  void dispose() {
    _quantityController.dispose();
    _priceController.dispose();
    _discountController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {

    return AlertDialog(
      title: const Text('Add Item'),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<Item>(
                value: _selectedItem,
                decoration: const InputDecoration(
                  labelText: 'Item',
                  border: OutlineInputBorder(),
                ),
                items: widget.items.map((item) {
                  return DropdownMenuItem(
                    value: item,
                    child: Text(item.name),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedItem = value;
                    if (value != null) {
                      _price = value.purchaseRate ?? 0.0;
                      _priceController.text = _price.toStringAsFixed(2);
                    }
                  });
                },
                validator: (value) =>
                    value == null ? 'Please select an item' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _quantityController,
                decoration: const InputDecoration(
                  labelText: 'Quantity',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
                onChanged: (value) {
                  _quantity = int.tryParse(value) ?? 1;
                  _quantityController.text = _quantity.toString();
                },
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter quantity';
                  }
                  final qty = int.tryParse(value);
                  if (qty == null || qty <= 0) {
                    return 'Please enter a valid quantity';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _priceController,
                decoration: const InputDecoration(
                  labelText: 'Price',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.numberWithOptions(decimal: true),
                onChanged: (value) {
                  _price = double.tryParse(value) ?? 0.0;
                  _priceController.text = _price.toStringAsFixed(2);
                },
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter price';
                  }
                  final price = double.tryParse(value);
                  if (price == null || price <= 0) {
                    return 'Please enter a valid price';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _discountController,
                decoration: const InputDecoration(
                  labelText: 'Discount (%)',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.numberWithOptions(decimal: true),
                onChanged: (value) {
                  _discount = double.tryParse(value) ?? 0.0;
                },
              ),

            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('CANCEL'),
        ),
        ElevatedButton(
          onPressed: () {
            if (_formKey.currentState!.validate() && _selectedItem != null) {

              final item = InvoiceItem(
                name: _selectedItem!.name,
                quantity: _quantity.toDouble(),
                price: _price,
                discount: _discount,
                unit: _selectedItem!.unit,
                isFreeItem: false,
              );
              widget.onAdd(item);
            } else if (_selectedItem == null) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Please select an item')),
              );
            }
          },
          child: const Text('ADD'),
        ),
      ],
    );
  }
}
