// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'company.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class CompanyAdapter extends TypeAdapter<Company> {
  @override
  final int typeId = 2;

  @override
  Company read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Company(
      name: fields[0] as String,
      address: fields[1] as String,
      gstin: fields[2] as String,
      financialYearStart: fields[3] as DateTime,
      mobileNumber: fields[4] as String,
      businessState: fields[5] as String,
      dealerType: fields[6] as String,
      email: fields[9] as String,
      pincode: fields[12] as String,
      isRegistered: fields[7] == null ? true : fields[7] as bool,
      businessType: fields[8] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, Company obj) {
    writer
      ..writeByte(11)
      ..writeByte(0)
      ..write(obj.name)
      ..writeByte(1)
      ..write(obj.address)
      ..writeByte(2)
      ..write(obj.gstin)
      ..writeByte(3)
      ..write(obj.financialYearStart)
      ..writeByte(4)
      ..write(obj.mobileNumber)
      ..writeByte(5)
      ..write(obj.businessState)
      ..writeByte(6)
      ..write(obj.dealerType)
      ..writeByte(7)
      ..write(obj.isRegistered)
      ..writeByte(8)
      ..write(obj.businessType)
      ..writeByte(9)
      ..write(obj.email)
      ..writeByte(12)
      ..write(obj.pincode);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CompanyAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
