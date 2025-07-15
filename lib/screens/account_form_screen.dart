import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:email_validator/email_validator.dart';

import '../models/account.dart';
import '../providers/account_provider.dart';
import '../constants/indian_states.dart';

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
  final _countryController = TextEditingController();
  final _stateController = TextEditingController();
  String _selectedState = ''; // Initialize with empty string
  final _gstinUinController = TextEditingController();
  final _emailController = TextEditingController();
  final _openingBalanceController = TextEditingController(text: '0.00');

  String? _selectedGroup;
  String? _selectedDealerType;
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

  final List<String> _dealerTypes = [
    'Registered',
    'Unregistered',
    'Composition',
    'Govt. Body',
    'UIN Holder',
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
      _countryController.text = account.country ?? 'India';
      _stateController.text = account.state ?? '';
      _selectedState = account.state ?? ''; // Ensure state is not null
      _gstinUinController.text = account.gstinUin ?? '';
      _emailController.text = account.email ?? '';
      _openingBalanceController.text = account.openingBalance.toStringAsFixed(2);
      _selectedGroup = account.group;
      _selectedDealerType = account.dealerType;
      _isCredit = account.isCredit;
    } else if (widget.isCustomer) {
      _selectedGroup = 'Sundry Debtor';
      _countryController.text = 'India';
    } else if (widget.isSupplier) {
      _selectedGroup = 'Sundry Creditor';
      _countryController.text = 'India';
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _countryController.dispose();
    _stateController.dispose();
    _gstinUinController.dispose();
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
          country: _countryController.text.trim().isEmpty ? null : _countryController.text.trim(),
          state: _stateController.text.trim().isEmpty ? null : _stateController.text.trim(),
          gstinUin: _gstinUinController.text.trim().isEmpty ? null : _gstinUinController.text.trim(),
          email: _emailController.text.trim().isEmpty ? null : _emailController.text.trim(),
          openingBalance: double.tryParse(_openingBalanceController.text) ?? 0.0,
          isCredit: _isCredit,
          group: _selectedGroup ?? 'Sundry Debtor',
          dealerType: _selectedDealerType,
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
        existingAccount.country = _countryController.text.trim().isEmpty ? null : _countryController.text.trim();
        existingAccount.state = _stateController.text.trim().isEmpty ? null : _stateController.text.trim();
        existingAccount.gstinUin = _gstinUinController.text.trim().isEmpty ? null : _gstinUinController.text.trim();
        existingAccount.email = _emailController.text.trim().isEmpty ? null : _emailController.text.trim();
        existingAccount.openingBalance = double.tryParse(_openingBalanceController.text) ?? 0.0;
        existingAccount.isCredit = _isCredit;
        existingAccount.group = _selectedGroup ?? 'Sundry Debtor';
        existingAccount.dealerType = _selectedDealerType;
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
                  
                  // Country and State Row
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Country Dropdown (Fixed to India)
                      DropdownButtonFormField<String>(
                        value: 'India',
                        decoration: const InputDecoration(
                          labelText: 'Country',
                          border: OutlineInputBorder(),
                          contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                        ),
                        isExpanded: true,
                        style: const TextStyle(fontSize: 15.5, color: Colors.black),
                        icon: const Icon(Icons.arrow_drop_down, size: 20, color: Colors.black54),
                        dropdownColor: Colors.white,
                        items: const [
                          DropdownMenuItem(
                            value: 'India',
                            child: Text('India', overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 15.5, color: Colors.black)),
                          ),
                        ],
                        onChanged: (value) {
                          // No-op since India is the only option
                        },
                      ),
                      const SizedBox(height: 16),
                      // State Dropdown
                      DropdownButtonFormField<String>(
                        value: _selectedState,
                        decoration: const InputDecoration(
                          labelText: 'State *',
                          border: OutlineInputBorder(),
                          contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                        ),
                        isExpanded: true,
                        style: const TextStyle(fontSize: 15.5, color: Colors.black),
                        icon: const Icon(Icons.arrow_drop_down, size: 20, color: Colors.black54),
                        dropdownColor: Colors.white,
                        hint: const Text('Select State', overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 15.5, color: Colors.black54)),
                        items: [
                          // Add a default empty value as the first item
                          const DropdownMenuItem(
                            value: '',
                            enabled: false,
                            child: Text('Select a state', style: TextStyle(color: Colors.grey)),
                          ),
                          // Add all Indian states
                          ...indianStates.map((state) {
                            return DropdownMenuItem(
                              value: state,
                              child: Text(
                                state,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(fontSize: 15.5, color: Colors.black),
                              ),
                            );
                          }).toList(),
                        ],
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please select a state';
                          }
                          return null;
                        },
                        onChanged: (value) {
                          if (value != null) {
                            setState(() {
                              _selectedState = value;
                              _stateController.text = value;
                            });
                          }
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  
                  // Dealer Type Dropdown
                  DropdownButtonFormField<String>(
                    value: _selectedDealerType,
                    decoration: const InputDecoration(
                      labelText: 'Type of Dealer',
                      border: OutlineInputBorder(),
                    ),
                    items: _dealerTypes.map((type) {
                      return DropdownMenuItem(
                        value: type,
                        child: Text(type),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() {
                        _selectedDealerType = value;
                      });
                    },
                    hint: const Text('Select dealer type'),
                  ),
                  const SizedBox(height: 16),
                  
                  // GSTIN/UIN
                  TextFormField(
                    controller: _gstinUinController,
                    decoration: const InputDecoration(
                      labelText: 'GSTIN/UIN',
                      border: OutlineInputBorder(),
                      hintText: '22AAAAA0000A1Z5',
                    ),
                    keyboardType: TextInputType.text,
                    textCapitalization: TextCapitalization.characters,
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(RegExp(r'[A-Z0-9]')),
                      LengthLimitingTextInputFormatter(15),
                    ],
                    validator: (value) {
                      if (value != null && value.isNotEmpty) {
                        if (value.length != 15) {
                          return 'GSTIN must be 15 characters';
                        }
                      }
                      return null;
                    },
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
