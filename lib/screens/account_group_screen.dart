import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/account_group.dart';

class AccountGroupScreen extends StatefulWidget {
  const AccountGroupScreen({Key? key}) : super(key: key);

  @override
  State<AccountGroupScreen> createState() => _AccountGroupScreenState();
}

class _AccountGroupScreenState extends State<AccountGroupScreen> {
  late final Box<AccountGroup> groupBox;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    groupBox = Hive.box<AccountGroup>('accountGroups');
    _initializeDefaultGroups();
  }

  Future<void> _initializeDefaultGroups() async {
    if (groupBox.isEmpty) {
      final defaultGroups = AccountGroup.getDefaultGroups();
      await groupBox.addAll(defaultGroups);
    }
  }

  void _filterGroups(String query) {
    setState(() {
      _searchQuery = query.toLowerCase();
    });
  }

  void _showAddEditGroupDialog({AccountGroup? group}) {
    final isEdit = group != null;
    final isSystemGroup = group?.isSystemGroup ?? false;
    final isDefaultInventoryGroup = group?.isDefaultInventoryGroup ?? false;
    final formKey = GlobalKey<FormState>();
    
    // Form controllers and state
    final nameController = TextEditingController(text: group?.name ?? '');
    String categoryType = group?.categoryType ?? 'Assets';
    String selectedParent = group?.parentGroup ?? 'None';
    bool isInventoryRelated = group?.isInventoryRelated ?? false;

    // Only show categories that make sense for new groups
    final categoryTypes = isEdit && isSystemGroup
        ? [categoryType] // Lock category for system groups
        : ['Assets', 'Liabilities', 'Income', 'Expenses'];
        
    // Get available parent groups, excluding current group and its children
    final availableParentGroups = groupBox.values.where((g) {
      // If not in edit mode, include all groups
      if (!isEdit) return true;
      
      // In edit mode, exclude the current group and its children
      // Since this is edit mode, group is guaranteed to be non-null
      if (g.name == group.name) return false;  // Don't allow selecting self as parent
      
      return !_isChildOf(g, group.name);  // Don't allow selecting any children as parent
    }).map((g) => g.name).toList()..insert(0, 'None');

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('${isEdit ? 'Edit' : 'Add'} Account Group'),
        content: SingleChildScrollView(
          child: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TextFormField(
                  controller: nameController,
                  decoration: const InputDecoration(
                    labelText: 'Group Name',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) =>
                      value?.trim().isEmpty ?? true ? 'Name is required' : null,
                  enabled: !(group?.isSystemGroup ?? false),
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: selectedParent,
                  decoration: const InputDecoration(
                    labelText: 'Parent Group',
                    border: OutlineInputBorder(),
                  ),
                  items: availableParentGroups
                      .map((group) => DropdownMenuItem(
                            value: group,
                            child: Text(group),
                          ))
                      .toList(),
                  onChanged: (value) {
                    if (value != null) {
                      setState(() => selectedParent = value);
                    }
                  },
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: categoryType,
                  decoration: const InputDecoration(
                    labelText: 'Category Type',
                    border: OutlineInputBorder(),
                  ),
                  items: categoryTypes
                      .map((type) => DropdownMenuItem(
                            value: type,
                            child: Text(type),
                          ))
                      .toList(),
                  onChanged: (group?.isSystemGroup ?? false)
                      ? null
                      : (value) => categoryType = value!,
                ),
                const SizedBox(height: 16),
                // Hide inventory toggle for default inventory groups
                if (!isDefaultInventoryGroup) ...[
                  const SizedBox(height: 8),
                  CheckboxListTile(
                    title: const Text('Affects Inventory'),
                    subtitle: isSystemGroup 
                        ? const Text('Cannot modify for system groups')
                        : null,
                    value: isInventoryRelated,
                    onChanged: isSystemGroup
                        ? null
                        : (value) => setState(() => isInventoryRelated = value ?? false),
                    controlAffinity: ListTileControlAffinity.leading,
                  ),
                ],
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              if (formKey.currentState?.validate() ?? false) {
                final newGroup = AccountGroup(
                  name: nameController.text.trim(),
                  parentGroup: selectedParent == 'None' ? null : selectedParent,
                  categoryType: categoryType,
                  isInventoryRelated: isInventoryRelated,
                  isSystemGroup: false, // User-created groups are never system groups
                );

                if (isEdit) {
                  group.name = newGroup.name;
                  group.parentGroup = newGroup.parentGroup;
                  if (!group.isSystemGroup) {
                    group.categoryType = newGroup.categoryType;
                    group.isInventoryRelated = newGroup.isInventoryRelated;
                  }
                  group.save();
                } else {
                  groupBox.add(newGroup);
                }
                Navigator.pop(context);
              }
            },
            child: Text(isEdit ? 'Update' : 'Create'),
          ),
        ],
      ),
    );
  }

  Map<String, List<AccountGroup>> _buildGroupTree(List<AccountGroup> groups) {
    final tree = <String, List<AccountGroup>>{};
    for (var group in groups) {
      final parent = group.parentGroup ?? '';
      tree.putIfAbsent(parent, () => []).add(group);
    }
    return tree;
  }

  Widget _buildGroupTreeView(String parent, Map<String, List<AccountGroup>> tree,
      List<AccountGroup> allGroups, int level) {
    final children = tree[parent] ?? [];
    if (children.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ...children.map((group) {
          final hasChildren = tree[group.name]?.isNotEmpty ?? false;
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Card(
                margin: EdgeInsets.only(left: level * 16.0, top: 4, bottom: 4),
                child: ListTile(
                  leading: Icon(
                    hasChildren ? Icons.folder : Icons.folder_open,
                    color: _getCategoryColor(group.categoryType),
                  ),
                  title: Row(
                    children: [
                      Expanded(child: Text(group.name)),
                      if (group.isInventoryRelated)
                        const Icon(Icons.inventory_2_outlined, size: 16, color: Colors.teal),
                      const SizedBox(width: 4),
                      _buildCategoryChip(group.categoryType),
                    ],
                  ),
                  onTap: () => _showGroupDetails(group, allGroups, tree),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (group.isSystemGroup)
                        const Padding(
                          padding: EdgeInsets.only(right: 8.0),
                          child: Icon(Icons.lock_outline, size: 20, color: Colors.grey),
                        )
                      else
                        IconButton(
                          icon: const Icon(Icons.edit_outlined, size: 20),
                          onPressed: () => _showAddEditGroupDialog(group: group),
                          color: Theme.of(context).primaryColor,
                          tooltip: 'Edit',
                        ),
                      if (!group.isSystemGroup)
                        IconButton(
                          icon: const Icon(Icons.delete_outline, size: 20),
                          onPressed: () => _confirmDeleteGroup(group, allGroups, tree),
                          color: Colors.red,
                          tooltip: 'Delete',
                        ),
                    ],
                  ),
                ),
              ),
              if (hasChildren)
                _buildGroupTreeView(group.name, tree, allGroups, level + 1),
            ],
          );
        }).toList(),
      ],
    );
  }

  Widget _buildCategoryChip(String category) {
    final primaryColor = Theme.of(context).primaryColor;
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: primaryColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: primaryColor.withOpacity(0.3)),
      ),
      child: Text(
        category,
        style: TextStyle(
          fontSize: 12,
          color: primaryColor,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  void _showGroupDetails(AccountGroup group, List<AccountGroup> allGroups, Map<String, List<AccountGroup>> tree) {
    final children = tree[group.name] ?? [];
    final parent = allGroups.firstWhere(
      (g) => g.name == group.parentGroup,
      orElse: () => AccountGroup(name: 'None', categoryType: ''),
    );

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(group.name),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildDetailRow('Category', group.categoryType),
              _buildDetailRow('Parent Group', parent.name),
              if (group.isInventoryRelated)
                _buildDetailRow('Inventory', 'Affects Inventory'),
              if (children.isNotEmpty) ...[
                const SizedBox(height: 16),
                const Text('Sub-groups:', style: TextStyle(fontWeight: FontWeight.bold)),
                ...children.map((child) => Padding(
                  padding: const EdgeInsets.only(left: 8.0, top: 4),
                  child: Text('• ${child.name}'),
                )).toList(),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }

  Color _getCategoryColor(String category) {
    return Theme.of(context).primaryColor;
  }

  void _confirmDeleteGroup(AccountGroup group, List<AccountGroup> allGroups, Map<String, List<AccountGroup>> tree) {
    // Check if group has children
    final hasChildren = tree[group.name]?.isNotEmpty ?? false;
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Group'),
        content: Text(
          hasChildren
              ? 'This group has sub-groups. Deleting it will also delete all sub-groups. Are you sure?'
              : 'Are you sure you want to delete this group?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              _deleteGroup(group, allGroups, tree);
              Navigator.pop(context);
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  // Check if group a is a child of group b
  bool _isChildOf(AccountGroup potentialChild, String parentName) {
    if (potentialChild.parentGroup == parentName) return true;
    if (potentialChild.parentGroup == null) return false;
    
    try {
      final parent = groupBox.values.firstWhere(
        (g) => g.name == potentialChild.parentGroup,
      );
      return _isChildOf(parent, parentName);
    } catch (e) {
      return false; // Parent not found
    }
  }

  void _deleteGroup(AccountGroup group, List<AccountGroup> allGroups, Map<String, List<AccountGroup>> tree) {
    // Prevent deletion of system groups
    if (group.isSystemGroup) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('System groups cannot be deleted'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Recursively delete all children
    final children = tree[group.name] ?? [];
    for (var child in children) {
      // Don't delete system groups even if they're children
      if (!child.isSystemGroup) {
        _deleteGroup(child, allGroups, tree);
      }
    }
    
    // Delete the group itself
    group.delete();
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('"${group.name}" deleted')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Account Groups'),
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.help_outline),
            onPressed: () {
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('About Account Groups'),
                  content: const Text(
                    '• Account Groups help organize your chart of accounts.\n\n'
                    '• System groups (🔒) cannot be deleted or modified.\n\n'
                    '• Use categories to group accounts for financial reporting.',
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Got it'),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search groups...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: Colors.grey[100],
                contentPadding: const EdgeInsets.symmetric(vertical: 0),
              ),
              onChanged: _filterGroups,
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: ValueListenableBuilder(
              valueListenable: groupBox.listenable(),
              builder: (context, Box<AccountGroup> box, _) {
                final allGroups = box.values.toList();
                
                // Filter groups based on search query
                final filteredGroups = _searchQuery.isEmpty
                    ? allGroups
                    : allGroups
                        .where((group) =>
                            group.name.toLowerCase().contains(_searchQuery))
                        .toList();

                final tree = _buildGroupTree(filteredGroups);

                if (filteredGroups.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.folder_off_outlined,
                          size: 64,
                          color: Colors.grey[400],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No groups found',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        if (_searchQuery.isNotEmpty) ...[
                          const SizedBox(height: 8),
                          const Text('Try a different search term'),
                        ],
                      ],
                    ),
                  );
                }


                return SingleChildScrollView(
                  child: _buildGroupTreeView('', tree, filteredGroups, 0),
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddEditGroupDialog(),
        icon: const Icon(Icons.add),
        label: const Text('New Group'),
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
      ),
    );
  }
}