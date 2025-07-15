// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'gst_report_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class GSTR1ReportAdapter extends TypeAdapter<GSTR1Report> {
  @override
  final int typeId = 40;

  @override
  GSTR1Report read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return GSTR1Report(
      id: fields[0] as String?,
      fromDate: fields[1] as DateTime,
      toDate: fields[2] as DateTime,
      b2bInvoices: (fields[4] as List).cast<GSTR1B2B>(),
      b2csInvoices: (fields[5] as List).cast<GSTR1B2CS>(),
      hsnSummary: (fields[6] as List).cast<GSTR1HSNSummary>(),
      generatedAt: fields[3] as DateTime?,
    );
  }

  @override
  void write(BinaryWriter writer, GSTR1Report obj) {
    writer
      ..writeByte(7)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.fromDate)
      ..writeByte(2)
      ..write(obj.toDate)
      ..writeByte(3)
      ..write(obj.generatedAt)
      ..writeByte(4)
      ..write(obj.b2bInvoices)
      ..writeByte(5)
      ..write(obj.b2csInvoices)
      ..writeByte(6)
      ..write(obj.hsnSummary);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is GSTR1ReportAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class GSTR1B2BAdapter extends TypeAdapter<GSTR1B2B> {
  @override
  final int typeId = 41;

  @override
  GSTR1B2B read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return GSTR1B2B(
      invoiceId: fields[0] as String,
      invoiceNumber: fields[1] as String,
      invoiceDate: fields[2] as DateTime,
      customerGSTIN: fields[3] as String,
      customerName: fields[4] as String,
      taxableValue: fields[5] as double,
      cgst: fields[6] as double,
      sgst: fields[7] as double,
      igst: fields[8] as double,
      total: fields[9] as double,
      placeOfSupply: fields[10] as String,
    );
  }

  @override
  void write(BinaryWriter writer, GSTR1B2B obj) {
    writer
      ..writeByte(11)
      ..writeByte(0)
      ..write(obj.invoiceId)
      ..writeByte(1)
      ..write(obj.invoiceNumber)
      ..writeByte(2)
      ..write(obj.invoiceDate)
      ..writeByte(3)
      ..write(obj.customerGSTIN)
      ..writeByte(4)
      ..write(obj.customerName)
      ..writeByte(5)
      ..write(obj.taxableValue)
      ..writeByte(6)
      ..write(obj.cgst)
      ..writeByte(7)
      ..write(obj.sgst)
      ..writeByte(8)
      ..write(obj.igst)
      ..writeByte(9)
      ..write(obj.total)
      ..writeByte(10)
      ..write(obj.placeOfSupply);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is GSTR1B2BAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class GSTR1B2CSAdapter extends TypeAdapter<GSTR1B2CS> {
  @override
  final int typeId = 42;

  @override
  GSTR1B2CS read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return GSTR1B2CS(
      invoiceId: fields[0] as String,
      invoiceNumber: fields[1] as String,
      invoiceDate: fields[2] as DateTime,
      placeOfSupply: fields[3] as String,
      taxableValue: fields[4] as double,
      taxRate: fields[5] as double,
      cgst: fields[6] as double,
      sgst: fields[7] as double,
      igst: fields[8] as double,
      total: fields[9] as double,
    );
  }

  @override
  void write(BinaryWriter writer, GSTR1B2CS obj) {
    writer
      ..writeByte(10)
      ..writeByte(0)
      ..write(obj.invoiceId)
      ..writeByte(1)
      ..write(obj.invoiceNumber)
      ..writeByte(2)
      ..write(obj.invoiceDate)
      ..writeByte(3)
      ..write(obj.placeOfSupply)
      ..writeByte(4)
      ..write(obj.taxableValue)
      ..writeByte(5)
      ..write(obj.taxRate)
      ..writeByte(6)
      ..write(obj.cgst)
      ..writeByte(7)
      ..write(obj.sgst)
      ..writeByte(8)
      ..write(obj.igst)
      ..writeByte(9)
      ..write(obj.total);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is GSTR1B2CSAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class GSTR1HSNSummaryAdapter extends TypeAdapter<GSTR1HSNSummary> {
  @override
  final int typeId = 43;

  @override
  GSTR1HSNSummary read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return GSTR1HSNSummary(
      hsnCode: fields[0] as String,
      description: fields[1] as String,
      uqc: fields[2] as String,
      quantity: fields[3] as double,
      taxableValue: fields[4] as double,
      taxRate: fields[5] as double,
      cgst: fields[6] as double,
      sgst: fields[7] as double,
      igst: fields[8] as double,
      total: fields[9] as double,
    );
  }

  @override
  void write(BinaryWriter writer, GSTR1HSNSummary obj) {
    writer
      ..writeByte(10)
      ..writeByte(0)
      ..write(obj.hsnCode)
      ..writeByte(1)
      ..write(obj.description)
      ..writeByte(2)
      ..write(obj.uqc)
      ..writeByte(3)
      ..write(obj.quantity)
      ..writeByte(4)
      ..write(obj.taxableValue)
      ..writeByte(5)
      ..write(obj.taxRate)
      ..writeByte(6)
      ..write(obj.cgst)
      ..writeByte(7)
      ..write(obj.sgst)
      ..writeByte(8)
      ..write(obj.igst)
      ..writeByte(9)
      ..write(obj.total);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is GSTR1HSNSummaryAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class GSTR3BReportAdapter extends TypeAdapter<GSTR3BReport> {
  @override
  final int typeId = 44;

  @override
  GSTR3BReport read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return GSTR3BReport(
      id: fields[0] as String?,
      fromDate: fields[1] as DateTime,
      toDate: fields[2] as DateTime,
      outwardTaxableValue: fields[4] as double,
      outwardCGST: fields[5] as double,
      outwardSGST: fields[6] as double,
      outwardIGST: fields[7] as double,
      inwardTaxableValue: fields[8] as double,
      inwardCGST: fields[9] as double,
      inwardSGST: fields[10] as double,
      inwardIGST: fields[11] as double,
      taxPayable: fields[12] as double,
      taxPaid: fields[13] as double,
      tdsCredit: fields[14] as double,
      itcAvailable: fields[15] as double,
      itcUtilized: fields[16] as double,
      interestPayable: fields[17] as double,
      lateFeePayable: fields[18] as double,
      generatedAt: fields[3] as DateTime?,
    );
  }

  @override
  void write(BinaryWriter writer, GSTR3BReport obj) {
    writer
      ..writeByte(19)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.fromDate)
      ..writeByte(2)
      ..write(obj.toDate)
      ..writeByte(3)
      ..write(obj.generatedAt)
      ..writeByte(4)
      ..write(obj.outwardTaxableValue)
      ..writeByte(5)
      ..write(obj.outwardCGST)
      ..writeByte(6)
      ..write(obj.outwardSGST)
      ..writeByte(7)
      ..write(obj.outwardIGST)
      ..writeByte(8)
      ..write(obj.inwardTaxableValue)
      ..writeByte(9)
      ..write(obj.inwardCGST)
      ..writeByte(10)
      ..write(obj.inwardSGST)
      ..writeByte(11)
      ..write(obj.inwardIGST)
      ..writeByte(12)
      ..write(obj.taxPayable)
      ..writeByte(13)
      ..write(obj.taxPaid)
      ..writeByte(14)
      ..write(obj.tdsCredit)
      ..writeByte(15)
      ..write(obj.itcAvailable)
      ..writeByte(16)
      ..write(obj.itcUtilized)
      ..writeByte(17)
      ..write(obj.interestPayable)
      ..writeByte(18)
      ..write(obj.lateFeePayable);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is GSTR3BReportAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class GSTR2AReconciliationAdapter extends TypeAdapter<GSTR2AReconciliation> {
  @override
  final int typeId = 45;

  @override
  GSTR2AReconciliation read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return GSTR2AReconciliation(
      id: fields[0] as String?,
      fromDate: fields[1] as DateTime,
      toDate: fields[2] as DateTime,
      matchedInvoices: (fields[4] as List).cast<GSTR2AMatched>(),
      unmatchedInvoices: (fields[5] as List).cast<GSTR2AUnmatched>(),
      missingInGSTR2A: (fields[6] as List).cast<GSTR2AMissing>(),
      generatedAt: fields[3] as DateTime?,
    );
  }

  @override
  void write(BinaryWriter writer, GSTR2AReconciliation obj) {
    writer
      ..writeByte(7)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.fromDate)
      ..writeByte(2)
      ..write(obj.toDate)
      ..writeByte(3)
      ..write(obj.generatedAt)
      ..writeByte(4)
      ..write(obj.matchedInvoices)
      ..writeByte(5)
      ..write(obj.unmatchedInvoices)
      ..writeByte(6)
      ..write(obj.missingInGSTR2A);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is GSTR2AReconciliationAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class GSTR2AMatchedAdapter extends TypeAdapter<GSTR2AMatched> {
  @override
  final int typeId = 46;

  @override
  GSTR2AMatched read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return GSTR2AMatched(
      invoiceId: fields[0] as String,
      invoiceNumber: fields[1] as String,
      invoiceDate: fields[2] as DateTime,
      supplierGSTIN: fields[3] as String,
      taxableValue: fields[4] as double,
      cgst: fields[5] as double,
      sgst: fields[6] as double,
      igst: fields[7] as double,
      total: fields[8] as double,
      status: fields[9] as String,
    );
  }

  @override
  void write(BinaryWriter writer, GSTR2AMatched obj) {
    writer
      ..writeByte(10)
      ..writeByte(0)
      ..write(obj.invoiceId)
      ..writeByte(1)
      ..write(obj.invoiceNumber)
      ..writeByte(2)
      ..write(obj.invoiceDate)
      ..writeByte(3)
      ..write(obj.supplierGSTIN)
      ..writeByte(4)
      ..write(obj.taxableValue)
      ..writeByte(5)
      ..write(obj.cgst)
      ..writeByte(6)
      ..write(obj.sgst)
      ..writeByte(7)
      ..write(obj.igst)
      ..writeByte(8)
      ..write(obj.total)
      ..writeByte(9)
      ..write(obj.status);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is GSTR2AMatchedAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class GSTR2AUnmatchedAdapter extends TypeAdapter<GSTR2AUnmatched> {
  @override
  final int typeId = 47;

  @override
  GSTR2AUnmatched read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return GSTR2AUnmatched(
      invoiceId: fields[0] as String,
      invoiceNumber: fields[1] as String,
      invoiceDate: fields[2] as DateTime,
      supplierGSTIN: fields[3] as String,
      taxableValue: fields[4] as double,
      cgst: fields[5] as double,
      sgst: fields[6] as double,
      igst: fields[7] as double,
      total: fields[8] as double,
      reason: fields[9] as String,
    );
  }

  @override
  void write(BinaryWriter writer, GSTR2AUnmatched obj) {
    writer
      ..writeByte(10)
      ..writeByte(0)
      ..write(obj.invoiceId)
      ..writeByte(1)
      ..write(obj.invoiceNumber)
      ..writeByte(2)
      ..write(obj.invoiceDate)
      ..writeByte(3)
      ..write(obj.supplierGSTIN)
      ..writeByte(4)
      ..write(obj.taxableValue)
      ..writeByte(5)
      ..write(obj.cgst)
      ..writeByte(6)
      ..write(obj.sgst)
      ..writeByte(7)
      ..write(obj.igst)
      ..writeByte(8)
      ..write(obj.total)
      ..writeByte(9)
      ..write(obj.reason);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is GSTR2AUnmatchedAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class GSTR2AMissingAdapter extends TypeAdapter<GSTR2AMissing> {
  @override
  final int typeId = 48;

  @override
  GSTR2AMissing read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return GSTR2AMissing(
      invoiceNumber: fields[0] as String,
      invoiceDate: fields[1] as DateTime,
      supplierGSTIN: fields[2] as String,
      taxableValue: fields[3] as double,
      taxAmount: fields[4] as double,
      source: fields[5] as String,
    );
  }

  @override
  void write(BinaryWriter writer, GSTR2AMissing obj) {
    writer
      ..writeByte(6)
      ..writeByte(0)
      ..write(obj.invoiceNumber)
      ..writeByte(1)
      ..write(obj.invoiceDate)
      ..writeByte(2)
      ..write(obj.supplierGSTIN)
      ..writeByte(3)
      ..write(obj.taxableValue)
      ..writeByte(4)
      ..write(obj.taxAmount)
      ..writeByte(5)
      ..write(obj.source);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is GSTR2AMissingAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
