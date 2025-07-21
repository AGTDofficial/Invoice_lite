import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:phone_numbers_parser/phone_numbers_parser.dart';
import 'package:drift/drift.dart' show Value;

import '../../../../core/database/database.dart' show Customer;
import '../../../../core/utils/form_validators.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/custom_text_field.dart';
import '../../data/customer_dao.dart';
import '../../data/customer_model.dart';
import '../../providers/customer_providers.dart';

class AddEditCustomerScreen extends ConsumerStatefulWidget {
  static const String routeName = '/customers/add-edit';
  
  final String? customerId; // Null for new customer
  
  const AddEditCustomerScreen({
    super.key,
    this.customerId,
  });

  @override
  ConsumerState<AddEditCustomerScreen> createState() => _AddEditCustomerScreenState();
}

class _AddEditCustomerScreenState extends ConsumerState<AddEditCustomerScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _phoneController;
  late final TextEditingController _emailController;
  late final TextEditingController _addressController;
  late final TextEditingController _gstinController;
  bool _isActive = true;
  bool _isLoading = false;
  
  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _phoneController = TextEditingController();
    _emailController = TextEditingController();
    _addressController = TextEditingController();
    _gstinController = TextEditingController();
    
    // If editing, load customer data
    if (widget.customerId != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _loadCustomer();
      });
    }
  }
  
  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _addressController.dispose();
    _gstinController.dispose();
    super.dispose();
  }
  
  Future<void> _loadCustomer() async {
    if (widget.customerId == null) return;
    
    setState(() => _isLoading = true);
    
    try {
      final customerDao = ref.read(customerDaoProvider);
      final customer = await customerDao.getCustomer(int.parse(widget.customerId!));
      
      if (customer != null) {
        _nameController.text = customer.name;
        _phoneController.text = customer.phone ?? '';
        _emailController.text = customer.email ?? '';
        _addressController.text = customer.address ?? '';
        _gstinController.text = customer.taxId ?? '';
        setState(() => _isActive = customer.isActive == 1);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading customer: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }
  
  Future<void> _saveCustomer() async {
    if (!_formKey.currentState!.validate()) return;
    
    setState(() => _isLoading = true);
    
    try {
      final customerDao = ref.read(customerDaoProvider);
      final customer = Customer(
        id: widget.customerId != null ? int.parse(widget.customerId!) : 0, // 0 for new customer
        name: _nameController.text.trim(),
        phone: _phoneController.text.trim().isEmpty ? null : _phoneController.text.trim(),
        email: _emailController.text.trim().isEmpty ? null : _emailController.text.trim(),
        address: _addressController.text.trim().isEmpty ? null : _addressController.text.trim(),
        city: null,
        state: null,
        country: 'India',
        pinCode: null,
        taxId: _gstinController.text.trim().isEmpty ? null : _gstinController.text.trim(),
        type: 'retail',
        balance: 0.0,
        isActive: _isActive ? 1 : 0,
        createdAt: widget.customerId == null ? DateTime.now() : DateTime.now(),
        updatedAt: DateTime.now(),
      );
      
      final companion = ref.read(customerDaoProvider).toCompanion(customer, widget.customerId != null);
      
      if (widget.customerId == null) {
        await customerDao.addCustomer(companion);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Customer added successfully')),
          );
        }
      } else {
        await customerDao.updateCustomer(companion);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Customer updated successfully')),
          );
        }
      }
      
      if (mounted) {
        Navigator.of(context).pop(true); // Return success
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to save customer: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }
  
  Future<void> _deleteCustomer() async {
    if (widget.customerId == null) return;
    
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Customer'),
        content: const Text('Are you sure you want to delete this customer? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('CANCEL'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('DELETE', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    
    if (confirmed != true) return;
    
    setState(() => _isLoading = true);
    
    try {
      final customerDao = ref.read(customerDaoProvider);
      await customerDao.deleteCustomer(int.parse(widget.customerId!));
      
      if (mounted) {
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error deleting customer: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }
  
  String? _validatePhone(String? value) {
    if (value == null || value.isEmpty) return null;
    
    // First check with our basic phone validation
    final basicValidation = FormValidators.phoneNumber(value, errorText: 'Please enter a valid phone number');
    if (basicValidation != null) return basicValidation;
    
    // Then try more specific validation with phone_numbers_parser
    try {
      final phone = PhoneNumber.parse(value);
      if (!phone.isValid()) {
        return 'Please enter a valid phone number';
      }
      return null;
    } catch (e) {
      return 'Please enter a valid phone number';
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.customerId == null ? 'Add Customer' : 'Edit Customer',
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        actions: [
          if (widget.customerId != null) ...[
            IconButton(
              icon: const Icon(Icons.delete_outline, color: Colors.red),
              onPressed: _isLoading ? null : _confirmDelete,
              tooltip: 'Delete Customer',
            ),
            const SizedBox(width: 8),
          ],
          TextButton(
            onPressed: _isLoading ? null : _saveCustomer,
            child: _isLoading 
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('SAVE'),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: _isLoading && widget.customerId != null
          ? const Center(child: CircularProgressIndicator())
          : Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  // Customer Status Toggle
                  Card(
                    margin: const EdgeInsets.only(bottom: 16),
                    child: SwitchListTile(
                      title: const Text('Active'),
                      subtitle: const Text('Inactive customers won\'t appear in dropdowns'),
                      value: _isActive,
                      onChanged: _isLoading
                          ? null
                          : (value) => setState(() => _isActive = value),
                    ),
                  ),
                  
                  // Basic Information
                  const Text(
                    'Basic Information',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 12),
                  
                  // Name
                  CustomTextField(
                    controller: _nameController,
                    label: 'Customer Name *',
                    hint: 'Enter customer name',
                    prefixIcon: Icons.person_outline,
                    keyboardType: TextInputType.name,
                    textCapitalization: TextCapitalization.words,
                    validator: (value) => FormValidators.combine([
                      (v) => FormValidators.required(v, errorText: 'Name is required'),
                      (v) => FormValidators.maxLength(v, 100, errorText: 'Maximum 100 characters'),
                    ])(value),
                  ),
                  const SizedBox(height: 16),
                  
                  // Phone
                  CustomTextField(
                    controller: _phoneController,
                    label: 'Phone Number',
                    hint: 'Enter phone number with country code',
                    prefixIcon: Icons.phone_outlined,
                    keyboardType: TextInputType.phone,
                    validator: (value) => FormValidators.combine([
                      _validatePhone,
                      (v) => FormValidators.maxLength(v, 20, errorText: 'Maximum 20 characters'),
                    ])(value),
                  ),
                  const SizedBox(height: 16),
                  
                  // Email
                  CustomTextField(
                    controller: _emailController,
                    label: 'Email',
                    hint: 'Enter email address',
                    prefixIcon: Icons.email_outlined,
                    keyboardType: TextInputType.emailAddress,
                    validator: (value) => FormValidators.combine([
                      (v) => FormValidators.email(v, errorText: 'Enter a valid email'),
                      (v) => FormValidators.maxLength(v, 100, errorText: 'Maximum 100 characters'),
                    ])(value),
                  ),
                  
                  // Additional Information
                  const SizedBox(height: 24),
                  const Text(
                    'Additional Information',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 12),
                  
                  // Address
                  CustomTextField(
                    controller: _addressController,
                    label: 'Billing Address',
                    hint: 'Enter full address',
                    prefixIcon: Icons.location_on_outlined,
                    maxLines: 3,
                    textCapitalization: TextCapitalization.sentences,
                  ),
                  const SizedBox(height: 16),
                  
                  // GSTIN
                  CustomTextField(
                    controller: _gstinController,
                    label: 'GSTIN',
                    hint: 'Enter GSTIN (if applicable)',
                    prefixIcon: Icons.receipt_long_outlined,
                    textCapitalization: TextCapitalization.characters,
                    maxLength: 15,
                    validator: (value) => FormValidators.combine([
                      // Allow empty
                      (v) => v == null || v.isEmpty ? null : null,
                      // Validate GSTIN format if not empty
                      (v) {
                        if (v == null || v.isEmpty) return null;
                        final gstinRegex = RegExp(r'^[0-9]{2}[A-Z]{5}[0-9]{4}[A-Z]{1}[1-9A-Z]{1}Z[0-9A-Z]{1}$');
                        if (!gstinRegex.hasMatch(v)) {
                          return 'Invalid GSTIN format';
                        }
                        return null;
                      },
                      // Max length check
                      (v) => FormValidators.maxLength(v, 15, errorText: 'Maximum 15 characters'),
                    ])(value),
                  ),
                ],
              ),
            ),
    );
  }
}
