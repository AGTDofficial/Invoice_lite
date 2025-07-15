import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../services/gst_report_service.dart';
import '../../models/gst_report_model.dart';

class GSTR1Screen extends StatefulWidget {
  final DateTime fromDate;
  final DateTime toDate;

  const GSTR1Screen({
    Key? key,
    required this.fromDate,
    required this.toDate,
  }) : super(key: key);

  @override
  _GSTR1ScreenState createState() => _GSTR1ScreenState();
}

class _GSTR1ScreenState extends State<GSTR1Screen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isLoading = true;
  late GSTR1Report _report;
  final GSTReportService _reportService = GSTReportService();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadReport();
  }

  Future<void> _loadReport() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final report = await _reportService.generateGSTR1Report(
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
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('GSTR-1 Report'),
          bottom: TabBar(
            controller: _tabController,
            tabs: const [
              Tab(text: 'B2B'),
              Tab(text: 'B2CS'),
              Tab(text: 'HSN Summary'),
            ],
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.picture_as_pdf),
              onPressed: _exportToPDF,
              tooltip: 'Export to PDF',
            ),
            IconButton(
              icon: const Icon(Icons.file_download),
              onPressed: _exportToExcel,
              tooltip: 'Export to Excel',
            ),
          ],
        ),
        body: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : TabBarView(
                controller: _tabController,
                children: [
                  _buildB2BTable(),
                  _buildB2CSTable(),
                  _buildHSNSummaryTable(),
                ],
              ),
      ),
    );
  }

  Widget _buildB2BTable() {
    if (_report.b2bInvoices.isEmpty) {
      return const Center(child: Text('No B2B invoices found'));
    }

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: DataTable(
        columns: const [
          DataColumn(label: Text('Invoice No.')),
          DataColumn(label: Text('Date')),
          DataColumn(label: Text('Customer GSTIN')),
          DataColumn(label: Text('Customer Name')),
          DataColumn(label: Text('Taxable Value'), numeric: true),
          DataColumn(label: Text('CGST'), numeric: true),
          DataColumn(label: Text('SGST'), numeric: true),
          DataColumn(label: Text('IGST'), numeric: true),
          DataColumn(label: Text('Total'), numeric: true),
        ],
        rows: _report.b2bInvoices.map((invoice) {
          return DataRow(cells: [
            DataCell(Text(invoice.invoiceNumber)),
            DataCell(Text(DateFormat('dd/MM/yyyy').format(invoice.invoiceDate))),
            DataCell(Text(invoice.customerGSTIN)),
            DataCell(Text(invoice.customerName)),
            DataCell(Text(_formatCurrency(invoice.taxableValue))),
            DataCell(Text(_formatCurrency(invoice.cgst))),
            DataCell(Text(_formatCurrency(invoice.sgst))),
            DataCell(Text(_formatCurrency(invoice.igst))),
            DataCell(Text(_formatCurrency(invoice.total))),
          ]);
        }).toList(),
      ),
    );
  }

  Widget _buildB2CSTable() {
    if (_report.b2csInvoices.isEmpty) {
      return const Center(child: Text('No B2CS invoices found'));
    }

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: DataTable(
        columns: const [
          DataColumn(label: Text('Invoice No.')),
          DataColumn(label: Text('Date')),
          DataColumn(label: Text('Place of Supply')),
          DataColumn(label: Text('Taxable Value'), numeric: true),
          DataColumn(label: Text('Tax Rate %'), numeric: true),
          DataColumn(label: Text('CGST'), numeric: true),
          DataColumn(label: Text('SGST'), numeric: true),
          DataColumn(label: Text('IGST'), numeric: true),
          DataColumn(label: Text('Total'), numeric: true),
        ],
        rows: _report.b2csInvoices.map((invoice) {
          return DataRow(cells: [
            DataCell(Text(invoice.invoiceNumber)),
            DataCell(Text(DateFormat('dd/MM/yyyy').format(invoice.invoiceDate))),
            DataCell(Text(invoice.placeOfSupply)),
            DataCell(Text(_formatCurrency(invoice.taxableValue))),
            DataCell(Text(invoice.taxRate.toStringAsFixed(2))),
            DataCell(Text(_formatCurrency(invoice.cgst))),
            DataCell(Text(_formatCurrency(invoice.sgst))),
            DataCell(Text(_formatCurrency(invoice.igst))),
            DataCell(Text(_formatCurrency(invoice.total))),
          ]);
        }).toList(),
      ),
    );
  }

  Widget _buildHSNSummaryTable() {
    if (_report.hsnSummary.isEmpty) {
      return const Center(child: Text('No HSN summary available'));
    }

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: DataTable(
        columns: const [
          DataColumn(label: Text('HSN Code')),
          DataColumn(label: Text('Description')),
          DataColumn(label: Text('UQC')),
          DataColumn(label: Text('Qty'), numeric: true),
          DataColumn(label: Text('Taxable Value'), numeric: true),
          DataColumn(label: Text('Tax Rate %'), numeric: true),
          DataColumn(label: Text('CGST'), numeric: true),
          DataColumn(label: Text('SGST'), numeric: true),
          DataColumn(label: Text('IGST'), numeric: true),
          DataColumn(label: Text('Total'), numeric: true),
        ],
        rows: _report.hsnSummary.map((hsn) {
          return DataRow(cells: [
            DataCell(Text(hsn.hsnCode)),
            DataCell(Text(hsn.description)),
            DataCell(Text(hsn.uqc)),
            DataCell(Text(hsn.quantity.toStringAsFixed(2))),
            DataCell(Text(_formatCurrency(hsn.taxableValue))),
            DataCell(Text(hsn.taxRate.toStringAsFixed(2))),
            DataCell(Text(_formatCurrency(hsn.cgst))),
            DataCell(Text(_formatCurrency(hsn.sgst))),
            DataCell(Text(_formatCurrency(hsn.igst))),
            DataCell(Text(_formatCurrency(hsn.total))),
          ]);
        }).toList(),
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

  void _exportToExcel() {
    // TODO: Implement Excel export
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Export to Excel will be implemented soon')),
    );
  }
}
