import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:invoice_lite/core/widgets/searchable_dropdown.dart';
import 'package:invoice_lite/features/customers/data/customer_dao.dart';
import 'package:invoice_lite/features/customers/data/customer_model.dart';
import 'package:invoice_lite/features/items/data/item_model.dart';
import 'package:invoice_lite/features/invoices/presentation/screens/select_item_screen.dart';
import 'package:invoice_lite/features/invoices/data/invoice_model.dart';

class AddEditInvoiceScreen extends ConsumerStatefulWidget {
  static const String routeName = '/invoices/add-edit';
  
  const AddEditInvoiceScreen({super.key});

  @override
  ConsumerState<AddEditInvoiceScreen> createState() => _AddEditInvoiceScreenState();
}

class _AddEditInvoiceScreenState extends ConsumerState<AddEditInvoiceScreen> {
  Customer? _selectedCustomer;
  List<Item> _selectedItems = [];
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _notesController = TextEditingController();
  DateTime _invoiceDate = DateTime.now();
  DateTime _dueDate = DateTime.now().add(const Duration(days: 30));
  double _taxRate = 0.0;
  double _discountAmount = 0.0;
  
  @override
  void dispose() {
    _notesController.dispose();
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
              // Invoice Date
              InkWell(
                onTap: () => _selectDate(context, isDueDate: false),
                child: InputDecorator(
                  decoration: const InputDecoration(
                    labelText: 'Invoice Date',
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
              const SizedBox(height: 16),
              
              // Due Date
              InkWell(
                onTap: () => _selectDate(context, isDueDate: true),
                child: InputDecorator(
                  decoration: const InputDecoration(
                    labelText: 'Due Date',
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
              const SizedBox(height: 16),
              
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
