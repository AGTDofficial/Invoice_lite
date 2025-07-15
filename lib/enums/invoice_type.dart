import 'package:hive/hive.dart';

part 'invoice_type.g.dart';

@HiveType(typeId: 100)
enum InvoiceType {
  @HiveField(0)
  purchase('PUR', 'Purchase Invoice'),
  @HiveField(1)
  purchaseReturn('PRET', 'Purchase Return'),
  @HiveField(2)
  sale('SALE', 'Sales Invoice'),
  @HiveField(3)
  saleReturn('SRET', 'Sales Return');

  final String code;
  final String displayName;

  const InvoiceType(this.code, this.displayName);

  @override
  String toString() => displayName;
}
