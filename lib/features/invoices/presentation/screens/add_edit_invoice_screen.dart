import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:invoice_lite/core/routes/app_router.dart';
import 'package:invoice_lite/core/widgets/searchable_dropdown.dart';
import 'package:invoice_lite/features/customers/data/customer_dao.dart';
import 'package:invoice_lite/features/customers/data/customer_model.dart';
import 'package:invoice_lite/features/items/data/item_model.dart';
import 'package:invoice_lite/features/invoices/data/invoice_dao.dart';
import 'package:invoice_lite/features/invoices/data/invoice_model.dart';
import 'package:invoice_lite/features/invoices/presentation/screens/select_item_screen.dart';

// Import the SelectedItem class from select_item_screen.dart
export 'select_item_screen.dart' show SelectedItem;

class AddEditInvoiceScreen extends ConsumerStatefulWidget {
  static const String routeName = '/invoices/add-edit';
  
  const AddEditInvoiceScreen({super.key});

  @override
  ConsumerState<AddEditInvoiceScreen> createState() => _AddEditInvoiceScreenState();
}

class _AddEditInvoiceScreenState extends ConsumerState<AddEditInvoiceScreen> {
  Customer? _selectedCustomer;
  List<SelectedItem> _selectedItems = [];
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _notesController = TextEditingController();
  final TextEditingController _discountController = TextEditingController(text: '0');
  final TextEditingController _taxRateController = TextEditingController(text: '0');
  DateTime _invoiceDate = DateTime.now();
  DateTime _dueDate = DateTime.now().add(const Duration(days: 30));
  double _taxRate = 0.0;
  double _taxAmount = 0.0;
  double _discountAmount = 0.0;
  double _subtotal = 0.0;
  double _total = 0.0;
  
  @override
  void dispose() {
    _notesController.dispose();
    _discountController.dispose();
    _taxRateController.dispose();
    super.dispose();
  }
  
  Future<void> _selectDate(BuildContext context, {bool isDueDate = false}) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: isDueDate ? _dueDate : _invoiceDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
    );
    
    if (picked != null) {
      setState(() {
        if (isDueDate) {
          _dueDate = picked;
        } else {
          _invoiceDate = picked;
          // If due date is before new invoice date, update it
          if (_dueDate.isBefore(_invoiceDate)) {
            _dueDate = _invoiceDate.add(const Duration(days: 30));
          }
        }
      });
    }
  }

  // Calculate invoice totals
  void _calculateTotals() {
    double subtotal = 0;
    
    // Calculate subtotal from selected items
    for (var selectedItem in _selectedItems) {
      subtotal += selectedItem.total;
    }
    
    // Calculate tax and total
    final tax = subtotal * (_taxRate / 100);
    final total = subtotal + tax - _discountAmount;
    
    setState(() {
      _subtotal = subtotal;
      _taxAmount = tax;
      _total = total > 0 ? total : 0;
      
      // Update controller values if they don't match
      if (_taxRateController.text != _taxRate.toStringAsFixed(2)) {
        _taxRateController.text = _taxRate.toStringAsFixed(2);
      }
      if (_discountController.text != _discountAmount.toStringAsFixed(2)) {
        _discountController.text = _discountAmount.toStringAsFixed(2);
      }
    });
  }
  
  // Helper method to build a summary row
  Widget _buildSummaryRow(
    String label, 
    double amount, {
    bool isTotal = false,
    bool isDiscount = false,
    TextStyle? style,
  }) {
    final theme = Theme.of(context);
    final amountStyle = isDiscount 
        ? theme.textTheme.bodyLarge?.copyWith(
            color: theme.colorScheme.error,
            fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
          )
        : style ?? theme.textTheme.bodyLarge?.copyWith(
            fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
          );
    
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: isTotal 
                ? theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  )
                : theme.textTheme.bodyLarge,
          ),
          Text(
            '₹${amount.toStringAsFixed(2)}',
            style: amountStyle,
          ),
        ],
      ),
    );
  }
  
  // Save invoice to database
  Future<void> _saveInvoice() async {
    if (_formKey.currentState?.validate() ?? false) {
      if (_selectedCustomer == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please select a customer')),
        );
        return;
      }
      
      if (_selectedItems.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please add at least one item')),
        );
        return;
      }
      
      try {
        final invoiceDao = ref.read(invoiceDaoProvider);
        
        // Get the next invoice number
        final invoiceNumber = await invoiceDao.getNextInvoiceNumber();
        
        // Create the invoice
        final invoice = InvoicesCompanion.insert(
          invoiceNumber: invoiceNumber,
          customerId: Value(_selectedCustomer!.id),
          invoiceDate: _invoiceDate,
          dueDate: Value(_dueDate),
          subtotal: _subtotal,
          taxAmount: _taxAmount,
          discountAmount: _discountAmount,
          total: _total,
          status: 'draft',
          paymentStatus: 'unpaid',
          notes: _notesController.text.isNotEmpty ? Value(_notesController.text) : const Value.absent(),
        );
        
        // Prepare invoice items
        final items = _selectedItems.map((selectedItem) {
          return InvoiceItemsCompanion.insert(
            itemId: selectedItem.item.id,
            description: Value(selectedItem.item.description ?? ''),
            quantity: selectedItem.quantity.toDouble(),
            unitPrice: selectedItem.item.saleRate,
            amount: selectedItem.item.saleRate * selectedItem.quantity,
            taxPercent: 0,
            taxAmount: 0,
            discountPercent: 0,
            discountAmount: 0,
            total: selectedItem.total,
          );
        }).toList();
        
        // Save the invoice with items
        await invoiceDao.createInvoiceWithItems(
          invoice: invoice,
          items: items,
        );
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Invoice created successfully')),
          );
          // Navigate back to invoices list with success
          Navigator.of(context).pop(true);
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error saving invoice: $e')),
          );
        }
      }
    }
  }
  
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Create Invoice'),
        actions: [
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: _saveInvoice,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Customer Selection
              Consumer(
                builder: (context, ref, _) {
                  return FutureBuilder<List<Customer>>(
                    future: ref.read(customerDaoProvider).getAllCustomers(),
                    builder: (context, snapshot) {
                      final customers = snapshot.data ?? [];
                      return SearchableDropdown<Customer>(
                        label: 'Customer *',
                        hint: 'Select a customer',
                        items: customers,
                        itemAsString: (customer) => '${customer.name} (${customer.phone})',
                        onChanged: (customer) {
                          setState(() {
                            _selectedCustomer = customer;
                          });
                        },
                        selectedItem: _selectedCustomer,
                        validator: (value) => value == null ? 'Please select a customer' : null,
                      );
                    },
                  );
                },
              ),
              const SizedBox(height: 16),
              // Invoice Details Row
              Row(
                children: [
                  // Invoice Date
                  Expanded(
                    child: InkWell(
                      onTap: () => _selectDate(context, isDueDate: false),
                      child: InputDecorator(
                        decoration: const InputDecoration(
                          labelText: 'Invoice Date *',
                          border: OutlineInputBorder(),
                          contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              '${_invoiceDate.day}/${_invoiceDate.month}/${_invoiceDate.year}',
                              style: const TextStyle(fontSize: 16),
                            ),
                            const Icon(Icons.calendar_today, size: 20),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  
                  // Due Date
                  Expanded(
                    child: InkWell(
                      onTap: () => _selectDate(context, isDueDate: true),
                      child: InputDecorator(
                        decoration: const InputDecoration(
                          labelText: 'Due Date *',
                          border: OutlineInputBorder(),
                          contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              '${_dueDate.day}/${_dueDate.month}/${_dueDate.year}',
                              style: const TextStyle(fontSize: 16),
                            ),
                            const Icon(Icons.calendar_today, size: 20),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              // Items Section
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Items',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  ElevatedButton.icon(
                    onPressed: () async {
                      final selectedItems = await AppRouter.navigateToSelectItems(
                        context,
                        selectedItems: _selectedItems,
                      ) as List<SelectedItem>?;
                      
                      if (selectedItems != null) {
                        setState(() {
                          _selectedItems = List<SelectedItem>.from(selectedItems);
                          _calculateTotals();
                        });
                      }
                    },
                    icon: const Icon(Icons.add, size: 18),
                    label: const Text('Add Items'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              
              // Items List
              if (_selectedItems.isEmpty)
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    border: Border.all(color: theme.dividerColor),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    children: [
                      Icon(Icons.receipt_long_outlined, 
                        size: 48, 
                        color: theme.hintColor.withOpacity(0.5),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'No items added yet',
                        style: theme.textTheme.bodyLarge?.copyWith(
                          color: theme.hintColor,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Click "Add Items" to add items to this invoice',
                        style: theme.textTheme.bodySmall,
                      ),
                    ],
                  ),
                )
              else
                Card(
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                    side: BorderSide(color: theme.dividerColor),
                  ),
                  child: Column(
                    children: [
                      // Table Header
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.surfaceVariant.withOpacity(0.5),
                          borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
                        ),
                        child: const Row(
                          children: [
                            Expanded(
                              flex: 3,
                              child: Text('Item', style: TextStyle(fontWeight: FontWeight.bold)),
                            ),
                            Expanded(
                              child: Text('Qty', style: TextStyle(fontWeight: FontWeight.bold), textAlign: TextAlign.center),
                            ),
                            Expanded(
                              child: Text('Rate', style: TextStyle(fontWeight: FontWeight.bold), textAlign: TextAlign.right),
                            ),
                            Expanded(
                              child: Text('Total', style: TextStyle(fontWeight: FontWeight.bold), textAlign: TextAlign.right),
                            ),
                            SizedBox(width: 8),
                          ],
                        ),
                      ),
                      
                      // Items List
                      ListView.separated(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: _selectedItems.length,
                        separatorBuilder: (context, index) => Divider(height: 1, color: theme.dividerColor),
                        itemBuilder: (context, index) {
                          final selectedItem = _selectedItems[index];
                          final item = selectedItem.item;
                          
                          return ListTile(
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            title: Text(
                              item.name,
                              style: const TextStyle(fontWeight: FontWeight.w500),
                            ),
                            subtitle: item.description?.isNotEmpty == true 
                                ? Text(item.description!) 
                                : null,
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                // Quantity
                                SizedBox(
                                  width: 60,
                                  child: TextField(
                                    controller: TextEditingController(text: selectedItem.quantity.toString()),
                                    keyboardType: TextInputType.number,
                                    textAlign: TextAlign.center,
                                    decoration: const InputDecoration(
                                      contentPadding: EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                                      border: OutlineInputBorder(),
                                      isDense: true,
                                    ),
                                    onChanged: (value) {
                                      final quantity = int.tryParse(value) ?? 0;
                                      if (quantity > 0) {
                                        setState(() {
                                          _selectedItems[index] = selectedItem.copyWith(quantity: quantity);
                                          _calculateTotals();
                                        });
                                      }
                                    },
                                  ),
                                ),
                                const SizedBox(width: 16),
                                // Rate
                                SizedBox(
                                  width: 80,
                                  child: Text(
                                    '₹${item.saleRate.toStringAsFixed(2)}',
                                    textAlign: TextAlign.right,
                                  ),
                                ),
                                const SizedBox(width: 16),
                                // Total
                                SizedBox(
                                  width: 80,
                                  child: Text(
                                    '₹${(item.saleRate * selectedItem.quantity).toStringAsFixed(2)}',
                                    textAlign: TextAlign.right,
                                    style: const TextStyle(fontWeight: FontWeight.bold),
                                  ),
                                ),
                                // Delete button
                                IconButton(
                                  icon: const Icon(Icons.delete_outline, size: 20),
                                  onPressed: () {
                                    setState(() {
                                      _selectedItems.removeAt(index);
                                      _calculateTotals();
                                    });
                                  },
                                  padding: EdgeInsets.zero,
                                  constraints: const BoxConstraints(),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              
              // Tax and Discount
              const SizedBox(height: 24),
              Row(
                children: [
                  // Tax Rate
                  Expanded(
                    child: TextFormField(
                      controller: _taxRateController,
                      decoration: const InputDecoration(
                        labelText: 'Tax Rate %',
                        border: OutlineInputBorder(),
                        prefixText: '   %   ',
                      ),
                      keyboardType: TextInputType.number,
                      onChanged: (value) {
                        setState(() {
                          _taxRate = double.tryParse(value) ?? 0.0;
                          _calculateTotals();
                        });
                      },
                    ),
                  ),
                  const SizedBox(width: 16),
                  
                  // Discount
                  Expanded(
                    child: TextFormField(
                      controller: _discountController,
                      decoration: const InputDecoration(
                        labelText: 'Discount',
                        border: OutlineInputBorder(),
                        prefixText: '   ₹   ',
                      ),
                      keyboardType: TextInputType.number,
                      onChanged: (value) {
                        setState(() {
                          _discountAmount = double.tryParse(value) ?? 0.0;
                          _calculateTotals();
                        });
                      },
                    ),
                  ),
                ],
              ),
              
              // Invoice Summary
              const SizedBox(height: 24),
              Card(
                elevation: 2,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      _buildSummaryRow('Subtotal', _subtotal),
                      const Divider(),
                      _buildSummaryRow('Tax', _taxAmount),
                      if (_discountAmount > 0) ...[
                        const Divider(),
                        _buildSummaryRow('Discount', -_discountAmount, isDiscount: true),
                      ],
                      const Divider(),
                      _buildSummaryRow(
                        'Total',
                        _total,
                        isTotal: true,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              
              // Notes
              const SizedBox(height: 16),
              TextFormField(
                controller: _notesController,
                decoration: const InputDecoration(
                  labelText: 'Notes',
                  border: OutlineInputBorder(),
                  alignLabelWithHint: true,
                ),
                maxLines: 3,
                textInputAction: TextInputAction.done,
              ),
              
              // Customer Selection
              // Load customers from the database
              FutureBuilder<List<Customer>>(
                future: ref.read(customerDaoProvider).getAllCustomers(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const CircularProgressIndicator();
                  }
                  
                  final customers = snapshot.data ?? [];
                  
                  return SearchableDropdown<Customer>(
                    hint: 'Select Customer',
                    label: 'Customer',
                    isRequired: true,
                    value: _selectedCustomer,
                    items: customers.map((customer) => DropdownMenuItem<Customer>(
                      value: customer,
                      child: Text('${customer.name} (${customer.phone})'),
                    )).toList(),
                    onChanged: (customer) {
                      setState(() {
                        _selectedCustomer = customer;
                      });
                    },
                    prefixIcon: const Icon(Icons.person_outline),
                  );
              ),
              const SizedBox(height: 20),
              
              // Invoice Items Section
              const Text(
                'Items',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Divider(),
              
              // Add Item Button
              ElevatedButton.icon(
                onPressed: _addItem,
                icon: const Icon(Icons.add),
                label: const Text('Add Item'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
              const SizedBox(height: 16),
              
              // Notes Field
              TextFormField(
                controller: _notesController,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'Notes (Optional)',
                  border: OutlineInputBorder(),
                  alignLabelWithHint: true,
                ),
              ),
              const SizedBox(height: 16),
              
              // Selected Items List
              ..._buildSelectedItems(),
              
              // Invoice Summary
              _buildInvoiceSummary(),
            ],
          ),
        ),
      ),
    );
  }
  
  List<Widget> _buildSelectedItems() {
    return _selectedItems.map((item) {
      return Card(
        margin: const EdgeInsets.only(bottom: 8),
        child: ListTile(
          title: Text(item.name),
          subtitle: Text('Qty: 1 × ${item.price}'),
          trailing: IconButton(
            icon: const Icon(Icons.delete_outline, color: Colors.red),
            onPressed: () => _removeItem(item),
          ),
        ),
      );
    }).toList();
  }
  
  Widget _buildInvoiceSummary() {
    // Calculate subtotal
    final subtotal = _selectedItems.fold<double>(
      0, 
      (sum, item) => sum + (item.saleRate * item.quantity),
    );
    
    // Calculate tax and total
    final taxAmount = subtotal * (_taxRate / 100);
    final total = subtotal + taxAmount - _discountAmount;
    
    return Card(
      margin: const EdgeInsets.only(top: 16),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Subtotal
            _buildSummaryRow('Subtotal', _formatCurrency(subtotal)),
            
            // Tax Row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Tax (${_taxRate.toStringAsFixed(1)}%)',
                  style: const TextStyle(fontSize: 14),
                ),
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.remove, size: 18),
                      onPressed: _taxRate > 0 ? () => _updateTaxRate(-0.5) : null,
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                    SizedBox(
                      width: 40,
                      child: Text(
                        '${_taxRate.toStringAsFixed(1)}%',
                        textAlign: TextAlign.center,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.add, size: 18),
                      onPressed: _taxRate < 30 ? () => _updateTaxRate(0.5) : null,
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                  ],
                ),
              ],
            ),
            
            // Discount Row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Discount',
                  style: TextStyle(fontSize: 14),
                ),
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.remove, size: 18),
                      onPressed: _discountAmount > 0 ? () => _updateDiscount(-1) : null,
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                    SizedBox(
                      width: 60,
                      child: Text(
                        _formatCurrency(_discountAmount),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.add, size: 18),
                      onPressed: () => _updateDiscount(1),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                  ],
                ),
              ],
            ),
            
            // Divider
            const Divider(thickness: 1.5),
            
            // Total
            _buildSummaryRow(
              'Total',
              _formatCurrency(total),
              isTotal: true,
            ),
          ],
        ),
      ),
    );
  }
  
  Future<void> _addItem() async {
    final result = await Navigator.of(context).pushNamed(
      SelectItemScreen.routeName,
      arguments: {
        'selectedItems': _selectedItems,
      },
    ) as List<Item>?;
    
    if (result != null) {
      setState(() {
        _selectedItems = result;
      });
    }
  }
  
  void _removeItem(Item item) {
    setState(() {
      _selectedItems.remove(item);
    });
  }
  
  // Helper method to format currency
  String _formatCurrency(double amount) {
    return '\$${amount.toStringAsFixed(2)}';
  }
  
  // Helper widget for summary rows
  Widget _buildSummaryRow(String label, String value, {bool isTotal = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: isTotal ? 16 : 14,
              fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: isTotal ? 18 : 14,
              fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
              color: isTotal ? Theme.of(context).primaryColor : null,
            ),
          ),
        ],
      ),
    );
  }
  
  void _updateTaxRate(double change) {
    setState(() {
      _taxRate = (_taxRate + change).clamp(0.0, 30.0);
    });
  }
  
  void _updateDiscount(double change) {
    final subtotal = _selectedItems.fold<double>(
      0, 
      (sum, item) => sum + (item.saleRate * item.quantity),
    );
    
    final newDiscount = (_discountAmount + change).clamp(0.0, subtotal);
    
    setState(() {
      _discountAmount = newDiscount;
    });
  }
  
  Future<void> _saveInvoice() async {
    if (_formKey.currentState?.validate() ?? false) {
      if (_selectedCustomer == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please select a customer')),
        );
        return;
      }
      
      if (_selectedItems.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please add at least one item')),
        );
        return;
      }
      
      try {
        final invoiceDao = ref.read(invoiceDaoProvider);
        
        // Calculate amounts
        final subtotal = _selectedItems.fold<double>(
          0,
          (sum, item) => sum + (item.saleRate * item.quantity),
        );
        
        final taxAmount = subtotal * (_taxRate / 100);
        final total = subtotal + taxAmount - _discountAmount;
        
        // Create invoice
        final invoice = InvoicesCompanion.insert(
          customerId: _selectedCustomer!.id,
          invoiceNumber: 'INV-${DateTime.now().millisecondsSinceEpoch}',
          invoiceDate: _invoiceDate,
          dueDate: _dueDate,
          subtotal: subtotal,
          taxAmount: taxAmount,
          discountAmount: _discountAmount,
          total: total,
          notes: _notesController.text.isNotEmpty ? _notesController.text : null,
          status: 'draft',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );
        
        // Save invoice to database
        final invoiceId = await invoiceDao.insertInvoice(invoice);
        
        // Create and save invoice items
        for (final item in _selectedItems) {
          await invoiceDao.insertInvoiceItem(
            InvoiceItemsCompanion.insert(
              invoiceId: invoiceId,
              itemId: item.id,
        );
        
        // Show success message
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Invoice created successfully')),
          );
          
          // Navigate back to invoices list with success
          Navigator.of(context).pop(true);
          Navigator.of(context).pop(true); // Return success
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error saving invoice: $e')),
          );
        }
      }
    }
  }
}
