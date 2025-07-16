import 'package:hive/hive.dart';

part 'invoice_item.g.dart';

@HiveType(typeId: 5)
class InvoiceItem extends HiveObject {
  @HiveField(0)
  String name;

  @HiveField(1)
  String? hsnCode;

  @HiveField(2)
  double quantity;

  @HiveField(3)
  String unit;

  @HiveField(4)
  double price;

  @HiveField(5)
  double taxRate;
  
  @HiveField(6)
  String taxType; // GST, IGST, Exempt, Tax Incl.

  @HiveField(7)
  double discount; // Changed from double? to double with default 0.0

  @HiveField(8)
  double cgst;

  @HiveField(9)
  double sgst;

  @HiveField(10)
  double igst;
  
  @HiveField(11)
  bool isTaxInclusive; // Whether tax is included in the price

  @HiveField(12)
  String? returnReason;

  @HiveField(13)
  String? originalInvoiceItemId;
  
  @HiveField(14)
  bool isFreeItem;

  @HiveField(15)
  String? originalItemKey;

  InvoiceItem({
    required this.name,
    this.hsnCode,
    required this.quantity,
    required this.unit,
    required this.price,
    required this.taxRate,
    this.taxType = 'GST', // Default to GST
    this.discount = 0.0,
    this.isFreeItem = false,
    this.isTaxInclusive = false,
    this.cgst = 0.0,
    this.sgst = 0.0,
    this.igst = 0.0,
    this.returnReason,
    this.originalInvoiceItemId,
  });

  // Copy with method for creating modified copies
  InvoiceItem copyWith({
    String? name,
    String? hsnCode,
    double? quantity,
    String? unit,
    double? price,
    double? taxRate,
    String? taxType,
    double? discount,
    double? cgst,
    double? sgst,
    double? igst,
    String? returnReason,
    String? originalInvoiceItemId,
    bool? isFreeItem,
    bool? isTaxInclusive,
  }) {
    return InvoiceItem(
      name: name ?? this.name,
      hsnCode: hsnCode ?? this.hsnCode,
      quantity: quantity ?? this.quantity.toDouble(),
      unit: unit ?? this.unit,
      price: price ?? this.price,
      taxRate: taxRate ?? this.taxRate,
      taxType: taxType ?? this.taxType,
      discount: discount ?? this.discount,
      cgst: cgst ?? this.cgst,
      sgst: sgst ?? this.sgst,
      igst: igst ?? this.igst,
      returnReason: returnReason ?? this.returnReason,
      originalInvoiceItemId: originalInvoiceItemId ?? this.originalInvoiceItemId,
      isFreeItem: isFreeItem ?? this.isFreeItem,
      isTaxInclusive: isTaxInclusive ?? this.isTaxInclusive,
    );
  }

  double get taxableValue => quantity * price;
  double get taxAmount => cgst + sgst + igst;
  double get total => (taxableValue + taxAmount - discount).clamp(0, double.infinity);

  /// Applies GST based on the tax type and whether it's an intra-state transaction
  /// [isIntraState] true for within same state, false for inter-state
  void applyGST(bool isIntraState) {
    // Reset all taxes first
    cgst = 0.0;
    sgst = 0.0;
    igst = 0.0;
    
    // Skip tax calculation for free items or exempt items
    if (isFreeItem || taxType == 'Exempt') {
      return;
    }
    
    double taxableValue = quantity * price;
    double calculatedTax = 0.0;
    
    // Handle tax inclusive pricing
    if (isTaxInclusive) {
      // Calculate the pre-tax amount
      double rate = taxRate / 100;
      double preTaxAmount = taxableValue / (1 + rate);
      calculatedTax = taxableValue - preTaxAmount;
      taxableValue = preTaxAmount;
    } else {
      calculatedTax = (taxableValue * taxRate) / 100;
    }
    
    // Apply tax based on tax type and transaction type
    if (taxType == 'IGST' || !isIntraState) {
      // For IGST or inter-state transactions, use IGST
      igst = calculatedTax;
    } else if (taxType == 'GST' && isIntraState) {
      // For GST and intra-state, split into CGST and SGST
      cgst = calculatedTax / 2;
      sgst = calculatedTax / 2;
    }
    // For 'Exempt' or other cases, tax remains 0
  }
}
