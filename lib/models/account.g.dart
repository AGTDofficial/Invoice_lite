// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'account.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class AccountAdapter extends TypeAdapter<Account> {
  @override
  final int typeId = 4;

  @override
  Account read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Account(
      name: fields[0] as String,
      phone: fields[1] as String,
      openingBalance: fields[2] as double,
      isCredit: fields[3] as bool,
      group: fields[4] == null ? 'Sundry Debtor' : fields[4] as String,
      address: fields[5] == null ? '' : fields[5] as String?,
      country: fields[6] == null ? '' : fields[6] as String?,
      state: fields[7] == null ? '' : fields[7] as String?,
      gstinUin: fields[8] == null ? '' : fields[8] as String?,
      email: fields[9] == null ? '' : fields[9] as String?,
      isActive: fields[10] == null ? true : fields[10] as bool,
      creditLimit: fields[11] == null ? 0 : fields[11] as double,
      creditDays: fields[12] == null ? 0 : fields[12] as int,
      creditAmount: fields[13] == null ? 0 : fields[13] as double,
      panNumber: fields[14] == null ? '' : fields[14] as String?,
      colorValue: fields[15] == null ? 0 : fields[15] as int,
      isCustomer: fields[16] == null ? false : fields[16] as bool,
      isSupplier: fields[17] == null ? false : fields[17] as bool,
    );
  }

  @override
  void write(BinaryWriter writer, Account obj) {
    writer
      ..writeByte(18)
      ..writeByte(0)
      ..write(obj.name)
      ..writeByte(1)
      ..write(obj.phone)
      ..writeByte(2)
      ..write(obj.openingBalance)
      ..writeByte(3)
      ..write(obj.isCredit)
      ..writeByte(4)
      ..write(obj.group)
      ..writeByte(5)
      ..write(obj.address)
      ..writeByte(6)
      ..write(obj.country)
      ..writeByte(7)
      ..write(obj.state)
      ..writeByte(8)
      ..write(obj.gstinUin)
      ..writeByte(9)
      ..write(obj.email)
      ..writeByte(10)
      ..write(obj.isActive)
      ..writeByte(11)
      ..write(obj.creditLimit)
      ..writeByte(12)
      ..write(obj.creditDays)
      ..writeByte(13)
      ..write(obj.creditAmount)
      ..writeByte(14)
      ..write(obj.panNumber)
      ..writeByte(15)
      ..write(obj.colorValue)
      ..writeByte(16)
      ..write(obj.isCustomer)
      ..writeByte(17)
      ..write(obj.isSupplier);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AccountAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
