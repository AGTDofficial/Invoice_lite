import 'package:hive/hive.dart';

part 'account.g.dart';

@HiveType(typeId: 4)
class Account extends HiveObject {
  @HiveField(0)
  String name;
  
  @HiveField(1)
  String phone;
  
  @HiveField(2)
  double openingBalance;
  
  @HiveField(3)
  bool isCredit; // true for credit, false for debit

  @HiveField(4, defaultValue: 'Sundry Debtor')
  String group;
  
  @HiveField(5, defaultValue: '')
  String? address;
  
  @HiveField(6, defaultValue: '')
  String? country;
  
  @HiveField(7, defaultValue: '')
  String? state;
  
  @HiveField(8, defaultValue: '')
  String? gstinUin;
  
  @HiveField(9, defaultValue: '')
  String? email;
  
  @HiveField(10, defaultValue: true)
  bool isActive;
  
  @HiveField(11, defaultValue: 0)
  double creditLimit;
  
  @HiveField(12, defaultValue: 0)
  int creditDays;
  
  @HiveField(13, defaultValue: 0)
  double creditAmount;
  
  @HiveField(14, defaultValue: '')
  String? panNumber;
  
  @HiveField(15, defaultValue: 0)
  int colorValue;
  
  @HiveField(16, defaultValue: false)
  bool isCustomer;
  
  @HiveField(17, defaultValue: false)
  bool isSupplier;

  Account({
    required this.name,
    required this.phone,
    this.openingBalance = 0.0,
    this.isCredit = true,
    this.group = 'Sundry Debtor',
    this.address = '',
    this.country = '',
    this.state = '',
    this.gstinUin = '',
    this.email = '',
    this.isActive = true,
    this.creditLimit = 0,
    this.creditDays = 0,
    this.creditAmount = 0,
    this.panNumber = '',
    this.colorValue = 0,
    this.isCustomer = false,
    this.isSupplier = false,
  });

  // Copy with method for easy updates
  Account copyWith({
    String? name,
    String? phone,
    double? openingBalance,
    bool? isCredit,
    String? group,
    String? address,
    String? country,
    String? state,
    String? gstinUin,
    String? email,
    bool? isActive,
    double? creditLimit,
    int? creditDays,
    double? creditAmount,
    String? panNumber,
    int? colorValue,
    bool? isCustomer,
    bool? isSupplier,
  }) {
    return Account(
      name: name ?? this.name,
      phone: phone ?? this.phone,
      openingBalance: openingBalance ?? this.openingBalance,
      isCredit: isCredit ?? this.isCredit,
      group: group ?? this.group,
      address: address ?? this.address,
      country: country ?? this.country,
      state: state ?? this.state,
      gstinUin: gstinUin ?? this.gstinUin,
      email: email ?? this.email,
      isActive: isActive ?? this.isActive,
      creditLimit: creditLimit ?? this.creditLimit,
      creditDays: creditDays ?? this.creditDays,
      creditAmount: creditAmount ?? this.creditAmount,
      panNumber: panNumber ?? this.panNumber,
      colorValue: colorValue ?? this.colorValue,
      isCustomer: isCustomer ?? this.isCustomer,
      isSupplier: isSupplier ?? this.isSupplier,
    );
  }
  
  // Get balance with sign based on debit/credit
  double get balance => isCredit ? -openingBalance : openingBalance;
}
