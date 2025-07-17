import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hive/hive.dart';
import '../models/company.dart';

class CompanyFormScreen extends StatefulWidget {
  final Company? company;
  final int? companyIndex;

  const CompanyFormScreen({
    super.key, 
    this.company,
    this.companyIndex,
  });

  @override
  State<CompanyFormScreen> createState() => _CompanyFormScreenState();
}

class _CompanyFormScreenState extends State<CompanyFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _addressController = TextEditingController();
  final _mobileNumberController = TextEditingController();
  final _stateSearchController = TextEditingController();
  final _emailController = TextEditingController();
  final _pincodeController = TextEditingController();
  
  String _selectedState = 'Maharashtra';
  String _businessType = 'Other';
  final DateTime _financialYearStart = DateTime(DateTime.now().month >= 4 
      ? DateTime.now().year 
      : DateTime.now().year - 1, 4, 1); // April 1st of current financial year

  bool get isEditing => widget.company != null;

  @override
  void initState() {
    super.initState();
    _initializeFields();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _addressController.dispose();
    _mobileNumberController.dispose();
    _emailController.dispose();
    _pincodeController.dispose();
    _stateSearchController.dispose();
    super.dispose();
  }

  void _initializeFields() {
    if (widget.company != null) {
      final company = widget.company!;
      _nameController.text = company.name;
      _addressController.text = company.address;
      _mobileNumberController.text = company.mobileNumber;
      _emailController.text = company.email;
      _pincodeController.text = company.pincode;
      _selectedState = company.businessState;
      _businessType = company.businessType ?? 'Other';
      _stateSearchController.text = company.businessState;
    }
  }



  Future<void> _saveForm() async {
    if (!_formKey.currentState!.validate()) return;

    final company = Company(
      name: _nameController.text.trim(),
      address: _addressController.text.trim(),
      mobileNumber: _mobileNumberController.text.trim(),
      email: _emailController.text.trim(),
      pincode: _pincodeController.text.trim(),
      businessState: _selectedState,
      businessType: _businessType,
      gstin: '', // Empty string as GST is not required
      financialYearStart: _financialYearStart,
      dealerType: 'Regular', // Default value
    );

    final box = Hive.box<Company>('companies');
    
    if (widget.companyIndex != null) {
      await box.putAt(widget.companyIndex!, company);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Company updated successfully')),
        );
      }
    } else {
      await box.add(company);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Company added successfully')),
        );
      }
    }

    if (mounted) {
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    
    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? 'Edit Company' : 'Add Company'),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16.0),
          children: [
            // Company Name
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(labelText: 'Company Name'),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter company name';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            
            // Business Type
            DropdownButtonFormField<String>(
              value: _businessType,
              decoration: const InputDecoration(labelText: 'Business Type'),
              items: const ['Retail', 'Wholesale', 'Service', 'Manufacturing', 'Other']
                  .map((type) => DropdownMenuItem(
                        value: type,
                        child: Text(type),
                      ))
                  .toList(),
              onChanged: (value) {
                setState(() {
                  _businessType = value!;
                });
              },
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please select business type';
                }
                return null;
              },
            ),
            
            const SizedBox(height: 16),
            TextFormField(
              controller: _addressController,
              maxLines: 3,
              decoration: const InputDecoration(labelText: 'Address'),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter address';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _mobileNumberController,
              decoration: const InputDecoration(labelText: 'Mobile Number'),
              keyboardType: TextInputType.phone,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              validator: _validateMobile,
            ),
            const SizedBox(height: 24),
            
            // Save Button
            ElevatedButton(
              onPressed: _saveForm,
              child: Text(isEditing ? 'Update Company' : 'Add Company'),
            ),
          ],
        ),
      ),
    );
  }
  
  String? _validateMobile(String? value) {
    if (value == null || value.isEmpty) {
      return 'Mobile number is required';
    }
    if (value.length != 10) {
      return 'Mobile number must be exactly 10 digits';
    }
    if (!RegExp(r'^[6-9][0-9]{9}').hasMatch(value)) {
      return 'Enter a valid Indian mobile number starting with 6-9';
    }
    return null;
  }
}
