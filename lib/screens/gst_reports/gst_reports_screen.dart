import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'gstr1_screen.dart';
import 'gstr3b_screen.dart';
import 'gstr2a_reconciliation_screen.dart';

class GSTReportsScreen extends StatefulWidget {
  const GSTReportsScreen({Key? key}) : super(key: key);

  @override
  _GSTReportsScreenState createState() => _GSTReportsScreenState();
}

class _GSTReportsScreenState extends State<GSTReportsScreen> {
  DateTime? _fromDate;
  DateTime? _toDate;
  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    // Default to current month
    final now = DateTime.now();
    _fromDate = DateTime(now.year, now.month, 1);
    _toDate = DateTime(now.year, now.month + 1, 0);
  }

  Future<void> _selectDate(BuildContext context, bool isFromDate) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: isFromDate ? _fromDate! : _toDate!,
      firstDate: DateTime(2020),
      lastDate: DateTime(2101),
    );
    if (picked != null) {
      setState(() {
        if (isFromDate) {
          _fromDate = picked;
          // If toDate is before fromDate, update toDate to be the same as fromDate
          if (_toDate!.isBefore(picked)) {
            _toDate = picked;
          }
        } else {
          _toDate = picked;
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('GST Reports'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Select Date Range',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: InkWell(
                              onTap: () => _selectDate(context, true),
                              child: InputDecorator(
                                decoration: const InputDecoration(
                                  labelText: 'From Date',
                                  border: OutlineInputBorder(),
                                ),
                                child: Text(
                                  _fromDate != null
                                      ? DateFormat('dd/MM/yyyy').format(_fromDate!)
                                      : 'Select Date',
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: InkWell(
                              onTap: () => _selectDate(context, false),
                              child: InputDecorator(
                                decoration: const InputDecoration(
                                  labelText: 'To Date',
                                  border: OutlineInputBorder(),
                                ),
                                child: Text(
                                  _toDate != null
                                      ? DateFormat('dd/MM/yyyy').format(_toDate!)
                                      : 'Select Date',
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              _buildReportCard(
                context,
                title: 'GSTR-1',
                subtitle: 'Outward supplies to registered persons (B2B)',
                icon: Icons.receipt_long,
                onTap: () {
                  if (_validateDates()) {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => GSTR1Screen(
                          fromDate: _fromDate!,
                          toDate: _toDate!,
                        ),
                      ),
                    );
                  }
                },
              ),
              const SizedBox(height: 16),
              _buildReportCard(
                context,
                title: 'GSTR-3B',
                subtitle: 'Monthly summary return for normal taxpayers',
                icon: Icons.summarize,
                onTap: () {
                  if (_validateDates()) {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => GSTR3BScreen(
                          fromDate: _fromDate!,
                          toDate: _toDate!,
                        ),
                      ),
                    );
                  }
                },
              ),
              const SizedBox(height: 16),
              _buildReportCard(
                context,
                title: 'GSTR-2A Reconciliation',
                subtitle: 'Reconcile purchase with GSTR-2A',
                icon: Icons.compare_arrows,
                onTap: () {
                  if (_validateDates()) {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => GSTR2AReconciliationScreen(
                          fromDate: _fromDate!,
                          toDate: _toDate!,
                        ),
                      ),
                    );
                  }
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildReportCard(
    BuildContext context, {
    required String title,
    required String subtitle,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 2,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Theme.of(context).primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: Theme.of(context).primaryColor, size: 28),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, color: Colors.grey),
            ],
          ),
        ),
      ),
    );
  }

  bool _validateDates() {
    if (_fromDate == null || _toDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select both from and to dates')),
      );
      return false;
    }
    
    if (_toDate!.isBefore(_fromDate!)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('To date cannot be before from date')),
      );
      return false;
    }
    
    return true;
  }
}
