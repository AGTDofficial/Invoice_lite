import 'package:hive/hive.dart';

part 'company.g.dart';

@HiveType(typeId: 2)
class Company extends HiveObject {
  @HiveField(0)
  String name;

  @HiveField(1)
  String address;

  @HiveField(2)
  String gstin;

  @HiveField(3)
  DateTime financialYearStart;

  @HiveField(4)
  String mobileNumber;

  @HiveField(5)
  String businessState;

  @HiveField(6)
  String dealerType;
  
  @HiveField(7, defaultValue: true)
  bool isRegistered;
  
  @HiveField(8)
  String? businessType;
  
  @HiveField(9)
  String email;
  
  @HiveField(12)
  String pincode;
  
  Company({
    required this.name,
    required this.address,
    required this.gstin,
    required this.financialYearStart,
    required this.mobileNumber,
    required this.businessState,
    required this.dealerType,
    required this.email,
    required this.pincode,
    this.isRegistered = true,
    this.businessType,
  });
}
