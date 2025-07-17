import 'package:hive/hive.dart';
import 'invoice_item.dart';
import '../enums/invoice_type.dart';

part 'invoice.g.dart';

@HiveType(typeId: 3)
class Invoice extends HiveObject {
  @HiveField(0)
  String id;

  @HiveField(1)
  InvoiceType type; // Invoice type (purchase, sale, return, etc.)

  @HiveField(2)
  String partyName;
  
  @HiveField(3)
  int? accountKey; // Reference to Account in Hive

  @HiveField(4)
  DateTime date;

  @HiveField(5)
  String invoiceNumber;

  @HiveField(6)
  List<InvoiceItem> items;

  @HiveField(7)
  double total;

  @HiveField(8)
  String? notes;

  @HiveField(9)
  double discount;

  @HiveField(10)
  double roundOff;

  @HiveField(11)
  String? saleType; // Sale, Purchase, Sale Return, Purchase Return

  @HiveField(12)
  String? originalInvoiceNumber;

  @HiveField(13)
  bool isReturn;

  @HiveField(14)
  DateTime? dueDate;

  Invoice({
    required this.id,
    required this.type,
    required this.partyName,
    required this.date,
    required this.invoiceNumber,
    required this.items,
    required this.total,
    this.notes,
    this.discount = 0.0,
    this.roundOff = 0.0,
    this.saleType,
    this.originalInvoiceNumber,
    this.isReturn = false,
    this.accountKey,
    this.dueDate,
  });

  Invoice copyWith({
    String? id,
    InvoiceType? type,
    String? partyName,
    DateTime? date,
    String? invoiceNumber,
    List<InvoiceItem>? items,
    double? total,
    String? notes,
    double? discount,
    double? roundOff,
    String? saleType,
    String? originalInvoiceNumber,
    bool? isReturn,
    int? accountKey,
    DateTime? dueDate,
  }) {
    return Invoice(
      id: id ?? this.id,
      type: type ?? this.type,
      partyName: partyName ?? this.partyName,
      date: date ?? this.date,
      invoiceNumber: invoiceNumber ?? this.invoiceNumber,
      items: items ?? this.items,
      total: total ?? this.total,
      notes: notes ?? this.notes,
      discount: discount ?? this.discount,
      roundOff: roundOff ?? this.roundOff,
      saleType: saleType ?? this.saleType,
      originalInvoiceNumber: originalInvoiceNumber ?? this.originalInvoiceNumber,
      isReturn: isReturn ?? this.isReturn,
      accountKey: accountKey ?? this.accountKey,
      dueDate: dueDate ?? this.dueDate,
    );
  }

  // Helper method to get the subtotal amount (before discount)
  double get subtotal {
    return items.fold(0, (sum, item) => sum + (item.price * item.quantity));
  }

  // Helper method to calculate total after discount
  double get totalAfterDiscount {
    return (subtotal - discount).clamp(0, double.infinity);
  }
}
