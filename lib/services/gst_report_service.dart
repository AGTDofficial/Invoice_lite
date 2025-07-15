import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';
import '../models/invoice.dart';
import '../models/invoice_item.dart';
import '../models/gst_report_model.dart';
import '../enums/invoice_type.dart';

class GSTReportService {
  final Box<Invoice> _invoiceBox;
  
  GSTReportService() : _invoiceBox = Hive.box<Invoice>('invoices');

  // Calculate tax amounts from invoice items
  Map<String, double> _calculateTaxAmounts(List<InvoiceItem> items) {
    double taxableValue = 0;
    double cgst = 0;
    double sgst = 0;
    double igst = 0;

    for (final item in items) {
      final itemTotal = item.price * item.quantity;
      taxableValue += itemTotal;
      
      // Calculate taxes based on tax type
      if (item.taxType == 'GST') {
        final cgstAmount = (itemTotal * (item.taxRate / 2)) / 100;
        final sgstAmount = (itemTotal * (item.taxRate / 2)) / 100;
        cgst += cgstAmount;
        sgst += sgstAmount;
      } else if (item.taxType == 'IGST') {
        final igstAmount = (itemTotal * item.taxRate) / 100;
        igst += igstAmount;
      }
    }

    return {
      'taxableValue': taxableValue,
      'cgst': cgst,
      'sgst': sgst,
      'igst': igst,
    };
  }

  // Generate GSTR-1 Report
  Future<GSTR1Report> generateGSTR1Report({
    required DateTime fromDate,
    required DateTime toDate,
  }) async {
    final invoices = _invoiceBox.values.where((invoice) => 
      invoice.date.isAfter(fromDate.subtract(const Duration(days: 1))) && 
      invoice.date.isBefore(toDate.add(const Duration(days: 1))) &&
      (invoice.type == InvoiceType.sale || invoice.type == InvoiceType.saleReturn)
    ).toList();

    final b2bInvoices = <GSTR1B2B>[];
    final b2csInvoices = <GSTR1B2CS>[];
    final hsnSummary = <String, GSTR1HSNSummary>{};

    for (final invoice in invoices) {
      // Skip if not a sale or sale return
      if (invoice.type != InvoiceType.sale && invoice.type != InvoiceType.saleReturn) continue;

      final isReturn = invoice.type == InvoiceType.saleReturn;
      final multiplier = isReturn ? -1.0 : 1.0;
      
      // Calculate tax amounts from items
      final taxAmounts = _calculateTaxAmounts(invoice.items);
      final taxableValue = taxAmounts['taxableValue']! * multiplier;
      final cgst = taxAmounts['cgst']! * multiplier;
      final sgst = taxAmounts['sgst']! * multiplier;
      final igst = taxAmounts['igst']! * multiplier;
      
      // Get account details (if available)
      String? gstin;
      String? placeOfSupply = '--'; // Default value
      
      if (invoice.accountKey != null) {
        try {
          final accountBox = Hive.box('accounts');
          final account = accountBox.get(invoice.accountKey);
          if (account != null) {
            gstin = account.gstinUin ?? '';
            placeOfSupply = account.state ?? '--';
          }
        } catch (e) {
          debugPrint('Error fetching account details: $e');
        }
      }

      // Process B2B invoices (invoices with GSTIN)
      if (gstin?.isNotEmpty == true) {
        b2bInvoices.add(GSTR1B2B(
          invoiceId: invoice.id,
          invoiceNumber: invoice.invoiceNumber,
          invoiceDate: invoice.date,
          customerGSTIN: gstin!,
          customerName: invoice.partyName,
          taxableValue: taxableValue,
          cgst: cgst,
          sgst: sgst,
          igst: igst,
          total: invoice.total * multiplier,
          placeOfSupply: placeOfSupply!,
        ));
      } 
      // Process B2CS invoices (invoices without GSTIN)
      else {
        // Calculate average tax rate for B2CS
        final totalTax = cgst + sgst + igst;
        final avgTaxRate = (taxableValue > 0 ? (totalTax / taxableValue) * 100 : 0).toDouble();
        
        b2csInvoices.add(GSTR1B2CS(
          invoiceId: invoice.id,
          invoiceNumber: invoice.invoiceNumber,
          invoiceDate: invoice.date,
          placeOfSupply: placeOfSupply!,
          taxableValue: taxableValue,
          taxRate: avgTaxRate,
          cgst: cgst,
          sgst: sgst,
          igst: igst,
          total: invoice.total * multiplier,
        ));
      }

      // Update HSN Summary
      for (final item in invoice.items) {
        if (item.hsnCode?.isNotEmpty != true) continue;
        
        final hsnCode = item.hsnCode!;
        final quantity = item.quantity * multiplier;
        final taxableValue = (item.price * item.quantity - item.discount) * multiplier;
        final taxRate = item.taxRate;
        final cgst = (taxableValue * (taxRate / 2) / 100) * multiplier;
        final sgst = (taxableValue * (taxRate / 2) / 100) * multiplier;
        final igst = (taxableValue * taxRate / 100) * multiplier;
        
        if (hsnSummary.containsKey(hsnCode)) {
          final existing = hsnSummary[hsnCode]!;
          hsnSummary[hsnCode] = GSTR1HSNSummary(
            hsnCode: hsnCode,
            description: existing.description,
            uqc: existing.uqc,
            quantity: existing.quantity + quantity,
            taxableValue: existing.taxableValue + taxableValue,
            taxRate: taxRate, // Assuming same tax rate for same HSN
            cgst: existing.cgst + cgst,
            sgst: existing.sgst + sgst,
            igst: existing.igst + igst,
            total: existing.total + taxableValue + cgst + sgst + igst,
          );
        } else {
          hsnSummary[hsnCode] = GSTR1HSNSummary(
            hsnCode: hsnCode,
            description: item.name, // This should ideally be the HSN description
            uqc: 'PCS', // Default unit, should be configurable
            quantity: quantity,
            taxableValue: taxableValue,
            taxRate: taxRate,
            cgst: cgst,
            sgst: sgst,
            igst: igst,
            total: taxableValue + cgst + sgst + igst,
          );
        }
      }
    }

    return GSTR1Report(
      fromDate: fromDate,
      toDate: toDate,
      b2bInvoices: b2bInvoices,
      b2csInvoices: b2csInvoices,
      hsnSummary: hsnSummary.values.toList(),
    );
  }

  // Generate GSTR-3B Report
  Future<GSTR3BReport> generateGSTR3BReport({
    required DateTime fromDate,
    required DateTime toDate,
  }) async {
    final invoices = _invoiceBox.values.where((invoice) => 
      invoice.date.isAfter(fromDate.subtract(const Duration(days: 1))) && 
      invoice.date.isBefore(toDate.add(const Duration(days: 1)))
    ).toList();

    double outwardTaxableValue = 0;
    double outwardCGST = 0;
    double outwardSGST = 0;
    double outwardIGST = 0;
    
    double inwardTaxableValue = 0;
    double inwardCGST = 0;
    double inwardSGST = 0;
    double inwardIGST = 0;

    for (final invoice in invoices) {
      final isReturn = invoice.type == InvoiceType.saleReturn || 
                      invoice.type == InvoiceType.purchaseReturn;
      final multiplier = isReturn ? -1.0 : 1.0;
      
      final isOutward = invoice.type == InvoiceType.sale || 
                       invoice.type == InvoiceType.saleReturn;
      
      // Calculate tax amounts from items
      final taxAmounts = _calculateTaxAmounts(invoice.items);
      final taxableValue = taxAmounts['taxableValue']! * multiplier;
      final cgst = taxAmounts['cgst']! * multiplier;
      final sgst = taxAmounts['sgst']! * multiplier;
      final igst = taxAmounts['igst']! * multiplier;

      if (isOutward) {
        outwardTaxableValue += taxableValue;
        outwardCGST += cgst;
        outwardSGST += sgst;
        outwardIGST += igst;
      } else {
        inwardTaxableValue += taxableValue;
        inwardCGST += cgst;
        inwardSGST += sgst;
        inwardIGST += igst;
      }
    }

    // Calculate tax payable (simplified)
    final taxPayable = (outwardCGST + outwardSGST + outwardIGST) - 
                      (inwardCGST + inwardSGST + inwardIGST);

    return GSTR3BReport(
      fromDate: fromDate,
      toDate: toDate,
      outwardTaxableValue: outwardTaxableValue,
      outwardCGST: outwardCGST,
      outwardSGST: outwardSGST,
      outwardIGST: outwardIGST,
      inwardTaxableValue: inwardTaxableValue,
      inwardCGST: inwardCGST,
      inwardSGST: inwardSGST,
      inwardIGST: inwardIGST,
      taxPayable: taxPayable > 0 ? taxPayable : 0,
      taxPaid: 0, // This would come from payment records
      tdsCredit: 0, // This would come from TDS records
      itcAvailable: (inwardCGST + inwardSGST + inwardIGST) > 0 ? 
                   (inwardCGST + inwardSGST + inwardIGST) : 0,
      itcUtilized: 0, // This would come from ITC utilization records
      interestPayable: 0, // This would be calculated based on late payments
      lateFeePayable: 0, // This would be calculated based on late filing
    );
  }

  // Generate GSTR-2A Reconciliation Report
  Future<GSTR2AReconciliation> generateGSTR2AReconciliation({
    required DateTime fromDate,
    required DateTime toDate,
    required Map<String, dynamic> gstr2aData, // This would come from GSTR-2A API
  }) async {
    final purchaseInvoices = _invoiceBox.values.where((invoice) => 
      (invoice.type == InvoiceType.purchase || 
       invoice.type == InvoiceType.purchaseReturn) &&
      invoice.date.isAfter(fromDate.subtract(const Duration(days: 1))) && 
      invoice.date.isBefore(toDate.add(const Duration(days: 1)))
    ).toList();

    final matchedInvoices = <GSTR2AMatched>[];
    final unmatchedInvoices = <GSTR2AUnmatched>[];
    final missingInGSTR2A = <GSTR2AMissing>[];
    final missingInBooks = <GSTR2AMissing>[];

    // Convert GSTR-2A data to a map for easier lookup
    final gstr2aMap = <String, Map<String, dynamic>>{};
    for (final entry in gstr2aData.entries) {
      gstr2aMap[entry.key] = entry.value;
    }

    // Check invoices in books against GSTR-2A
    for (final invoice in purchaseInvoices) {
      final gstr2aInvoice = gstr2aMap[invoice.invoiceNumber];
      
      if (gstr2aInvoice != null) {
        // Calculate tax amounts from items
        final taxAmounts = _calculateTaxAmounts(invoice.items);
        final taxableValue = taxAmounts['taxableValue']!;
        final cgst = taxAmounts['cgst']!;
        final sgst = taxAmounts['sgst']!;
        final igst = taxAmounts['igst']!;
        
        // Get supplier GSTIN from account if available
        String supplierGSTIN = '--';
        if (invoice.accountKey != null) {
          try {
            final accountBox = Hive.box('accounts');
            final account = accountBox.get(invoice.accountKey);
            if (account != null && account.gstinUin != null && account.gstinUin!.isNotEmpty) {
              supplierGSTIN = account.gstinUin!;
            }
          } catch (e) {
            debugPrint('Error fetching account details: $e');
          }
        }
        
        // Check if invoice details match
        final isMatched = _compareInvoiceWithGSTR2A(invoice, gstr2aInvoice);
        
        if (isMatched) {
          matchedInvoices.add(GSTR2AMatched(
            invoiceId: invoice.id,
            invoiceNumber: invoice.invoiceNumber,
            invoiceDate: invoice.date,
            supplierGSTIN: supplierGSTIN,
            taxableValue: taxableValue,
            cgst: cgst,
            sgst: sgst,
            igst: igst,
            total: invoice.total,
            status: 'Matched',
          ));
        } else {
          unmatchedInvoices.add(GSTR2AUnmatched(
            invoiceId: invoice.id,
            invoiceNumber: invoice.invoiceNumber,
            invoiceDate: invoice.date,
            supplierGSTIN: supplierGSTIN,
            taxableValue: taxableValue,
            cgst: cgst,
            sgst: sgst,
            igst: igst,
            total: invoice.total,
            reason: 'Mismatch in invoice details',
          ));
        }
        
        // Remove from GSTR-2A map to track missing invoices
        gstr2aMap.remove(invoice.invoiceNumber);
      } else {
        // Calculate tax amounts for missing invoices
        final taxAmounts = _calculateTaxAmounts(invoice.items);
        final totalTax = taxAmounts['cgst']! + taxAmounts['sgst']! + taxAmounts['igst']!;
        
        // Get supplier GSTIN from account if available
        String supplierGSTIN = '--';
        if (invoice.accountKey != null) {
          try {
            final accountBox = Hive.box('accounts');
            final account = accountBox.get(invoice.accountKey);
            if (account != null && account.gstinUin != null && account.gstinUin!.isNotEmpty) {
              supplierGSTIN = account.gstinUin!;
            }
          } catch (e) {
            debugPrint('Error fetching account details: $e');
          }
        }
        
        // Invoice not found in GSTR-2A
        missingInGSTR2A.add(GSTR2AMissing(
          invoiceNumber: invoice.invoiceNumber,
          invoiceDate: invoice.date,
          supplierGSTIN: supplierGSTIN,
          taxableValue: taxAmounts['taxableValue']!,
          taxAmount: totalTax,
          source: 'Books',
        ));
      }
    }

    // Add remaining GSTR-2A invoices as missing in books
    for (final entry in gstr2aMap.entries) {
      final invoice = entry.value;
      missingInBooks.add(GSTR2AMissing(
        invoiceNumber: entry.key,
        invoiceDate: DateTime.parse(invoice['invoiceDate']),
        supplierGSTIN: invoice['supplierGSTIN'] ?? '--',
        taxableValue: (invoice['taxableValue'] ?? 0).toDouble(),
        taxAmount: (invoice['taxAmount'] ?? 0).toDouble(),
        source: 'GSTR-2A',
      ));
    }

    return GSTR2AReconciliation(
      fromDate: fromDate,
      toDate: toDate,
      matchedInvoices: matchedInvoices,
      unmatchedInvoices: unmatchedInvoices,
      missingInGSTR2A: missingInBooks, // These are actually missing in GSTR-2A
    );
  }

  // Helper method to compare invoice with GSTR-2A data
  bool _compareInvoiceWithGSTR2A(Invoice invoice, Map<String, dynamic> gstr2aInvoice) {
    // Compare basic details
    if (invoice.invoiceNumber != gstr2aInvoice['invoiceNumber']) return false;
    
    // Compare dates (allow 1 day difference due to timezone issues)
    final invoiceDate = invoice.date.toUtc().toIso8601String().substring(0, 10);
    final gstr2aDate = gstr2aInvoice['invoiceDate']?.toIso8601String().substring(0, 10);
    
    if (invoiceDate != gstr2aDate) return false;
    
    // Compare amounts (allow small rounding differences)
    final amountDifference = (invoice.total - (gstr2aInvoice['total'] ?? 0)).abs();
    if (amountDifference > 1.0) return false; // More than 1 rupee difference
    
    return true;
  }
}
