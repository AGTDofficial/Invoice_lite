import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/item_group.dart';

class ItemGroupScreen extends StatefulWidget {
  const ItemGroupScreen({super.key});

  @override
  State<ItemGroupScreen> createState() => _ItemGroupScreenState();
}

class _ItemGroupScreenState extends State<ItemGroupScreen> {
  final _groupBox = Hive.box<ItemGroup>('itemGroups');
  final TextEditingController _nameController = TextEditingController();
  String? _selectedParent;
  int? _editingIndex;

  void _saveGroup() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please enter a group name')),
        );
      }
      return;
    }

    // Check for duplicate names (excluding the current item being edited)
    if (_groupBox.values.any((g) => 
        g.name.toLowerCase() == name.toLowerCase() && 
        g.key != (_editingIndex != null ? _groupBox.keyAt(_editingIndex!) : null))) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('A group with this name already exists')),
        );
      }
      return;
    }

    if (_editingIndex != null) {
      // Update existing group
      final key = _groupBox.keyAt(_editingIndex!);
      final updatedGroup = ItemGroup(
        name: name,
        parentGroup: _selectedParent,
        isSystemGroup: _groupBox.getAt(_editingIndex!)?.isSystemGroup ?? false,
      );
      await _groupBox.put(key, updatedGroup);
    } else {
      // Create new group
      final newGroup = ItemGroup(
        name: name,
        parentGroup: _selectedParent,
      );
      await _groupBox.add(newGroup);
    }

    _resetForm();
    if (mounted) {
      Navigator.pop(context);
    }
  }

  void _resetForm() {
    _nameController.clear();
    _selectedParent = null;
    _editingIndex = null;
    setState(() {});
  }

  void _showEditGroupDialog(int index) {
    final group = _groupBox.getAt(index);
    if (group == null) return;
    
    _editingIndex = index;
    _nameController.text = group.name;
    _selectedParent = group.parentGroup;
    
    _showGroupDialog();
  }

  void _showCreateGroupDialog() {
    _resetForm();
    _showGroupDialog();
  }
  
  void _showGroupDialog() {
    final isEditing = _editingIndex != null;
    
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(isEditing ? 'Edit Item Group' : 'Create Item Group'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(labelText: 'Group Name'),
            ),
            ValueListenableBuilder(
              valueListenable: _groupBox.listenable(),
              builder: (context, Box<ItemGroup> box, _) {
                final options = box.values.map((g) => g.name).toList();
                return DropdownButtonFormField<String>(
                  value: _selectedParent,
                  hint: const Text('Parent Group (optional)'),
                  items: options
                      .map((name) => DropdownMenuItem(value: name, child: Text(name)))
                      .toList(),
                  onChanged: (val) => setState(() => _selectedParent = val),
                  isExpanded: true,
                );
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: _saveGroup,
            child: Text(isEditing ? 'Update' : 'Save'),
          ),
        ],
      ),
    );
  }

  void _deleteGroup(int index) async {
    final group = _groupBox.getAt(index);
    if (group?.isSystemGroup == true) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('System groups cannot be deleted.')),
        );
      }
      return;
    }
    await _groupBox.deleteAt(index);
    if (mounted) {
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Item Groups')),
      body: ValueListenableBuilder(
        valueListenable: _groupBox.listenable(),
        builder: (context, Box<ItemGroup> box, _) {
          final groups = box.values.toList();
          return ListView.builder(
            itemCount: groups.length,
            itemBuilder: (context, index) {
              final group = groups[index];
              return ListTile(
                leading: group.isSystemGroup ? const Icon(Icons.lock, size: 20) : null,
                title: Text(group.name),
                subtitle: group.parentGroup != null
                    ? Text('Parent: ${group.parentGroup}')
                    : null,
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (!group.isSystemGroup) ...[
                      IconButton(
                        icon: const Icon(Icons.edit, color: Colors.blue),
                        onPressed: () => _showEditGroupDialog(index),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        onPressed: () => _deleteGroup(index),
                      ),
                    ],
                  ],
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showCreateGroupDialog,
        icon: const Icon(Icons.add),
        label: const Text('Add Group'),
      ),
    );
  }
}
