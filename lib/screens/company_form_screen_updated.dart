import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hive/hive.dart';
import '../models/company.dart';
import '../utils/text_formatters.dart';
import '../utils/constants.dart';

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
  final _gstinController = TextEditingController();
  final _mobileNumberController = TextEditingController();
  final _stateSearchController = TextEditingController();
  
  DateTime _selectedDate = DateTime.now();
  String _selectedState = 'Maharashtra';
  String _selectedDealerType = 'Regular';
  String _gstStatus = 'Registered';
  String? _businessType;

  bool get isEditing => widget.company != null;

  // State list is available through gstStateCodeMap

  @override
  void initState() {
    super.initState();
    _initializeFields();
    _gstinController.addListener(_handleGSTINChange);
  }

  @override
  void dispose() {
    _gstinController.removeListener(_handleGSTINChange);
    _nameController.dispose();
    _addressController.dispose();
    _gstinController.dispose();
    _mobileNumberController.dispose();
    _stateSearchController.dispose();
    super.dispose();
  }

  void _initializeFields() {
    final company = widget.company;
    if (company != null) {
      _nameController.text = company.name;
      _addressController.text = company.address;
      _gstinController.text = company.gstin;
      _mobileNumberController.text = company.mobileNumber;
      _selectedState = company.businessState;
      _selectedDealerType = company.dealerType;
      _stateSearchController.text = company.businessState;
      _gstStatus = company.isRegistered ? 'Registered' : 'Unregistered';
      _businessType = company.businessType;
    }
  }

  void _handleGSTINChange() {
    final gstin = _gstinController.text;
    if (gstin.length >= 2) {
      final stateCode = gstin.substring(0, 2);
      final stateName = getStateNameFromGSTCode(stateCode);
      if (stateName != null && stateName != _selectedState) {
        setState(() {
          _selectedState = stateName;
          _stateSearchController.text = stateName;
        });
      }
    }
  }

  Future<void> _saveForm() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }



    final company = Company(
      name: _nameController.text.trim(),
      address: _addressController.text.trim(),
      gstin: _gstinController.text.trim(),
      financialYearStart: _selectedDate,
      mobileNumber: _mobileNumberController.text.trim(),
      businessState: _selectedState,
      dealerType: _selectedDealerType,
      isRegistered: _gstStatus == 'Registered',
      businessType: _businessType,
      email: '${_nameController.text.trim().toLowerCase()}@company.com',
      pincode: '000000', // Default pincode
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
            
            // GST Registration Status
            DropdownButtonFormField<String>(
              value: _gstStatus,
              decoration: const InputDecoration(labelText: 'GST Registration Status'),
              items: ['Registered', 'Unregistered']
                  .map((status) => DropdownMenuItem(
                        value: status,
                        child: Text(status),
                      ))
                  .toList(),
              onChanged: (value) {
                setState(() {
                  _gstStatus = value!;
                  if (_gstStatus == 'Unregistered') {
                    _gstinController.clear();
                    _businessType = null;
                  }
                });
              },
            ),
            const SizedBox(height: 16),
            
            // GST Number (only if registered)
            if (_gstStatus == 'Registered')
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextFormField(
                    controller: _gstinController,
                    decoration: const InputDecoration(
                      labelText: 'GST Number',
                      hintText: '22AAAAA0000A1Z5',
                    ),
                    inputFormatters: [
                      UpperCaseTextFormatter(),
                      FilteringTextInputFormatter.allow(RegExp(r'[0-9A-Z]')),
                      LengthLimitingTextInputFormatter(15),
                    ],
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter GST number';
                      }
                      if (value.length != 15) {
                        return 'GST number must be 15 characters';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  // Business Type (only if registered)
                  DropdownButtonFormField<String>(
                    value: _businessType,
                    decoration: const InputDecoration(labelText: 'Business Type'),
                    items: ['Regular', 'Composition']
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
                      if (_gstStatus == 'Registered' && (value == null || value.isEmpty)) {
                        return 'Please select business type';
                      }
                      return null;
                    },
                  ),
                ],
              ),
            
            // Other existing fields...
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
