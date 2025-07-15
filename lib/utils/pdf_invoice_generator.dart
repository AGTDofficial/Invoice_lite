import 'dart:typed_data';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import '../models/invoice.dart';

Future<Uint8List> generateInvoicePdf(Invoice invoice) async {
  final pdf = pw.Document();

  pdf.addPage(
    pw.Page(
      pageFormat: PdfPageFormat.a4,
      build: (context) {
        return pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text('INVOICE', style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold)),
            pw.SizedBox(height: 10),
            pw.Text('Invoice No: ${invoice.invoiceNumber}'),
            pw.Text('Date: ${invoice.date.toLocal().toString().split(' ')[0]}'),
            pw.Text('Party: ${invoice.partyName}'),
            pw.Text('Type: ${invoice.type}'),
            pw.Text('Tax Type: ${invoice.taxType}'),
            pw.SizedBox(height: 20),
            pw.TableHelper.fromTextArray(
              headers: ['Item', 'HSN', 'Qty', 'Unit', 'Rate', 'Tax%', 'Disc', 'Total'],
              data: invoice.items.map((item) {
                return [
                  item.name,
                  item.hsnCode ?? '',
                  item.quantity.toString(),
                  item.unit,
                  item.price.toStringAsFixed(2),
                  item.taxRate.toStringAsFixed(2),
                  item.discount.toStringAsFixed(2),
                  item.total.toStringAsFixed(2),
                ];
              }).toList(),
            ),
            pw.Divider(),
            pw.Align(
              alignment: pw.Alignment.centerRight,
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.end,
                children: [
                  if (invoice.discount != null)
                    pw.Text('Discount: ₹${invoice.discount!.toStringAsFixed(2)}'),
                  if (invoice.totalTaxAmount != null)
                    pw.Text('Tax: ₹${invoice.totalTaxAmount!.toStringAsFixed(2)}'),
                  if (invoice.roundOff != null)
                    pw.Text('Round Off: ₹${invoice.roundOff!.toStringAsFixed(2)}'),
                  pw.Text('Total: ₹${invoice.total.toStringAsFixed(2)}', style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold)),
                ],
              ),
            ),
          ],
        );
      },
    ),
  );

  return pdf.save();
} 