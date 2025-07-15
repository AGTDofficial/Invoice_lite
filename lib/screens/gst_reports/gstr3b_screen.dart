import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../services/gst_report_service.dart';
import '../../models/gst_report_model.dart';

class GSTR3BScreen extends StatefulWidget {
  final DateTime fromDate;
  final DateTime toDate;

  const GSTR3BScreen({
    Key? key,
    required this.fromDate,
    required this.toDate,
  }) : super(key: key);

  @override
  _GSTR3BScreenState createState() => _GSTR3BScreenState();
}

class _GSTR3BScreenState extends State<GSTR3BScreen> {
  bool _isLoading = true;
  late GSTR3BReport _report;
  final GSTReportService _reportService = GSTReportService();

  @override
  void initState() {
    super.initState();
    _loadReport();
  }

  Future<void> _loadReport() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final report = await _reportService.generateGSTR3BReport(
        fromDate: widget.fromDate,
        toDate: widget.toDate,
      );
      
      setState(() {
        _report = report;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading report: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('GSTR-3B Report'),
        actions: [
          IconButton(
            icon: const Icon(Icons.picture_as_pdf),
            onPressed: _exportToPDF,
            tooltip: 'Export to PDF',
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadReport,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildSummaryCard(),
                  const SizedBox(height: 24),
                  _buildOutwardSuppliesCard(),
                  const SizedBox(height: 24),
                  _buildInwardSuppliesCard(),
                  const SizedBox(height: 24),
                  _buildTaxPaymentCard(),
                ],
              ),
            ),
    );
  }

  Widget _buildSummaryCard() {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Summary',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const Divider(),
            const SizedBox(height: 8),
            _buildSummaryRow('Reporting Period',
                '${DateFormat('dd MMM yyyy').format(_report.fromDate)} - ${DateFormat('dd MMM yyyy').format(_report.toDate)}'),
            _buildSummaryRow('Outward Supplies', _formatCurrency(_report.outwardTaxableValue)),
            _buildSummaryRow('Inward Supplies', _formatCurrency(_report.inwardTaxableValue)),
            const SizedBox(height: 8),
            const Divider(),
            const SizedBox(height: 8),
            _buildSummaryRow(
              'Total Tax Payable',
              _formatCurrency(_report.taxPayable),
              isBold: true,
              textColor: Colors.red,
            ),
            _buildSummaryRow(
              'Input Tax Credit Available',
              _formatCurrency(_report.itcAvailable),
              isBold: true,
              textColor: Colors.green,
            ),
            _buildSummaryRow(
              'Net Tax Payable',
              _formatCurrency(_report.taxPayable - _report.itcAvailable),
              isBold: true,
              textColor: Colors.blue,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOutwardSuppliesCard() {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Outward Supplies',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const Divider(),
            const SizedBox(height: 8),
            _buildTaxSummaryRow('Taxable Value', _report.outwardTaxableValue),
            _buildTaxSummaryRow('CGST', _report.outwardCGST),
            _buildTaxSummaryRow('SGST', _report.outwardSGST),
            _buildTaxSummaryRow('IGST', _report.outwardIGST),
            const Divider(),
            _buildTaxSummaryRow(
              'Total Tax on Outward Supplies',
              _report.outwardCGST + _report.outwardSGST + _report.outwardIGST,
              isTotal: true,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInwardSuppliesCard() {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Inward Supplies',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const Divider(),
            const SizedBox(height: 8),
            _buildTaxSummaryRow('Taxable Value', _report.inwardTaxableValue),
            _buildTaxSummaryRow('CGST', _report.inwardCGST),
            _buildTaxSummaryRow('SGST', _report.inwardSGST),
            _buildTaxSummaryRow('IGST', _report.inwardIGST),
            const Divider(),
            _buildTaxSummaryRow(
              'Total ITC Available',
              _report.inwardCGST + _report.inwardSGST + _report.inwardIGST,
              isTotal: true,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTaxPaymentCard() {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Tax Payment',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const Divider(),
            const SizedBox(height: 8),
            _buildPaymentRow('Tax Payable', _report.taxPayable),
            _buildPaymentRow('Less: ITC Available', _report.itcAvailable),
            _buildPaymentRow('Tax Payable in Cash', _report.taxPayable - _report.itcAvailable),
            const Divider(),
            _buildPaymentRow('Interest Payable', _report.interestPayable, isHighlighted: true),
            _buildPaymentRow('Late Fee Payable', _report.lateFeePayable, isHighlighted: true),
            const Divider(),
            _buildPaymentRow(
              'Total Amount Payable',
              (_report.taxPayable - _report.itcAvailable) + _report.interestPayable + _report.lateFeePayable,
              isTotal: true,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryRow(String label, String value, {bool isBold = false, Color? textColor}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
              color: textColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTaxSummaryRow(String label, double amount, {bool isTotal = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
            ),
          ),
          Text(
            _formatCurrency(amount),
            style: TextStyle(
              fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
              color: isTotal ? Colors.blue : null,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentRow(String label, double amount, {bool isHighlighted = false, bool isTotal = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
              color: isHighlighted ? Colors.red : null,
            ),
          ),
          Text(
            _formatCurrency(amount),
            style: TextStyle(
              fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
              color: isTotal ? Colors.blue : (isHighlighted ? Colors.red : null),
            ),
          ),
        ],
      ),
    );
  }

  String _formatCurrency(double amount) {
    return '₹${amount.toStringAsFixed(2)}';
  }

  void _exportToPDF() {
    // TODO: Implement PDF export
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Export to PDF will be implemented soon')),
    );
  }
}
