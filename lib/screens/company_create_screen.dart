import 'package:flutter/material.dart';
// ignore: duplicate_import
import 'package:flutter/material.dart';
import '../constants/indian_states.dart';
import '../services/form_validator.dart';
import '../services/company_service.dart';
import '../models/company.dart';
import '../utils/text_formatters.dart' as formatters;

class CompanyCreateScreen extends StatefulWidget {
  const CompanyCreateScreen({super.key});

  @override
  State<CompanyCreateScreen> createState() => _CompanyCreateScreenState();
}

class _CompanyCreateScreenState extends State<CompanyCreateScreen> {
  final _formKey = GlobalKey<FormState>();
  final _companyNameController = TextEditingController();
  final _legalNameController = TextEditingController();
  final _gstinController = TextEditingController();
  final _panController = TextEditingController();
  final _mobileController = TextEditingController();
  final _emailController = TextEditingController();
  final _address1Controller = TextEditingController();
  final _address2Controller = TextEditingController();
  final _pincodeController = TextEditingController();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  String? _selectedState;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  // Remove unused _selectedCountry field as it's not being used
  bool _isLoading = false;

  @override
  void dispose() {
    _companyNameController.dispose();
    _legalNameController.dispose();
    _gstinController.dispose();
    _panController.dispose();
    _mobileController.dispose();
    _emailController.dispose();
    _address1Controller.dispose();
    _address2Controller.dispose();
    _pincodeController.dispose();
    _usernameController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);
    
    // Generate default username from company name (lowercase with underscores)
    final company = Company(
      name: _companyNameController.text,
      address: '${_address1Controller.text}${_address2Controller.text.isNotEmpty ? ', ${_address2Controller.text}' : ''}, ${_selectedState ?? ''} - ${_pincodeController.text}',
      gstin: _gstinController.text,
      financialYearStart: DateTime.now(),
      mobileNumber: _mobileController.text,
      businessState: _selectedState ?? '',
      dealerType: 'Regular',
      email: _emailController.text,
      pincode: _pincodeController.text,
    );
    
    try {
      final service = CompanyService();
      await service.init();
      await service.addCompany(company);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Company created successfully!')),
      );
      Navigator.of(context).pop();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to create company: $e')),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Create Company'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                controller: _companyNameController,
                decoration: const InputDecoration(
                  labelText: 'Company Name',
                  border: OutlineInputBorder(),
                ),
                validator: (v) => FormValidator.validateRequired(v, 'Company Name'),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _legalNameController,
                decoration: const InputDecoration(
                  labelText: 'Legal Name',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _gstinController,
                decoration: const InputDecoration(
                  labelText: 'GSTIN',
                  border: OutlineInputBorder(),
                ),
                inputFormatters: [formatters.UpperCaseTextFormatter()],
                validator: FormValidator.validateGstin,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _panController,
                decoration: const InputDecoration(
                  labelText: 'PAN',
                  border: OutlineInputBorder(),
                ),
                inputFormatters: [formatters.UpperCaseTextFormatter()],
                validator: FormValidator.validatePan,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _mobileController,
                decoration: const InputDecoration(
                  labelText: 'Mobile Number',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.phone,
                validator: FormValidator.validateMobile,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _emailController,
                decoration: const InputDecoration(
                  labelText: 'Email',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.emailAddress,
                validator: FormValidator.validateEmail,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _address1Controller,
                decoration: const InputDecoration(
                  labelText: 'Address Line 1',
                  border: OutlineInputBorder(),
                ),
                validator: (v) => FormValidator.validateRequired(v, 'Address Line 1'),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _address2Controller,
                decoration: const InputDecoration(
                  labelText: 'Address Line 2 (Optional)',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: DropdownButtonFormField<String>(
                      value: _selectedState,
                      decoration: const InputDecoration(
                        labelText: 'State',
                        border: OutlineInputBorder(),
                      ),
                      items: indianStates.map((state) {
                        return DropdownMenuItem(
                          value: state,
                          child: Text(state),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setState(() {
                          _selectedState = value;
                        });
                      },
                      validator: (v) => v == null ? 'Please select a state' : null,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: TextFormField(
                      controller: _pincodeController,
                      decoration: const InputDecoration(
                        labelText: 'Pincode',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.number,
                      validator: FormValidator.validatePincode,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _pincodeController,
                      decoration: const InputDecoration(
                        labelText: 'Pincode',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.number,
                      validator: FormValidator.validatePincode,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _usernameController,
                decoration: const InputDecoration(
                  labelText: 'Username',
                  border: OutlineInputBorder(),
                  hintText: 'Will be used for login',
                ),
                validator: (v) => FormValidator.validateRequired(v, 'Username'),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _passwordController,
                decoration: InputDecoration(
                  labelText: 'Password',
                  border: const OutlineInputBorder(),
                  suffixIcon: IconButton(
                    icon: Icon(_obscurePassword ? Icons.visibility : Icons.visibility_off),
                    onPressed: () {
                      setState(() {
                        _obscurePassword = !_obscurePassword;
                      });
                    },
                  ),
                ),
                obscureText: _obscurePassword,
                validator: FormValidator.validatePassword,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _confirmPasswordController,
                decoration: InputDecoration(
                  labelText: 'Confirm Password',
                  border: const OutlineInputBorder(),
                  suffixIcon: IconButton(
                    icon: Icon(_obscureConfirmPassword ? Icons.visibility : Icons.visibility_off),
                    onPressed: () {
                      setState(() {
                        _obscureConfirmPassword = !_obscureConfirmPassword;
                      });
                    },
                  ),
                ),
                obscureText: _obscureConfirmPassword,
                validator: (value) {
                  if (value != _passwordController.text) {
                    return 'Passwords do not match';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _isLoading ? null : _submitForm,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: _isLoading
                    ? const CircularProgressIndicator()
                    : const Text('Create Company'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
