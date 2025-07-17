// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'invoice.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class InvoiceAdapter extends TypeAdapter<Invoice> {
  @override
  final int typeId = 3;

  @override
  Invoice read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Invoice(
      id: fields[0] as String,
      type: fields[1] as InvoiceType,
      partyName: fields[2] as String,
      date: fields[4] as DateTime,
      invoiceNumber: fields[5] as String,
      items: (fields[6] as List).cast<InvoiceItem>(),
      total: fields[7] as double,
      notes: fields[8] as String?,
      discount: fields[9] as double,
      roundOff: fields[10] as double,
      saleType: fields[11] as String?,
      originalInvoiceNumber: fields[12] as String?,
      isReturn: fields[13] as bool,
      accountKey: fields[3] as int?,
      dueDate: fields[14] as DateTime?,
    );
  }

  @override
  void write(BinaryWriter writer, Invoice obj) {
    writer
      ..writeByte(15)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.type)
      ..writeByte(2)
      ..write(obj.partyName)
      ..writeByte(3)
      ..write(obj.accountKey)
      ..writeByte(4)
      ..write(obj.date)
      ..writeByte(5)
      ..write(obj.invoiceNumber)
      ..writeByte(6)
      ..write(obj.items)
      ..writeByte(7)
      ..write(obj.total)
      ..writeByte(8)
      ..write(obj.notes)
      ..writeByte(9)
      ..write(obj.discount)
      ..writeByte(10)
      ..write(obj.roundOff)
      ..writeByte(11)
      ..write(obj.saleType)
      ..writeByte(12)
      ..write(obj.originalInvoiceNumber)
      ..writeByte(13)
      ..write(obj.isReturn)
      ..writeByte(14)
      ..write(obj.dueDate);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is InvoiceAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
