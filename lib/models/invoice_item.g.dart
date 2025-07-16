// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'invoice_item.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class InvoiceItemAdapter extends TypeAdapter<InvoiceItem> {
  @override
  final int typeId = 5;

  @override
  InvoiceItem read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return InvoiceItem(
      name: fields[0] as String,
      hsnCode: fields[1] as String?,
      quantity: fields[2] as double,
      unit: fields[3] as String,
      price: fields[4] as double,
      taxRate: fields[5] as double,
      taxType: fields[6] as String,
      discount: fields[7] as double,
      isFreeItem: fields[14] as bool,
      isTaxInclusive: fields[11] as bool,
      cgst: fields[8] as double,
      sgst: fields[9] as double,
      igst: fields[10] as double,
      returnReason: fields[12] as String?,
      originalInvoiceItemId: fields[13] as String?,
    )..originalItemKey = fields[15] as String?;
  }

  @override
  void write(BinaryWriter writer, InvoiceItem obj) {
    writer
      ..writeByte(16)
      ..writeByte(0)
      ..write(obj.name)
      ..writeByte(1)
      ..write(obj.hsnCode)
      ..writeByte(2)
      ..write(obj.quantity)
      ..writeByte(3)
      ..write(obj.unit)
      ..writeByte(4)
      ..write(obj.price)
      ..writeByte(5)
      ..write(obj.taxRate)
      ..writeByte(6)
      ..write(obj.taxType)
      ..writeByte(7)
      ..write(obj.discount)
      ..writeByte(8)
      ..write(obj.cgst)
      ..writeByte(9)
      ..write(obj.sgst)
      ..writeByte(10)
      ..write(obj.igst)
      ..writeByte(11)
      ..write(obj.isTaxInclusive)
      ..writeByte(12)
      ..write(obj.returnReason)
      ..writeByte(13)
      ..write(obj.originalInvoiceItemId)
      ..writeByte(14)
      ..write(obj.isFreeItem)
      ..writeByte(15)
      ..write(obj.originalItemKey);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is InvoiceItemAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
