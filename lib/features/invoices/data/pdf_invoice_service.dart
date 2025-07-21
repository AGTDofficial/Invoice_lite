import 'dart:io';
import 'dart:typed_data';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:invoice_lite/features/invoices/data/invoice_model.dart';
import 'package:invoice_lite/features/customers/data/customer_model.dart';
import 'package:invoice_lite/features/items/data/item_model.dart';

import '../../../core/database/database.dart';

class PdfInvoiceService {
  static final PdfInvoiceService _instance = PdfInvoiceService._internal();
  factory PdfInvoiceService() => _instance;
  PdfInvoiceService._internal();

  // Generate and save PDF invoice
  Future<File> generateInvoice({
    required Invoice invoice,
    required Customer customer,
    required List<InvoiceItem> items,
  }) async {
    final pdf = pw.Document();
    
    // Add invoice content
    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (context) => [
          _buildHeader(invoice),
          pw.SizedBox(height: 30),
          _buildCustomerInfo(customer),
          pw.SizedBox(height: 30),
          _buildInvoiceItemsTable(items),
          pw.SizedBox(height: 30),
          _buildTotals(invoice),
          pw.SizedBox(height: 30),
          _buildFooter(),
        ],
      ),
    );

    // Get the application documents directory
    final output = await getTemporaryDirectory();
    final file = File('${output.path}/invoice_${invoice.invoiceNumber.replaceAll('/', '_')}.pdf');
    
    // Save the PDF file
    await file.writeAsBytes(await pdf.save());
    return file;
  }

  // Share the generated PDF
  Future<void> shareInvoice(File pdfFile) async {
    await Share.shareFiles(
      [pdfFile.path],
      mimeTypes: ['application/pdf'],
      subject: 'Invoice ${pdfFile.path.split('/').last}',
    );
  }

  // Header with company info and invoice details
  pw.Widget _buildHeader(Invoice invoice) {
    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        // Company Info
        pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text(
              'Your Company Name',
              style: pw.TextStyle(
                fontSize: 24,
                fontWeight: pw.FontWeight.bold,
              ),
            ),
            pw.Text('123 Business Street'),
            pw.Text('Mumbai, 400001, India'),
            pw.Text('GSTIN: 22AAAAA0000A1Z5'),
            pw.Text('+91 98765 43210'),
          ],
        ),
        
        // Invoice Info
        pw.Container(
          padding: const pw.EdgeInsets.all(16),
          decoration: pw.BoxDecoration(
            border: pw.Border.all(color: PdfColors.grey300),
            borderRadius: const pw.BorderRadius.all(pw.Radius.circular(6)),
          ),
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.end,
            children: [
              pw.Text(
                'INVOICE',
                style: pw.TextStyle(
                  fontSize: 24,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.SizedBox(height: 10),
              _buildInfoRow('Invoice #', invoice.invoiceNumber),
              _buildInfoRow('Date', _formatDate(invoice.invoiceDate)),
              if (invoice.dueDate != null)
                _buildInfoRow('Due Date', _formatDate(invoice.dueDate!)),
            ],
          ),
        ),
      ],
    );
  }

  // Customer information section
  pw.Widget _buildCustomerInfo(Customer customer) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          'Bill To',
          style: pw.TextStyle(
            fontSize: 14,
            fontWeight: pw.FontWeight.bold,
          ),
        ),
        pw.SizedBox(height: 8),
        pw.Text(customer.name, style: const pw.TextStyle(fontWeight: pw.FontWeight.bold)),
        if (customer.email != null) pw.Text(customer.email!),
        if (customer.phone != null) pw.Text(customer.phone!),
        if (customer.address != null) pw.Text(customer.address!),
        if (customer.city != null) 
          pw.Text([
            customer.city,
            if (customer.state != null) ', ${customer.state}',
            if (customer.country != null) ', ${customer.country}',
          ].join()),
        if (customer.pinCode?.isNotEmpty ?? false) 
          pw.Text('PIN: ${customer.pinCode}'),
        if (customer.taxId?.isNotEmpty ?? false) 
          pw.Text('GSTIN: ${customer.taxId}'),
      ],
    );
  }

  // Invoice items table
  pw.Widget _buildInvoiceItemsTable(List<InvoiceItem> items) {
    return pw.TableHelper.fromTextArray(
      border: null,
      cellAlignment: pw.Alignment.centerLeft,
      headerDecoration: pw.BoxDecoration(
        color: PdfColors.grey200,
        borderRadius: const pw.BorderRadius.vertical(top: pw.Radius.circular(4)),
      ),
      headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 11),
      headerPadding: const pw.EdgeInsets.all(8),
      cellPadding: const pw.EdgeInsets.all(8),
      cellStyle: const pw.TextStyle(fontSize: 10),
      rowDecoration: pw.BoxDecoration(
        border: pw.Border(bottom: pw.BorderSide(color: PdfColors.grey300)),
      ),
      headers: ['#', 'Description', 'Qty', 'Rate', 'Amount'],
      data: List<List<dynamic>>.generate(
        items.length,
        (index) => [
          '${index + 1}',
          items[index].description.isNotEmpty 
              ? items[index].description 
              : 'Item ${index + 1}',
          items[index].quantity.toStringAsFixed(2),
          _formatCurrency(items[index].unitPrice),
          _formatCurrency(items[index].total),
        ],
      ),
    );
  }

  // Invoice totals section
  pw.Widget _buildTotals(Invoice invoice) {
    return pw.Container(
      alignment: pw.Alignment.centerRight,
      child: pw.SizedBox(
        width: 200,
        child: pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.end,
          children: [
            _buildTotalRow('Subtotal', invoice.subtotal),
            if (invoice.discountAmount > 0)
              _buildTotalRow('Discount', -invoice.discountAmount, isDiscount: true),
            if (invoice.taxAmount > 0)
              _buildTotalRow('Tax', invoice.taxAmount),
            _buildTotalRow(
              'Total',
              invoice.total,
              isTotal: true,
            ),
          ],
        ),
      ),
    );
  }

  // Footer with terms and conditions
  pw.Widget _buildFooter() {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          'Terms & Conditions',
          style: pw.TextStyle(
            fontSize: 10,
            fontWeight: pw.FontWeight.bold,
          ),
        ),
        pw.SizedBox(height: 4),
        pw.Text(
          '1. Payment is due within 15 days of invoice date.\n'
          '2. Please include the invoice number in your payment.\n'
          '3. Late payments are subject to a 2% monthly interest charge.\n'
          '4. All amounts are in Indian Rupees (₹).',
          style: const pw.TextStyle(fontSize: 9),
        ),
        pw.SizedBox(height: 20),
        pw.Text(
          'Thank you for your business!',
          style: pw.TextStyle(
            fontSize: 10,
            fontWeight: pw.FontWeight.bold,
          ),
        ),
      ],
    );
  }

  // Helper to build info rows with label and value
  pw.Widget _buildInfoRow(String label, String value) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 2),
      child: pw.Row(
        mainAxisSize: pw.MainAxisSize.min,
        children: [
          pw.SizedBox(
            width: 70,
            child: pw.Text(
              label,
              style: const pw.TextStyle(fontSize: 9),
            ),
          ),
          pw.Text(
            ': $value',
            style: const pw.TextStyle(fontSize: 9),
          ),
        ],
      ),
    );
  }

  // Helper to build total rows
  pw.Widget _buildTotalRow(String label, double amount, {bool isTotal = false, bool isDiscount = false}) {
    return pw.Container(
      padding: const pw.EdgeInsets.symmetric(vertical: 4, horizontal: 8),
      decoration: isTotal
          ? pw.BoxDecoration(
              border: pw.Border.all(color: PdfColors.grey300),
              borderRadius: const pw.BorderRadius.all(pw.Radius.circular(4)),
            )
          : null,
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(
            label,
            style: pw.TextStyle(
              fontSize: isTotal ? 11 : 10,
              fontWeight: isTotal ? pw.FontWeight.bold : null,
            ),
          ),
          pw.Text(
            '₹${amount.toStringAsFixed(2)}',
            style: pw.TextStyle(
              fontSize: isTotal ? 11 : 10,
              fontWeight: isTotal ? pw.FontWeight.bold : null,
            ),
          ),
        ],
      ),
    );
  }

  // Format date to dd/MM/yyyy
  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }

  // Format currency with Indian Rupee symbol
  String _formatCurrency(double amount) {
    return '₹${amount.toStringAsFixed(2)}';
  }
}
