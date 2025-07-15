import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../services/gst_report_service.dart';
import '../../models/gst_report_model.dart';

class GSTR2AReconciliationScreen extends StatefulWidget {
  final DateTime fromDate;
  final DateTime toDate;

  const GSTR2AReconciliationScreen({
    Key? key,
    required this.fromDate,
    required this.toDate,
  }) : super(key: key);

  @override
  _GSTR2AReconciliationScreenState createState() => _GSTR2AReconciliationScreenState();
}

class _GSTR2AReconciliationScreenState extends State<GSTR2AReconciliationScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isLoading = true;
  late GSTR2AReconciliation _report;
  final GSTReportService _reportService = GSTReportService();
  final Map<String, dynamic> _gstr2aData = {}; // This would come from GSTR-2A API

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
      final report = await _reportService.generateGSTR2AReconciliation(
        fromDate: widget.fromDate,
        toDate: widget.toDate,
        gstr2aData: _gstr2aData,
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
          title: const Text('GSTR-2A Reconciliation'),
          bottom: TabBar(
            controller: _tabController,
            tabs: const [
              Tab(text: 'Matched'),
              Tab(text: 'Mismatched'),
              Tab(text: 'Missing'),
            ],
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: _loadReport,
              tooltip: 'Refresh',
            ),
            IconButton(
              icon: const Icon(Icons.help_outline),
              onPressed: _showHelpDialog,
              tooltip: 'Help',
            ),
          ],
        ),
        body: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : TabBarView(
                controller: _tabController,
                children: [
                  _buildMatchedInvoices(),
                  _buildMismatchedInvoices(),
                  _buildMissingInvoices(),
                ],
              ),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: _uploadGSTR2A,
          icon: const Icon(Icons.upload_file),
          label: const Text('Upload GSTR-2A'),
        ),
      ),
    );
  }

  Widget _buildMatchedInvoices() {
    if (_report.matchedInvoices.isEmpty) {
      return const Center(child: Text('No matched invoices found'));
    }

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: DataTable(
        columns: const [
          DataColumn(label: Text('Invoice No.')),
          DataColumn(label: Text('Date')),
          DataColumn(label: Text('Supplier GSTIN')),
          DataColumn(label: Text('Taxable Value'), numeric: true),
          DataColumn(label: Text('CGST'), numeric: true),
          DataColumn(label: Text('SGST'), numeric: true),
          DataColumn(label: Text('IGST'), numeric: true),
          DataColumn(label: Text('Total'), numeric: true),
          DataColumn(label: Text('Status')),
        ],
        rows: _report.matchedInvoices.map((invoice) {
          return DataRow(
            cells: [
              DataCell(Text(invoice.invoiceNumber)),
              DataCell(Text(DateFormat('dd/MM/yyyy').format(invoice.invoiceDate))),
              DataCell(Text(invoice.supplierGSTIN)),
              DataCell(Text(_formatCurrency(invoice.taxableValue))),
              DataCell(Text(_formatCurrency(invoice.cgst))),
              DataCell(Text(_formatCurrency(invoice.sgst))),
              DataCell(Text(_formatCurrency(invoice.igst))),
              DataCell(Text(_formatCurrency(invoice.total))),
              DataCell(
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.green[100],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    invoice.status,
                    style: const TextStyle(color: Colors.green),
                  ),
                ),
              ),
            ],
          );
        }).toList(),
      ),
    );
  }

  Widget _buildMismatchedInvoices() {
    if (_report.unmatchedInvoices.isEmpty) {
      return const Center(child: Text('No mismatched invoices found'));
    }

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: DataTable(
        columns: const [
          DataColumn(label: Text('Invoice No.')),
          DataColumn(label: Text('Date')),
          DataColumn(label: Text('Supplier GSTIN')),
          DataColumn(label: Text('Taxable Value'), numeric: true),
          DataColumn(label: Text('Total'), numeric: true),
          DataColumn(label: Text('Reason')),
          DataColumn(label: Text('Action')),
        ],
        rows: _report.unmatchedInvoices.map((invoice) {
          return DataRow(
            cells: [
              DataCell(Text(invoice.invoiceNumber)),
              DataCell(Text(DateFormat('dd/MM/yyyy').format(invoice.invoiceDate))),
              DataCell(Text(invoice.supplierGSTIN)),
              DataCell(Text(_formatCurrency(invoice.taxableValue))),
              DataCell(Text(_formatCurrency(invoice.total))),
              DataCell(
                Tooltip(
                  message: invoice.reason,
                  child: Text(
                    invoice.reason.length > 20
                        ? '${invoice.reason.substring(0, 20)}...'
                        : invoice.reason,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
              DataCell(
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.edit, size: 20),
                      onPressed: () => _editInvoice(invoice.invoiceId),
                      tooltip: 'Edit',
                    ),
                    IconButton(
                      icon: const Icon(Icons.visibility, size: 20),
                      onPressed: () => _viewDetails(invoice.invoiceId),
                      tooltip: 'View Details',
                    ),
                  ],
                ),
              ),
            ],
          );
        }).toList(),
      ),
    );
  }

  Widget _buildMissingInvoices() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: DataTable(
        columns: const [
          DataColumn(label: Text('Invoice No.')),
          DataColumn(label: Text('Date')),
          DataColumn(label: Text('Supplier GSTIN')),
          DataColumn(label: Text('Taxable Value'), numeric: true),
          DataColumn(label: Text('Tax Amount'), numeric: true),
          DataColumn(label: Text('Source')),
          DataColumn(label: Text('Action')),
        ],
        rows: _report.missingInGSTR2A.map((invoice) => _buildMissingInvoiceRow(invoice, 'GSTR-2A')).toList(),
      ),
    );
  }

  DataRow _buildMissingInvoiceRow(GSTR2AMissing invoice, String source) {
    return DataRow(
      cells: [
        DataCell(Text(invoice.invoiceNumber)),
        DataCell(Text(DateFormat('dd/MM/yyyy').format(invoice.invoiceDate))),
        DataCell(Text(invoice.supplierGSTIN)),
        DataCell(Text(_formatCurrency(invoice.taxableValue))),
        DataCell(Text(_formatCurrency(invoice.taxAmount))),
        DataCell(
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: source == 'Books' ? Colors.orange[100] : Colors.blue[100],
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              source,
              style: TextStyle(
                color: source == 'Books' ? Colors.orange[800] : Colors.blue[800],
              ),
            ),
          ),
        ),
        DataCell(
          Row(
            children: [
              if (source == 'GSTR-2A')
                TextButton(
                  onPressed: () => _importFromGSTR2A(invoice),
                  child: const Text('Import'),
                ),
              if (source == 'Books')
                TextButton(
                  onPressed: () => _markAsReconciled(invoice),
                  child: const Text('Mark as Reconciled'),
                ),
            ],
          ),
        ),
      ],
    );
  }

  String _formatCurrency(double amount) {
    return '₹${amount.toStringAsFixed(2)}';
  }

  void _uploadGSTR2A() {
    // TODO: Implement GSTR-2A upload
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Upload GSTR-2A'),
        content: const Text('This feature will allow you to upload your GSTR-2A JSON file.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              // TODO: Implement file picker and processing
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('GSTR-2A upload will be implemented soon')),
              );
            },
            child: const Text('Upload'),
          ),
        ],
      ),
    );
  }

  void _editInvoice(String invoiceId) {
    // TODO: Implement edit invoice
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Edit invoice will be implemented soon')),
    );
  }

  void _viewDetails(String invoiceId) {
    // TODO: Implement view details
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('View details will be implemented soon')),
    );
  }

  void _importFromGSTR2A(GSTR2AMissing invoice) {
    // TODO: Implement import from GSTR-2A
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Import from GSTR-2A will be implemented soon')),
    );
  }

  void _markAsReconciled(GSTR2AMissing invoice) {
    // TODO: Implement mark as reconciled
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Mark as reconciled will be implemented soon')),
    );
  }

  void _showHelpDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('GSTR-2A Reconciliation Help'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: const [
              Text(
                'Matched Invoices',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              Text(
                  '• Invoices that match between your books and GSTR-2A'),
              SizedBox(height: 12),
              Text(
                'Mismatched Invoices',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              Text(
                  '• Invoices with discrepancies between your books and GSTR-2A\n• Click the edit icon to correct the invoice'),
              SizedBox(height: 12),
              Text(
                'Missing Invoices',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              Text(
                  '• Invoices in your books but not in GSTR-2A (marked as Books)\n• Invoices in GSTR-2A but not in your books (marked as GSTR-2A)'),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
}
