import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';
import 'package:invoice_lite/features/invoices/data/invoice_model.dart';
import 'package:invoice_lite/features/invoices/data/pdf_invoice_service.dart';
import 'package:invoice_lite/features/customers/data/customer_model.dart';
import 'package:invoice_lite/features/items/data/item_model.dart';

class InvoiceActions extends ConsumerWidget {
  final Invoice invoice;
  final Customer customer;
  final List<InvoiceItem> items;
  final VoidCallback? onPrintComplete;
  final bool isLoading;

  const InvoiceActions({
    super.key,
    required this.invoice,
    required this.customer,
    required this.items,
    this.onPrintComplete,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pdfService = PdfInvoiceService();

    Future<void> _handleGeneratePdf() async {
      try {
        // Show loading indicator
        final scaffoldMessenger = ScaffoldMessenger.of(context);
        
        // Generate and save PDF
        final pdfFile = await pdfService.generateInvoice(
          invoice: invoice,
          customer: customer,
          items: items,
        );

        // Share the PDF
        await pdfService.shareInvoice(pdfFile);
        
        if (onPrintComplete != null) {
          onPrintComplete!();
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to generate PDF: $e')),
          );
        }
      }
    }

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _buildActionButton(
          icon: Icons.picture_as_pdf,
          label: 'PDF',
          onPressed: _handleGeneratePdf,
          isLoading: isLoading,
        ),
        _buildActionButton(
          icon: Icons.share,
          label: 'Share',
          onPressed: _handleGeneratePdf, // Same as PDF for now
          isLoading: isLoading,
        ),
        _buildActionButton(
          icon: Icons.print,
          label: 'Print',
          onPressed: _handleGeneratePdf, // Will open print dialog
          isLoading: isLoading,
        ),
      ],
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onPressed,
    bool isLoading = false,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton.filledTonal(
          icon: isLoading ? const CircularProgressIndicator() : Icon(icon),
          onPressed: isLoading ? null : onPressed,
          tooltip: label,
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: Theme.of(context).textTheme.labelSmall,
        ),
      ],
    );
  }
}
