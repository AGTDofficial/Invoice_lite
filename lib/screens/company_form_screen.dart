import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hive/hive.dart';
import '../models/company.dart';
import '../utils/constants.dart';

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
  final _gstController = TextEditingController();
  final _addressController = TextEditingController();
  final _mobileController = TextEditingController();
  final _emailController = TextEditingController();
  final _pincodeController = TextEditingController();
  final _stateSearchController = TextEditingController();

  String _registrationStatus = 'Registered';
  String _dealerType = 'Regular';
  String _selectedState = 'Maharashtra';
  String? _businessType;
  DateTime _selectedDate = DateTime.now();

  final List<String> _states = gstStateCodeMap.values.toList()..sort();
  bool get isRegistered => _registrationStatus == 'Registered';
  bool get isEditing => widget.company != null;

  @override
  void initState() {
    super.initState();
    _gstController.addListener(_onGstChanged);
    _initializeFields();
  }

  @override
  void dispose() {
    _gstController.removeListener(_onGstChanged);
    _nameController.dispose();
    _gstController.dispose();
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
      _gstController.text = company.gstin;
      _addressController.text = company.address;
      _mobileController.text = company.mobileNumber;
      _selectedState = company.businessState;
      _registrationStatus = company.isRegistered ? 'Registered' : 'Unregistered';
      _dealerType = company.dealerType;
      _emailController.text = company.email;
      _pincodeController.text = company.pincode;
      _stateSearchController.text = company.businessState;
      _businessType = company.businessType;
    }
  }

  void _onGstChanged() {
    final gstin = _gstController.text;
    if (gstin.length >= 2) {
      final code = gstin.substring(0, 2);
      final state = getStateNameFromGSTCode(code);
      if (state != null && state != _selectedState) {
        setState(() {
          _selectedState = state;
          _stateSearchController.text = state;
        });
      }
    }
  }

  String? _validateGst(String? value) {
    if (!isRegistered) return null;
    final pattern = RegExp(r'^[0-9A-Z]{15}$');
    if (value == null || !pattern.hasMatch(value)) {
      return 'Enter valid 15-char GSTIN in capital letters';
    }
    return null;
  }

  String? _validateMobile(String? value) {
    if (value == null || value.isEmpty || value.length != 10) {
      return 'Enter 10-digit mobile number';
    }
    return null;
  }

  Future<void> _saveForm() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;



    final company = Company(
      name: _nameController.text.trim(),
      gstin: isRegistered ? _gstController.text.trim() : '',
      address: _addressController.text.trim(),
      mobileNumber: _mobileController.text.trim(),
      businessState: _selectedState,
      dealerType: isRegistered ? _dealerType : 'Unregistered',
      isRegistered: isRegistered,
      financialYearStart: _selectedDate,

      email: _emailController.text.trim(),
      pincode: _pincodeController.text.trim(),
      businessType: _businessType,
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
                  label: 'GST Registration Status',
                  value: _registrationStatus,
                  items: ['Registered', 'Unregistered'],
                  onChanged: (val) => setState(() => _registrationStatus = val!),
                ),
                const SizedBox(height: 16),

                if (isRegistered) ...[
                  _buildTextField(
                    _gstController,
                    'GST Number',
                    inputFormatters: [UpperCaseTextFormatter()],
                    validator: _validateGst,
                  ),
                  const SizedBox(height: 16),
                  _buildDropdownField(
                    label: 'Business Type',
                    value: _dealerType,
                    items: ['Regular', 'Composition'],
                    onChanged: (val) => setState(() => _dealerType = val!),
                  ),
                  const SizedBox(height: 16),
                ],

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

class UpperCaseTextFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    return TextEditingValue(
      text: newValue.text.toUpperCase(),
      selection: newValue.selection,
    );
  }
}
