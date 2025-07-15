import 'package:hive/hive.dart';
import 'package:uuid/uuid.dart';

part 'gst_report_model.g.dart';

@HiveType(typeId: 40)
class GSTR1Report {
  @HiveField(0)
  final String id;
  
  @HiveField(1)
  final DateTime fromDate;
  
  @HiveField(2)
  final DateTime toDate;
  
  @HiveField(3)
  final DateTime generatedAt;
  
  @HiveField(4)
  final List<GSTR1B2B> b2bInvoices;
  
  @HiveField(5)
  final List<GSTR1B2CS> b2csInvoices;
  
  @HiveField(6)
  final List<GSTR1HSNSummary> hsnSummary;

  GSTR1Report({
    String? id,
    required this.fromDate,
    required this.toDate,
    required this.b2bInvoices,
    required this.b2csInvoices,
    required this.hsnSummary,
    DateTime? generatedAt,
  })  : id = id ?? const Uuid().v4(),
        generatedAt = generatedAt ?? DateTime.now();
}

@HiveType(typeId: 41)
class GSTR1B2B {
  @HiveField(0)
  final String invoiceId;
  
  @HiveField(1)
  final String invoiceNumber;
  
  @HiveField(2)
  final DateTime invoiceDate;
  
  @HiveField(3)
  final String customerGSTIN;
  
  @HiveField(4)
  final String customerName;
  
  @HiveField(5)
  final double taxableValue;
  
  @HiveField(6)
  final double cgst;
  
  @HiveField(7)
  final double sgst;
  
  @HiveField(8)
  final double igst;
  
  @HiveField(9)
  final double total;
  
  @HiveField(10)
  final String placeOfSupply;

  GSTR1B2B({
    required this.invoiceId,
    required this.invoiceNumber,
    required this.invoiceDate,
    required this.customerGSTIN,
    required this.customerName,
    required this.taxableValue,
    required this.cgst,
    required this.sgst,
    required this.igst,
    required this.total,
    required this.placeOfSupply,
  });
}

@HiveType(typeId: 42)
class GSTR1B2CS {
  @HiveField(0)
  final String invoiceId;
  
  @HiveField(1)
  final String invoiceNumber;
  
  @HiveField(2)
  final DateTime invoiceDate;
  
  @HiveField(3)
  final String placeOfSupply;
  
  @HiveField(4)
  final double taxableValue;
  
  @HiveField(5)
  final double taxRate;
  
  @HiveField(6)
  final double cgst;
  
  @HiveField(7)
  final double sgst;
  
  @HiveField(8)
  final double igst;
  
  @HiveField(9)
  final double total;

  GSTR1B2CS({
    required this.invoiceId,
    required this.invoiceNumber,
    required this.invoiceDate,
    required this.placeOfSupply,
    required this.taxableValue,
    required this.taxRate,
    required this.cgst,
    required this.sgst,
    required this.igst,
    required this.total,
  });
}

@HiveType(typeId: 43)
class GSTR1HSNSummary {
  @HiveField(0)
  final String hsnCode;
  
  @HiveField(1)
  final String description;
  
  @HiveField(2)
  final String uqc; // Unit Quantity Code
  
  @HiveField(3)
  final double quantity;
  
  @HiveField(4)
  final double taxableValue;
  
  @HiveField(5)
  final double taxRate;
  
  @HiveField(6)
  final double cgst;
  
  @HiveField(7)
  final double sgst;
  
  @HiveField(8)
  final double igst;
  
  @HiveField(9)
  final double total;

  GSTR1HSNSummary({
    required this.hsnCode,
    required this.description,
    required this.uqc,
    required this.quantity,
    required this.taxableValue,
    required this.taxRate,
    required this.cgst,
    required this.sgst,
    required this.igst,
    required this.total,
  });
}

// GSTR-3B Model
@HiveType(typeId: 44)
class GSTR3BReport {
  @HiveField(0)
  final String id;
  
  @HiveField(1)
  final DateTime fromDate;
  
  @HiveField(2)
  final DateTime toDate;
  
  @HiveField(3)
  final DateTime generatedAt;
  
  @HiveField(4)
  final double outwardTaxableValue;
  
  @HiveField(5)
  final double outwardCGST;
  
  @HiveField(6)
  final double outwardSGST;
  
  @HiveField(7)
  final double outwardIGST;
  
  @HiveField(8)
  final double inwardTaxableValue;
  
  @HiveField(9)
  final double inwardCGST;
  
  @HiveField(10)
  final double inwardSGST;
  
  @HiveField(11)
  final double inwardIGST;
  
  @HiveField(12)
  final double taxPayable;
  
  @HiveField(13)
  final double taxPaid;
  
  @HiveField(14)
  final double tdsCredit;
  
  @HiveField(15)
  final double itcAvailable;
  
  @HiveField(16)
  final double itcUtilized;
  
  @HiveField(17)
  final double interestPayable;
  
  @HiveField(18)
  final double lateFeePayable;

  GSTR3BReport({
    String? id,
    required this.fromDate,
    required this.toDate,
    required this.outwardTaxableValue,
    required this.outwardCGST,
    required this.outwardSGST,
    required this.outwardIGST,
    required this.inwardTaxableValue,
    required this.inwardCGST,
    required this.inwardSGST,
    required this.inwardIGST,
    required this.taxPayable,
    required this.taxPaid,
    required this.tdsCredit,
    required this.itcAvailable,
    required this.itcUtilized,
    required this.interestPayable,
    required this.lateFeePayable,
    DateTime? generatedAt,
  })  : id = id ?? const Uuid().v4(),
        generatedAt = generatedAt ?? DateTime.now();
}

// GSTR-2A Reconciliation Model
@HiveType(typeId: 45)
class GSTR2AReconciliation {
  @HiveField(0)
  final String id;
  
  @HiveField(1)
  final DateTime fromDate;
  
  @HiveField(2)
  final DateTime toDate;
  
  @HiveField(3)
  final DateTime generatedAt;
  
  @HiveField(4)
  final List<GSTR2AMatched> matchedInvoices;
  
  @HiveField(5)
  final List<GSTR2AUnmatched> unmatchedInvoices;
  
  @HiveField(6)
  final List<GSTR2AMissing> missingInGSTR2A;

  GSTR2AReconciliation({
    String? id,
    required this.fromDate,
    required this.toDate,
    required this.matchedInvoices,
    required this.unmatchedInvoices,
    required this.missingInGSTR2A,
    DateTime? generatedAt,
  })  : id = id ?? const Uuid().v4(),
        generatedAt = generatedAt ?? DateTime.now();
}

@HiveType(typeId: 46)
class GSTR2AMatched {
  @HiveField(0)
  final String invoiceId;
  
  @HiveField(1)
  final String invoiceNumber;
  
  @HiveField(2)
  final DateTime invoiceDate;
  
  @HiveField(3)
  final String supplierGSTIN;
  
  @HiveField(4)
  final double taxableValue;
  
  @HiveField(5)
  final double cgst;
  
  @HiveField(6)
  final double sgst;
  
  @HiveField(7)
  final double igst;
  
  @HiveField(8)
  final double total;
  
  @HiveField(9)
  final String status; // Matched, Mismatched, Pending

  GSTR2AMatched({
    required this.invoiceId,
    required this.invoiceNumber,
    required this.invoiceDate,
    required this.supplierGSTIN,
    required this.taxableValue,
    required this.cgst,
    required this.sgst,
    required this.igst,
    required this.total,
    required this.status,
  });
}

@HiveType(typeId: 47)
class GSTR2AUnmatched {
  @HiveField(0)
  final String invoiceId;
  
  @HiveField(1)
  final String invoiceNumber;
  
  @HiveField(2)
  final DateTime invoiceDate;
  
  @HiveField(3)
  final String supplierGSTIN;
  
  @HiveField(4)
  final double taxableValue;
  
  @HiveField(5)
  final double cgst;
  
  @HiveField(6)
  final double sgst;
  
  @HiveField(7)
  final double igst;
  
  @HiveField(8)
  final double total;
  
  @HiveField(9)
  final String reason; // Mismatch reason

  GSTR2AUnmatched({
    required this.invoiceId,
    required this.invoiceNumber,
    required this.invoiceDate,
    required this.supplierGSTIN,
    required this.taxableValue,
    required this.cgst,
    required this.sgst,
    required this.igst,
    required this.total,
    required this.reason,
  });
}

@HiveType(typeId: 48)
class GSTR2AMissing {
  @HiveField(0)
  final String invoiceNumber;
  
  @HiveField(1)
  final DateTime invoiceDate;
  
  @HiveField(2)
  final String supplierGSTIN;
  
  @HiveField(3)
  final double taxableValue;
  
  @HiveField(4)
  final double taxAmount;
  
  @HiveField(5)
  final String source; // Books or GSTR-2A

  GSTR2AMissing({
    required this.invoiceNumber,
    required this.invoiceDate,
    required this.supplierGSTIN,
    required this.taxableValue,
    required this.taxAmount,
    required this.source,
  });
}
