import 'package:hive/hive.dart';

part 'party.g.dart';

@HiveType(typeId: 5)
class Party extends HiveObject {
  @HiveField(0)
  String name;

  @HiveField(1)
  String type; // 'customer' or 'supplier'

  @HiveField(2)
  String? gstin;

  @HiveField(3)
  String? phone;

  @HiveField(4)
  String? address;

  Party({
    required this.name,
    required this.type,
    this.gstin,
    this.phone,
    this.address,
  });
}
