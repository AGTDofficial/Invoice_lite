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
      quantity: fields[1] as double,
      unit: fields[2] as String,
      price: fields[3] as double,
      discount: fields[4] as double,
      returnReason: fields[5] as String?,
      originalInvoiceItemId: fields[6] as String?,
      isFreeItem: fields[7] as bool,
      originalItemKey: fields[8] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, InvoiceItem obj) {
    writer
      ..writeByte(9)
      ..writeByte(0)
      ..write(obj.name)
      ..writeByte(1)
      ..write(obj.quantity)
      ..writeByte(2)
      ..write(obj.unit)
      ..writeByte(3)
      ..write(obj.price)
      ..writeByte(4)
      ..write(obj.discount)
      ..writeByte(5)
      ..write(obj.returnReason)
      ..writeByte(6)
      ..write(obj.originalInvoiceItemId)
      ..writeByte(7)
      ..write(obj.isFreeItem)
      ..writeByte(8)
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
