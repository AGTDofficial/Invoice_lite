import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hive/hive.dart';
import '../models/company.dart';


class CompanyFormScreen extends StatefulWidget {
  final Company? company;
  final int? companyIndex;

  const CompanyFormScreen({
    Key? key,
    this.company,
    this.companyIndex,
  }) : super(key: key);

  @override
  State<CompanyFormScreen> createState() => _CompanyFormScreenState();
}

class _CompanyFormScreenState extends State<CompanyFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _addressController = TextEditingController();
  final _mobileController = TextEditingController();
  final _emailController = TextEditingController();
  final _pincodeController = TextEditingController();
  final _stateSearchController = TextEditingController();

  String _selectedState = 'Maharashtra';
  String _businessType = 'Other';
  final DateTime _financialYearStart = DateTime(DateTime.now().month >= 4 
      ? DateTime.now().year 
      : DateTime.now().year - 1, 4, 1); // April 1st of current financial year

  final List<String> _states = [
    'Andhra Pradesh',
    'Arunachal Pradesh',
    'Assam',
    'Bihar',
    'Chhattisgarh',
    'Goa',
    'Gujarat',
    'Haryana',
    'Himachal Pradesh',
    'Jharkhand',
    'Karnataka',
    'Kerala',
    'Madhya Pradesh',
    'Maharashtra',
    'Manipur',
    'Meghalaya',
    'Mizoram',
    'Nagaland',
    'Odisha',
    'Punjab',
    'Rajasthan',
    'Sikkim',
    'Tamil Nadu',
    'Telangana',
    'Tripura',
    'Uttar Pradesh',
    'Uttarakhand',
    'West Bengal',
    'Andaman and Nicobar Islands',
    'Chandigarh',
    'Dadra and Nagar Haveli and Daman and Diu',
    'Delhi',
    'Jammu and Kashmir',
    'Ladakh',
    'Lakshadweep',
    'Puducherry'
  ]..sort();
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
    _mobileController.dispose();
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
      _mobileController.text = company.mobileNumber;
      _selectedState = company.businessState;
      _emailController.text = company.email;
      _pincodeController.text = company.pincode;
      _stateSearchController.text = company.businessState;
      _businessType = company.businessType ?? 'Other';
    }
  }

  String? _validateMobile(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter mobile number';
    }
    final pattern = RegExp(r'^[0-9]{10,15}$');
    if (!pattern.hasMatch(value)) {
      return 'Enter valid 10-15 digit mobile number';
    }
    return null;
  }

  Future<void> _saveForm() async {
    if (!_formKey.currentState!.validate()) return;

    final company = Company(
      name: _nameController.text.trim(),
      address: _addressController.text.trim(),
      mobileNumber: _mobileController.text.trim(),
      email: _emailController.text.trim(),
      pincode: _pincodeController.text.trim(),
      businessState: _selectedState,
      businessType: _businessType,
      gstin: '', // Empty string as GST is not required
      financialYearStart: _financialYearStart,
      dealerType: 'Regular', // Default value
    );

    try {
      final box = await Hive.openBox<Company>('companies');
      if (isEditing) {
        await box.put(widget.company!.key, company);
      } else {
        await box.add(company);
      }
      if (mounted) {
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving company: $e')),
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
        title: Text(isEditing ? 'Edit Company' : 'Create Company'),
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildTextField(
                  _nameController, 
                  'Company Name', 
                  validator: (v) => v!.isEmpty ? 'Required' : null,
                ),
                const SizedBox(height: 16),
                
                _buildDropdownField(
                  label: 'Business Type',
                  value: _businessType,
                  items: const ['Retail', 'Wholesale', 'Service', 'Manufacturing', 'Other'],
                  onChanged: (val) => setState(() => _businessType = val!),
                ),
                const SizedBox(height: 16),

                _buildTextField(
                  _addressController, 
                  'Address', 
                  maxLines: 3,
                ),
                const SizedBox(height: 16),

                _buildTextField(
                  _mobileController,
                  'Mobile Number',
                  keyboardType: TextInputType.phone,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  validator: _validateMobile,
                ),
                const SizedBox(height: 16),

                _buildDropdownField(
                  label: 'State of Business',
                  value: _selectedState,
                  items: _states,
                  onChanged: (val) => setState(() => _selectedState = val!),
                ),
                const SizedBox(height: 16),

                _buildTextField(
                  _emailController,
                  'Email',
                  keyboardType: TextInputType.emailAddress,
                  validator: (v) => (v == null || v.isEmpty || !v.contains('@')) 
                      ? 'Enter a valid email' 
                      : null,
                ),
                const SizedBox(height: 16),

                _buildTextField(
                  _pincodeController,
                  'Pincode',
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  validator: (v) => (v == null || v.length != 6) 
                      ? 'Enter 6-digit pincode' 
                      : null,
                ),
                const SizedBox(height: 16),

                const Divider(),
                const SizedBox(height: 16),

                ElevatedButton(
                  onPressed: _saveForm,
                  child: Text(isEditing ? 'Update Company' : 'Create Company'),
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(
    TextEditingController controller, 
    String label, {
    bool obscureText = false,
    TextInputType? keyboardType,
    List<TextInputFormatter>? inputFormatters,
    int? maxLines = 1,
    String? Function(String?)? validator,
    bool enabled = true,
  }) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
        enabled: enabled,
      ),
      obscureText: obscureText,
      keyboardType: keyboardType,
      inputFormatters: inputFormatters,
      maxLines: maxLines,
      validator: validator,
    );
  }

  Widget _buildDropdownField<T>({
    required String label,
    required T value,
    required List<T> items,
    required void Function(T?) onChanged,
  }) {
    return DropdownButtonFormField<T>(
      value: value,
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
      ),
      items: items.map((item) {
        return DropdownMenuItem<T>(
          value: item,
          child: Text(item.toString()),
        );
      }).toList(),
      onChanged: onChanged,
    );
  }
}


