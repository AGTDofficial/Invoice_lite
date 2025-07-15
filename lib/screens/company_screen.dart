import 'package:flutter/material.dart';
import '../models/company.dart';
import '../services/company_service.dart';

class CompanyScreen extends StatefulWidget {
  const CompanyScreen({super.key});

  @override
  State<CompanyScreen> createState() => _CompanyScreenState();
}

class _CompanyScreenState extends State<CompanyScreen> {
  final CompanyService _companyService = CompanyService();
  final _formKey = GlobalKey<FormState>();
  
  final _nameController = TextEditingController();
  final _addressController = TextEditingController();
  final _gstinController = TextEditingController();
  final _mobileNumberController = TextEditingController();
  final _businessStateController = TextEditingController();
  DateTime _selectedFinancialYearStart = DateTime.now();
  String _selectedDealerType = 'Regular';

  @override
  void initState() {
    super.initState();
    _initializeHive();
  }

  Future<void> _initializeHive() async {
    await _companyService.init();
    setState(() {});
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedFinancialYearStart,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      setState(() {
        _selectedFinancialYearStart = picked;
      });
    }
  }

  void _showAddCompanyDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Company'),
        content: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(labelText: 'Company Name'),
                  validator: (value) =>
                      value?.isEmpty ?? true ? 'Please enter company name' : null,
                ),
                TextFormField(
                  controller: _addressController,
                  decoration: const InputDecoration(labelText: 'Address'),
                  validator: (value) =>
                      value?.isEmpty ?? true ? 'Please enter address' : null,
                ),
                TextFormField(
                  controller: _gstinController,
                  decoration: const InputDecoration(labelText: 'GSTIN'),
                  validator: (value) =>
                      value?.isEmpty ?? true ? 'Please enter GSTIN' : null,
                ),
                TextFormField(
                  controller: _mobileNumberController,
                  decoration: const InputDecoration(labelText: 'Mobile Number'),
                  keyboardType: TextInputType.phone,
                  validator: (value) {
                    if (value?.isEmpty ?? true) {
                      return 'Please enter mobile number';
                    }
                    if (!RegExp(r'^\d{10}$').hasMatch(value!)) {
                      return 'Please enter a valid 10-digit mobile number';
                    }
                    return null;
                  },
                ),
                TextFormField(
                  controller: _businessStateController,
                  decoration: const InputDecoration(labelText: 'Business State'),
                  validator: (value) =>
                      value?.isEmpty ?? true ? 'Please enter business state' : null,
                ),
                ListTile(
                  title: const Text('Financial Year Start'),
                  subtitle: Text(
                    '${_selectedFinancialYearStart.day}/${_selectedFinancialYearStart.month}/${_selectedFinancialYearStart.year}',
                  ),
                  onTap: () => _selectDate(context),
                ),
                DropdownButtonFormField<String>(
                  value: _selectedDealerType,
                  decoration: const InputDecoration(labelText: 'Dealer Type'),
                  items: const [
                    DropdownMenuItem(value: 'Regular', child: Text('Regular')),
                    DropdownMenuItem(value: 'Composite', child: Text('Composite')),
                  ],
                  onChanged: (value) {
                    setState(() {
                      _selectedDealerType = value!;
                    });
                  },
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: _addCompany,
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  void _addCompany() {
    if (_formKey.currentState?.validate() ?? false) {
      // Generate default username from company name (lowercase with underscores)
      _nameController.text
          .toLowerCase()
          .replaceAll(RegExp(r'[^a-z0-9]'), '_')
          .replaceAll(RegExp(r'_+'), '_')
          .replaceAll(RegExp(r'^_|_$'), '');
          
      final company = Company(
        name: _nameController.text,
        address: _addressController.text,
        gstin: _gstinController.text,
        financialYearStart: _selectedFinancialYearStart,
        mobileNumber: _mobileNumberController.text,
        businessState: _businessStateController.text,
        dealerType: _selectedDealerType,
        email: '${_nameController.text.toLowerCase().replaceAll(' ', '')}@company.com', // Auto-generated email
        pincode: '000000', // Default pincode
      );

      _companyService.addCompany(company);
      
      _nameController.clear();
      _addressController.clear();
      _gstinController.clear();
      _mobileNumberController.clear();
      _businessStateController.clear();
      _selectedFinancialYearStart = DateTime.now();
      _selectedDealerType = 'Regular';

      Navigator.pop(context);
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    final companies = _companyService.getAllCompanies();
    final currentCompany = _companyService.getCurrentCompany();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Company Management'),
      ),
      body: companies.isEmpty
          ? Center(
              child: Text(
                'No companies added yet',
                style: Theme.of(context).textTheme.titleLarge,
              ),
            )
          : ListView.builder(
              itemCount: companies.length,
              itemBuilder: (context, index) {
                final company = companies[index];
                final isSelected = company == currentCompany;

                return Card(
                  elevation: isSelected ? 4 : 1,
                  margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  child: ListTile(
                    title: Text(company.name),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('GSTIN: ${company.gstin}'),
                        Text('Mobile: ${company.mobileNumber}'),
                        Text('State: ${company.businessState}'),
                        Text('Dealer Type: ${company.dealerType}'),
                      ],
                    ),
                    isThreeLine: true,
                    selected: isSelected,
                    onTap: () {
                      _companyService.setCurrentCompany(index);
                      setState(() {});
                    },
                    trailing: IconButton(
                      icon: const Icon(Icons.delete),
                      onPressed: () {
                        _companyService.deleteCompany(index);
                        setState(() {});
                      },
                    ),
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddCompanyDialog,
        child: const Icon(Icons.add),
      ),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _addressController.dispose();
    _gstinController.dispose();
    _mobileNumberController.dispose();
    _businessStateController.dispose();
    super.dispose();
  }
}
