import 'dart:io';
import 'package:flutter/material.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

/// Handles PDF generation and sharing for invoices

Future<void> generateAndShareInvoicePdf({
  required String invoiceNumber,
  required String partyName,
  required DateTime date,
  required List<Map<String, dynamic>> items,
  required double totalAmount,
  double? discount,
  double? roundOff,
  double? taxAmount,
  String? notes,
  String? companyName = 'MY COMPANY',
  String? gstin = '22XXXXXXXZ5',
  String? phone = '9876543210',
}) async {
  final pdf = pw.Document();

  pdf.addPage(
    pw.Page(
      pageFormat: PdfPageFormat.a4,
      build: (context) {
        return pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Center(
                child: pw.Text(companyName!,
                    style: pw.TextStyle(
                        fontSize: 20, fontWeight: pw.FontWeight.bold))),
            pw.SizedBox(height: 4),
            pw.Center(child: pw.Text('GSTIN: $gstin')),
            pw.Center(child: pw.Text('Phone: $phone')),
            pw.Divider(),
            pw.Text('Invoice #: $invoiceNumber'),
            pw.Text('Date: ${_formatDate(date)}'),
            pw.Text('Customer: $partyName'),
            pw.SizedBox(height: 10),
            _buildItemsTable(items),
            pw.SizedBox(height: 10),
            _buildSummary(discount, taxAmount, roundOff, totalAmount),
            if (notes != null) pw.SizedBox(height: 10),
            if (notes != null) pw.Text('Notes: $notes'),
            pw.Divider(),
            pw.Center(child: pw.Text('Thank you for your business!')),
          ],
        );
      },
    ),
  );

  final output = await getTemporaryDirectory();
  final filePath = "${output.path}/invoice_$invoiceNumber.pdf";
  final file = File(filePath);
  await file.writeAsBytes(await pdf.save());

  try {
    // Share the generated PDF using SharePlus
    await Share.shareXFiles(
      [XFile(filePath)],
      text: 'Invoice $invoiceNumber from $companyName',
      subject: 'Invoice $invoiceNumber',
    );
  } catch (e) {
    debugPrint('Error sharing file: $e');
    rethrow; // Re-throw to allow calling function to handle the error
  }
}

String _formatDate(DateTime date) {
  return '${date.day.toString().padLeft(2, '0')}-${date.month.toString().padLeft(2, '0')}-${date.year}';
}

pw.Widget _buildItemsTable(List<Map<String, dynamic>> items) {
  return pw.TableHelper.fromTextArray(
    headers: ['Item', 'Qty', 'Rate', 'Amount'],
    data: items.map((item) {
      final amount = item['price'] * item['quantity'];
      return [
        item['itemName'],
        '${item['quantity']}',
        'â‚¹${item['price'].toStringAsFixed(2)}',
        'â‚¹${amount.toStringAsFixed(2)}',
      ];
    }).toList(),
  );
}

pw.Widget _buildSummary(
    double? discount, double? taxAmount, double? roundOff, double totalAmount) {
  return pw.Column(
    crossAxisAlignment: pw.CrossAxisAlignment.end,
    children: [
      if (discount != null && discount > 0)
        pw.Text('Discount: â‚¹${discount.toStringAsFixed(2)}'),
      if (taxAmount != null && taxAmount > 0)
        pw.Text('Tax: â‚¹${taxAmount.toStringAsFixed(2)}'),
      if (roundOff != null && roundOff != 0)
        pw.Text('Round Off: â‚¹${roundOff.toStringAsFixed(2)}'),
      pw.SizedBox(height: 4),
      pw.Text(
        'Total: â‚¹${totalAmount.toStringAsFixed(2)}',
        style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 14),
      ),
    ],
  );
}
