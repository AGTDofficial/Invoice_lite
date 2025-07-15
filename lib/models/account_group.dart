import 'package:hive/hive.dart';

part 'account_group.g.dart';

@HiveType(typeId: 1)
class AccountGroup extends HiveObject {
  @HiveField(0)
  String name;

  @HiveField(1)
  String? parentGroup;

  @HiveField(2)
  String categoryType; // 'Assets', 'Liabilities', 'Income', 'Expenses'

  @HiveField(3)
  bool isInventoryRelated;

  @HiveField(4)
  bool isSystemGroup;

  AccountGroup({
    required String name,
    String? parentGroup,
    String? categoryType,
    bool? isInventoryRelated,
    bool? isSystemGroup,
  }) : name = name,
       parentGroup = parentGroup,
       categoryType = categoryType ?? 'Assets',
       isInventoryRelated = isInventoryRelated ?? false,
       isSystemGroup = isSystemGroup ?? false {
    if (name.isEmpty) {
      throw ArgumentError('Account group name cannot be empty');
    }
  }


  // For Hive
  AccountGroup.empty()
      : name = '',
        categoryType = 'Assets',
        isInventoryRelated = false,
        isSystemGroup = false;

  AccountGroup copyWith({
    String? name,
    String? parentGroup,
    String? categoryType,
    bool? isInventoryRelated,
    bool? isSystemGroup,
  }) {
    return AccountGroup(
      name: name ?? this.name,
      parentGroup: parentGroup ?? this.parentGroup,
      categoryType: categoryType ?? this.categoryType,
      isInventoryRelated: isInventoryRelated ?? this.isInventoryRelated,
      isSystemGroup: isSystemGroup ?? this.isSystemGroup,
    );
  }

  // Default inventory-related account groups that should be protected
  static const List<Map<String, dynamic>> _inventoryGroups = [
    {'name': 'Stock-in-Hand', 'categoryType': 'Assets', 'parentGroup': 'Current Assets'},
    {'name': 'Sales', 'categoryType': 'Income'},
    {'name': 'Purchase', 'categoryType': 'Expenses'},
    {'name': 'Sales Return', 'categoryType': 'Income'},
    {'name': 'Purchase Return', 'categoryType': 'Expenses'},
  ];

  // Get all default account groups - all are marked as system groups
  static List<AccountGroup> getDefaultGroups() {
    // Regular system groups
    final defaultGroups = [
      // Capital Account Group
      AccountGroup(
        name: 'Capital Account',
        categoryType: 'Liabilities',
        isSystemGroup: true,
      ),
      
      // Liabilities
      AccountGroup(
        name: 'Drawings',
        parentGroup: 'Capital Account',
        categoryType: 'Liabilities',
        isSystemGroup: true,
      ),
      AccountGroup(
        name: 'Loans (Liability)',
        categoryType: 'Liabilities',
        isSystemGroup: true,
      ),
      AccountGroup(
        name: 'Current Liabilities',
        categoryType: 'Liabilities',
        isSystemGroup: true,
      ),
      AccountGroup(
        name: 'Sundry Creditors',
        parentGroup: 'Current Liabilities',
        categoryType: 'Liabilities',
        isSystemGroup: true,
      ),
      
      // Assets
      AccountGroup(
        name: 'Current Assets',
        categoryType: 'Assets',
        isSystemGroup: true,
      ),
      AccountGroup(
        name: 'Sundry Debtors',
        parentGroup: 'Current Assets',
        categoryType: 'Assets',
        isSystemGroup: true,
      ),
      AccountGroup(
        name: 'Bank Accounts',
        parentGroup: 'Current Assets',
        categoryType: 'Assets',
        isSystemGroup: true,
      ),
      AccountGroup(
        name: 'Cash-in-Hand',
        parentGroup: 'Current Assets',
        categoryType: 'Assets',
        isSystemGroup: true,
      ),
      
      // Income
      AccountGroup(
        name: 'Direct Incomes',
        categoryType: 'Income',
        isSystemGroup: true,
      ),
      AccountGroup(
        name: 'Indirect Incomes',
        categoryType: 'Income',
        isSystemGroup: true,
      ),
      
      // Expenses
      AccountGroup(
        name: 'Direct Expenses',
        categoryType: 'Expenses',
        isSystemGroup: true,
      ),
      AccountGroup(
        name: 'Indirect Expenses',
        categoryType: 'Expenses',
        isSystemGroup: true,
      ),
    ];

    // Add inventory-related groups (all are system groups)
    for (var group in _inventoryGroups) {
      defaultGroups.add(AccountGroup(
        name: group['name'] as String,
        categoryType: group['categoryType'] as String,
        parentGroup: group['parentGroup'] as String?,
        isInventoryRelated: true,
        isSystemGroup: true,
      ));
    }

    return defaultGroups;
  }

  // Check if a group is one of the default inventory-related groups
  bool get isDefaultInventoryGroup => _inventoryGroups.any((g) => g['name'] == name);

  @override
  String toString() => name;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AccountGroup &&
      runtimeType == other.runtimeType &&
      name == other.name &&
      parentGroup == other.parentGroup;
      
  @override
  int get hashCode => Object.hash(name, parentGroup);
}