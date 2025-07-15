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
      dealerType: fields[8] as String?,
      gstinUin: fields[9] == null ? '' : fields[9] as String?,
      email: fields[10] == null ? '' : fields[10] as String?,
      isActive: fields[11] == null ? true : fields[11] as bool,
      colorValue: fields[12] == null ? 0 : fields[12] as int,
      isCustomer: fields[13] == null ? false : fields[13] as bool,
      isSupplier: fields[14] == null ? false : fields[14] as bool,
    );
  }

  @override
  void write(BinaryWriter writer, Account obj) {
    writer
      ..writeByte(15)
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
      ..write(obj.dealerType)
      ..writeByte(9)
      ..write(obj.gstinUin)
      ..writeByte(10)
      ..write(obj.email)
      ..writeByte(11)
      ..write(obj.isActive)
      ..writeByte(12)
      ..write(obj.colorValue)
      ..writeByte(13)
      ..write(obj.isCustomer)
      ..writeByte(14)
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
