import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:email_validator/email_validator.dart';

import '../models/account.dart';
import '../providers/account_provider.dart';


class AccountFormScreen extends StatefulWidget {
  final Account? account;
  final bool isCustomer;
  final bool isSupplier;

  const AccountFormScreen({
    Key? key,
    this.account,
    this.isCustomer = false,
    this.isSupplier = false,
  }) : super(key: key);

  @override
  _AccountFormScreenState createState() => _AccountFormScreenState();
}

class _AccountFormScreenState extends State<AccountFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();
  final _emailController = TextEditingController();
  final _openingBalanceController = TextEditingController(text: '0.00');

  String? _selectedGroup;
  bool _isCredit = false;
  bool _isLoading = false;

  final List<String> _accountGroups = [
    'Sundry Debtor',
    'Sundry Creditor',
    'Bank',
    'Cash',
    'Loans',
    'Fixed Assets',
    'Current Assets',
    'Current Liabilities',
    'Direct Expenses',
    'Indirect Expenses',
    'Direct Income',
    'Indirect Income',
  ];

  @override
  void initState() {
    super.initState();
    _loadAccountData();
  }

  void _loadAccountData() {
    if (widget.account != null) {
      final account = widget.account!;
      _nameController.text = account.name;
      _phoneController.text = account.phone;
      _addressController.text = account.address ?? '';
      _emailController.text = account.email ?? '';
      _openingBalanceController.text = account.openingBalance.toStringAsFixed(2);
      _selectedGroup = account.group;
      _isCredit = account.isCredit;
    } else if (widget.isCustomer) {
      _selectedGroup = 'Sundry Debtor';
    } else if (widget.isSupplier) {
      _selectedGroup = 'Sundry Creditor';
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _emailController.dispose();
    _openingBalanceController.dispose();
    super.dispose();
  }

  Future<void> _saveForm() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // For new accounts, create a new Account instance
      if (widget.account == null) {
        final newAccount = Account(
          name: _nameController.text.trim(),
          phone: _phoneController.text.trim(),
          address: _addressController.text.trim().isEmpty ? null : _addressController.text.trim(),
          email: _emailController.text.trim().isEmpty ? null : _emailController.text.trim(),
          openingBalance: double.tryParse(_openingBalanceController.text) ?? 0.0,
          isCredit: _isCredit,
          group: _selectedGroup ?? 'Sundry Debtor',
          isCustomer: widget.isCustomer || _selectedGroup == 'Sundry Debtor',
          isSupplier: widget.isSupplier || _selectedGroup == 'Sundry Creditor',
        );
        
        final accountProvider = Provider.of<AccountProvider>(context, listen: false);
        await accountProvider.addAccount(newAccount);
      } else {
        // For existing accounts, update the existing account directly
        final existingAccount = widget.account!;
        existingAccount.name = _nameController.text.trim();
        existingAccount.phone = _phoneController.text.trim();
        existingAccount.address = _addressController.text.trim().isEmpty ? null : _addressController.text.trim();
        existingAccount.email = _emailController.text.trim().isEmpty ? null : _emailController.text.trim();
        existingAccount.openingBalance = double.tryParse(_openingBalanceController.text) ?? 0.0;
        existingAccount.isCredit = _isCredit;
        existingAccount.group = _selectedGroup ?? 'Sundry Debtor';
        existingAccount.isCustomer = widget.isCustomer || _selectedGroup == 'Sundry Debtor';
        existingAccount.isSupplier = widget.isSupplier || _selectedGroup == 'Sundry Creditor';
        
        final accountProvider = Provider.of<AccountProvider>(context, listen: false);
        await accountProvider.updateAccount(existingAccount);
      }
      
      if (mounted) {
        Navigator.of(context).pop(true);
      }
      return;

      // Account saving is now handled in the if-else block above
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving account: ${e.toString()}')),
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

  bool _validatePhoneNumber(String phone) {
    if (phone.isEmpty) return true;
    
    // Simple phone number validation (10 digits, optional + at start)
    final phoneRegex = RegExp(r'^\+?[0-9]{10,15}$');
    return phoneRegex.hasMatch(phone);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.account == null ? 'Add Account' : 'Edit Account'),
        actions: [
          if (widget.account != null)
            IconButton(
              icon: const Icon(Icons.delete),
              onPressed: _isLoading ? null : () => _deleteAccount(),
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.all(16.0),
                children: [
                  // Name Field
                  TextFormField(
                    controller: _nameController,
                    decoration: const InputDecoration(
                      labelText: 'Name *',
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Please enter a name';
                      }
                      return null;
                    },
                    inputFormatters: [
                      FilteringTextInputFormatter.deny(RegExp(r'[\[\]{};:\\|<>/?]')),
                    ],
                  ),
                  const SizedBox(height: 16),
                  
                  // Group Dropdown
                  DropdownButtonFormField<String>(
                    value: _selectedGroup,
                    decoration: const InputDecoration(
                      labelText: 'Group *',
                      border: OutlineInputBorder(),
                    ),
                    items: _accountGroups.map((group) {
                      return DropdownMenuItem(
                        value: group,
                        child: Text(group),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() {
                        _selectedGroup = value;
                      });
                    },
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please select a group';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  
                  // Address
                  TextFormField(
                    controller: _addressController,
                    decoration: const InputDecoration(
                      labelText: 'Address',
                      border: OutlineInputBorder(),
                      alignLabelWithHint: true,
                    ),
                    maxLines: 3,
                  ),
                  const SizedBox(height: 16),
                  
                  // Phone
                  TextFormField(
                    controller: _phoneController,
                    decoration: const InputDecoration(
                      labelText: 'Phone',
                      border: OutlineInputBorder(),
                      hintText: '+919876543210',
                    ),
                    keyboardType: TextInputType.phone,
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                    ],
                    validator: (value) {
                      if (value != null && value.isNotEmpty) {
                        if (!_validatePhoneNumber(value)) {
                          return 'Enter a valid phone number (10-15 digits, + optional)';
                        }
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  
                  // Email
                  TextFormField(
                    controller: _emailController,
                    decoration: const InputDecoration(
                      labelText: 'Email',
                      border: OutlineInputBorder(),
                      hintText: 'example@domain.com',
                    ),
                    keyboardType: TextInputType.emailAddress,
                    validator: (value) {
                      if (value != null && value.isNotEmpty) {
                        if (!EmailValidator.validate(value)) {
                          return 'Enter a valid email';
                        }
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  
                  // Opening Balance
                  TextFormField(
                    controller: _openingBalanceController,
                    decoration: InputDecoration(
                      labelText: 'Opening Balance',
                      border: const OutlineInputBorder(),
                      prefixIcon: const Icon(Icons.account_balance_wallet),
                      suffix: DropdownButtonHideUnderline(
                        child: DropdownButton<bool>(
                          value: _isCredit,
                          items: const [
                            DropdownMenuItem(
                              value: false,
                              child: Text('Debit'),
                            ),
                            DropdownMenuItem(
                              value: true,
                              child: Text('Credit'),
                            ),
                          ],
                          onChanged: (value) {
                            if (value != null) {
                              setState(() {
                                _isCredit = value;
                              });
                            }
                          },
                        ),
                      ),
                    ),
                    keyboardType: TextInputType.numberWithOptions(decimal: true),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter an opening balance';
                      }
                      final amount = double.tryParse(value);
                      if (amount == null || amount < 0) {
                        return 'Please enter a valid positive amount';
                      }
                      return null;
                    },
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
                    ],
                  ),
                  const SizedBox(height: 24),
                  
                  // Save Button
                  ElevatedButton(
                    onPressed: _isLoading ? null : _saveForm,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: _isLoading
                        ? const CircularProgressIndicator()
                        : const Text('Save Account', style: TextStyle(fontSize: 16)),
                  ),
                ],
              ),
            ),
    );
  }


  Future<void> _deleteAccount() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Are you sure?'),
        content: const Text('Do you want to delete this account? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      setState(() {
        _isLoading = true;
      });

      try {
        final accountProvider = Provider.of<AccountProvider>(context, listen: false);
        await accountProvider.deleteAccount(widget.account!);
        
        if (mounted) {
          Navigator.of(context).pop(true);
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error deleting account: ${e.toString()}')),
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
  }
}
