import 'package:hive/hive.dart';

part 'invoice_item.g.dart';

@HiveType(typeId: 5)
class InvoiceItem extends HiveObject {
  @HiveField(0)
  String name;

  @HiveField(1)
  double quantity;

  @HiveField(2)
  String unit;

  @HiveField(3)
  double price;

  @HiveField(4)
  double discount;

  @HiveField(5)
  String? returnReason;

  @HiveField(6)
  String? originalInvoiceItemId;
  
  @HiveField(7)
  bool isFreeItem;

  @HiveField(8)
  String? originalItemKey;

  InvoiceItem({
    required this.name,
    required this.quantity,
    required this.unit,
    required this.price,
    this.discount = 0.0,
    this.returnReason,
    this.originalInvoiceItemId,
    this.isFreeItem = false,
    this.originalItemKey,
  });

  // Copy with method for creating modified copies
  InvoiceItem copyWith({
    String? name,
    double? quantity,
    String? unit,
    double? price,
    double? discount,
    String? returnReason,
    String? originalInvoiceItemId,
    bool? isFreeItem,
    String? originalItemKey,
  }) {
    return InvoiceItem(
      name: name ?? this.name,
      quantity: quantity ?? this.quantity,
      unit: unit ?? this.unit,
      price: price ?? this.price,
      discount: discount ?? this.discount,
      returnReason: returnReason ?? this.returnReason,
      originalInvoiceItemId: originalInvoiceItemId ?? this.originalInvoiceItemId,
      isFreeItem: isFreeItem ?? this.isFreeItem,
      originalItemKey: originalItemKey ?? this.originalItemKey,
    );
  }

  double get total => (price * quantity) - discount;
  
  // No tax calculations needed
  double get taxAmount => 0.0;
  
  double get totalWithTax => total;
}
