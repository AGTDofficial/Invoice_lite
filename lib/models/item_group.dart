import 'package:hive/hive.dart';

part 'item_group.g.dart';

@HiveType(typeId: 6)
class ItemGroup extends HiveObject {
  @HiveField(0)
  final String name;
  
  @HiveField(1)
  final String? parentGroup;
  
  @HiveField(2, defaultValue: false)
  final bool isSystemGroup;

  ItemGroup({
    required this.name,
    this.parentGroup,
    this.isSystemGroup = false,
  });

  @override
  String toString() => 'ItemGroup(name: $name, parentGroup: $parentGroup, isSystemGroup: $isSystemGroup)';

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ItemGroup &&
        other.name == name &&
        other.parentGroup == parentGroup &&
        other.isSystemGroup == isSystemGroup;
  }

  @override
  int get hashCode => Object.hash(name, parentGroup, isSystemGroup);
}
