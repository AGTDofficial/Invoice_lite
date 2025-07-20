import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:form_builder_validators/form_builder_validators.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/custom_text_field.dart';
import '../../data/item_dao.dart';
import '../../data/item_model.dart';

class AddEditItemScreen extends ConsumerStatefulWidget {
  static const String routeName = '/items/add-edit';
  
  final int? itemId; // Null for new item
  
  const AddEditItemScreen({
    super.key,
    this.itemId,
  });

  @override
  ConsumerState<AddEditItemScreen> createState() => _AddEditItemScreenState();
}

class _AddEditItemScreenState extends ConsumerState<AddEditItemScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _descriptionController;
  late final TextEditingController _itemCodeController;
  late final TextEditingController _saleRateController;
  late final TextEditingController _purchaseRateController;
  late final TextEditingController _currentStockController;
  late final TextEditingController _minStockLevelController;
  late final TextEditingController _unitController;
  
  bool _isLoading = false;
  
  // Available units for the dropdown
  final List<String> _availableUnits = const [
    'PCS', 'KG', 'G', 'L', 'ML', 'M', 'FT', 'IN', 'BOX', 'PKT'
  ];
  
  @override
  void initState() {
    super.initState();
    
    _nameController = TextEditingController();
    _descriptionController = TextEditingController();
    _itemCodeController = TextEditingController();
    _saleRateController = TextEditingController();
    _purchaseRateController = TextEditingController();
    _currentStockController = TextEditingController(text: '0');
    _minStockLevelController = TextEditingController(text: '0');
    _unitController = TextEditingController(text: 'PCS');
    
    // If editing, load item data
    if (widget.itemId != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _loadItemData();
      });
    }
  }
  
  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _itemCodeController.dispose();
    _saleRateController.dispose();
    _purchaseRateController.dispose();
    _currentStockController.dispose();
    _minStockLevelController.dispose();
    _unitController.dispose();
    super.dispose();
  }
  
  Future<void> _loadItemData() async {
    if (widget.itemId == null) return;
    
    setState(() => _isLoading = true);
    
    try {
      final itemDao = ref.read(itemDaoProvider);
      final item = await itemDao.getItem(widget.itemId!);
      
      if (item != null) {
        setState(() {
          _nameController.text = item.name;
          _descriptionController.text = item.description ?? '';
          _itemCodeController.text = item.itemCode;
          _saleRateController.text = item.saleRate.toString();
          _purchaseRateController.text = item.purchaseRate.toString();
          _currentStockController.text = item.currentStock.toString();
          _minStockLevelController.text = item.minStockLevel.toString();
          _unitController.text = item.unit;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load item: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }
  
  Future<void> _saveItem() async {
    if (!_formKey.currentState!.validate()) return;
    
    setState(() => _isLoading = true);
    
    try {
      final itemDao = ref.read(itemDaoProvider);
      final now = DateTime.now();
      
      final item = Item(
        id: widget.itemId ?? 0, // 0 will be auto-incremented
        name: _nameController.text.trim(),
        description: _descriptionController.text.trim().isEmpty 
            ? null 
            : _descriptionController.text.trim(),
        itemCode: _itemCodeController.text.trim(),
        saleRate: double.tryParse(_saleRateController.text) ?? 0,
        purchaseRate: double.tryParse(_purchaseRateController.text) ?? 0,
        currentStock: double.tryParse(_currentStockController.text) ?? 0,
        minStockLevel: double.tryParse(_minStockLevelController.text) ?? 0,
        unit: _unitController.text.trim(),
        createdAt: widget.itemId == null ? now : null,
        updatedAt: now,
      );
      
      if (widget.itemId == null) {
        await itemDao.addItem(item.toCompanion(true));
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Item added successfully')),
          );
        }
      } else {
        await itemDao.updateItem(item.toCompanion(true));
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Item updated successfully')),
          );
        }
      }
      
      if (mounted) {
        Navigator.of(context).pop(true); // Return success
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to save item: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }
  
  Future<void> _confirmDelete() async {
    if (widget.itemId == null) return;
    
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Item'),
        content: const Text('Are you sure you want to delete this item? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('CANCEL'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('DELETE'),
          ),
        ],
      ),
    );
    
    if (confirmed != true) return;
    
    setState(() => _isLoading = true);
    
    try {
      final itemDao = ref.read(itemDaoProvider);
      await itemDao.deleteItem(widget.itemId!);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Item deleted successfully')),
        );
        Navigator.of(context).pop(true); // Return success
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to delete item: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.itemId == null ? 'Add Item' : 'Edit Item',
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        actions: [
          if (widget.itemId != null) ...[
            IconButton(
              icon: const Icon(Icons.delete_outline, color: Colors.red),
              onPressed: _isLoading ? null : _confirmDelete,
              tooltip: 'Delete Item',
            ),
            const SizedBox(width: 8),
          ],
          TextButton(
            onPressed: _isLoading ? null : _saveItem,
            child: _isLoading 
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('SAVE'),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: _isLoading && widget.itemId != null
          ? const Center(child: CircularProgressIndicator())
          : Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  // Basic Information
                  const Text(
                    'Item Details',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 12),
                  
                  // Name
                  CustomTextField(
                    controller: _nameController,
                    label: 'Item Name *',
                    hint: 'Enter item name',
                    prefixIcon: Icons.inventory_2_outlined,
                    keyboardType: TextInputType.name,
                    textCapitalization: TextCapitalization.words,
                    validator: FormBuilderValidators.compose([
                      FormBuilderValidators.required(errorText: 'Name is required'),
                      FormBuilderValidators.maxLength(100, errorText: 'Maximum 100 characters'),
                    ]),
                  ),
                  const SizedBox(height: 16),
                  
                  // Item Code
                  CustomTextField(
                    controller: _itemCodeController,
                    label: 'Item Code *',
                    hint: 'Enter item code',
                    prefixIcon: Icons.qr_code,
                    textCapitalization: TextCapitalization.characters,
                    validator: FormBuilderValidators.compose([
                      FormBuilderValidators.required(errorText: 'Item code is required'),
                      FormBuilderValidators.maxLength(50, errorText: 'Maximum 50 characters'),
                    ]),
                  ),
                  const SizedBox(height: 16),
                  
                  // Description
                  CustomTextField(
                    controller: _descriptionController,
                    label: 'Description',
                    hint: 'Enter item description',
                    prefixIcon: Icons.description_outlined,
                    maxLines: 3,
                    textCapitalization: TextCapitalization.sentences,
                  ),
                  
                  // Pricing
                  const SizedBox(height: 24),
                  const Text(
                    'Pricing',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 12),
                  
                  Row(
                    children: [
                      // Sale Rate
                      Expanded(
                        child: CustomTextField(
                          controller: _saleRateController,
                          label: 'Sale Rate *',
                          hint: '0.00',
                          prefixIcon: Icons.currency_rupee,
                          keyboardType: TextInputType.numberWithOptions(decimal: true),
                          inputFormatters: [
                            FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
                          ],
                          validator: FormBuilderValidators.compose([
                            FormBuilderValidators.required(errorText: 'Sale rate is required'),
                            FormBuilderValidators.numeric(errorText: 'Enter a valid amount'),
                          ]),
                        ),
                      ),
                      const SizedBox(width: 16),
                      
                      // Purchase Rate
                      Expanded(
                        child: CustomTextField(
                          controller: _purchaseRateController,
                          label: 'Purchase Rate',
                          hint: '0.00',
                          prefixIcon: Icons.currency_rupee,
                          keyboardType: TextInputType.numberWithOptions(decimal: true),
                          inputFormatters: [
                            FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
                          ],
                          validator: FormBuilderValidators.compose([
                            FormBuilderValidators.numeric(errorText: 'Enter a valid amount'),
                          ]),
                        ),
                      ),
                    ],
                  ),
                  
                  // Stock Management
                  const SizedBox(height: 24),
                  const Text(
                    'Stock Management',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 12),
                  
                  Row(
                    children: [
                      // Current Stock
                      Expanded(
                        child: CustomTextField(
                          controller: _currentStockController,
                          label: 'Current Stock',
                          hint: '0',
                          prefixIcon: Icons.inventory_2_outlined,
                          keyboardType: TextInputType.numberWithOptions(decimal: true),
                          inputFormatters: [
                            FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
                          ],
                          validator: FormBuilderValidators.compose([
                            FormBuilderValidators.numeric(errorText: 'Enter a valid number'),
                          ]),
                        ),
                      ),
                      const SizedBox(width: 16),
                      
                      // Min Stock Level
                      Expanded(
                        child: CustomTextField(
                          controller: _minStockLevelController,
                          label: 'Min Stock Level',
                          hint: '0',
                          prefixIcon: Icons.warning_amber_outlined,
                          keyboardType: TextInputType.numberWithOptions(decimal: true),
                          inputFormatters: [
                            FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
                          ],
                          validator: FormBuilderValidators.compose([
                            FormBuilderValidators.numeric(errorText: 'Enter a valid number'),
                          ]),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  
                  // Unit
                  CustomTextField(
                    controller: _unitController,
                    label: 'Unit of Measurement *',
                    hint: 'Select unit',
                    prefixIcon: Icons.scale_outlined,
                    readOnly: true,
                    onTap: () {
                      showModalBottomSheet(
                        context: context,
                        builder: (context) => _buildUnitSelector(theme),
                      );
                    },
                    validator: FormBuilderValidators.compose([
                      FormBuilderValidators.required(errorText: 'Unit is required'),
                    ]),
                  ),
                ],
              ),
            ),
    );
  }
  
  Widget _buildUnitSelector(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Select Unit',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: ListView.builder(
              itemCount: _availableUnits.length,
              itemBuilder: (context, index) {
                final unit = _availableUnits[index];
                return ListTile(
                  title: Text(unit),
                  trailing: _unitController.text == unit
                      ? Icon(Icons.check, color: theme.primaryColor)
                      : null,
                  onTap: () {
                    setState(() {
                      _unitController.text = unit;
                    });
                    Navigator.pop(context);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
