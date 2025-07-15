import 'package:flutter/material.dart';

class JournalVoucherScreen extends StatefulWidget {
  const JournalVoucherScreen({super.key});
  
  @override
  State<JournalVoucherScreen> createState() => _JournalVoucherScreenState();
}

class _JournalVoucherScreenState extends State<JournalVoucherScreen> {
  final _formKey = GlobalKey<FormState>();
  DateTime _selectedDate = DateTime.now();
  String _selectedType = 'cash';
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Journal Entry'),
        actions: [
          IconButton(
            icon: Icon(Icons.save),
            onPressed: _saveVoucher,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildDateField(),
              SizedBox(height: 16),
              _buildTypeDropdown(),
              SizedBox(height: 16),
              _buildAmountField(),
              SizedBox(height: 16),
              _buildDescriptionField(),
              SizedBox(height: 24),
              _buildPartySection(),
              SizedBox(height: 24),
              _buildAccountSection(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDateField() {
    return ListTile(
      title: Text('Date'),
      subtitle: Text('${_selectedDate.toLocal()}'.split(' ')[0]),
      trailing: Icon(Icons.calendar_today),
      onTap: _selectDate,
    );
  }

  Widget _buildTypeDropdown() {
    return DropdownButtonFormField<String>(
      value: _selectedType,
      decoration: InputDecoration(
        labelText: 'Transaction Type',
        border: OutlineInputBorder(),
      ),
      items: <String>['cash', 'bank', 'journal'].map((String value) {
        return DropdownMenuItem<String>(
          value: value,
          child: Text(value[0].toUpperCase() + value.substring(1)),
        );
      }).toList(),
      onChanged: (String? newValue) {
        if (newValue != null) {
          setState(() {
            _selectedType = newValue;
          });
        }
      },
    );
  }

  Widget _buildAmountField() {
    return TextFormField(
      controller: _amountController,
      decoration: InputDecoration(
        labelText: 'Amount',
        border: OutlineInputBorder(),
        prefixText: '₹ ',
      ),
      keyboardType: TextInputType.numberWithOptions(decimal: true),
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Please enter an amount';
        }
        if (double.tryParse(value) == null) {
          return 'Please enter a valid number';
        }
        return null;
      },
    );
  }

  Widget _buildDescriptionField() {
    return TextFormField(
      controller: _descriptionController,
      decoration: InputDecoration(
        labelText: 'Description',
        border: OutlineInputBorder(),
      ),
      maxLines: 3,
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Please enter a description';
        }
        return null;
      },
    );
  }

  Widget _buildPartySection() {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Party Details', style: Theme.of(context).textTheme.titleMedium),
            SizedBox(height: 8),
            // Add party selection widgets here
          ],
        ),
      ),
    );
  }

  Widget _buildAccountSection() {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Account Details', style: Theme.of(context).textTheme.titleMedium),
            SizedBox(height: 8),
            // Add account selection widgets here
          ],
        ),
      ),
    );
  }

  Future<void> _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  void _saveVoucher() {
    if (_formKey.currentState!.validate()) {
      // Save the voucher
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Voucher saved successfully')),
      );
    }
  }

  @override
  void dispose() {
    _amountController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }
}
