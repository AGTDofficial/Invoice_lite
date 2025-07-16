import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:uuid/uuid.dart';
import '../models/item_model.dart';
import '../models/item_group.dart';
import '../models/stock_movement.dart';
import '../enums/stock_movement_type.dart';

class ItemFormScreen extends StatefulWidget {
  final Item? item;
  final Box<Item> itemsBox;
  final void Function(Item item, {bool isDelete}) onSave;

  const ItemFormScreen({
    Key? key,
    this.item,
    required this.itemsBox,
    required this.onSave,
  }) : super(key: key);

  @override
  _ItemFormScreenState createState() => _ItemFormScreenState();
}

class _ItemFormScreenState extends State<ItemFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _itemCodeController = TextEditingController();
  final _hsnCodeController = TextEditingController();
  final _saleRateController = TextEditingController();
  final _purchaseRateController = TextEditingController();
  final _openingStockController = TextEditingController();
  final _minStockLevelController = TextEditingController();
  final _barcodeController = TextEditingController();
  final _descriptionController = TextEditingController();

  String? _selectedGroup;
  String? _selectedUnit = 'PCS';
  double _taxRate = 0.0;
  bool _isStockTracked = false;
  // Using a Set to ensure unique units
  final Set<String> _commonUnits = {'PCS', 'KG', 'LTR', 'MTR', 'BOX', 'PKT'}.toSet();
  final List<double> _taxRates = [0, 5, 12, 18, 28];
  final _groupBox = Hive.box<ItemGroup>('itemGroups');

  @override
  void initState() {
    super.initState();
    if (widget.item != null) {
      _loadItemData(widget.item!);
    }
  }

  void _loadItemData(Item item) {
    _nameController.text = item.name;
    _itemCodeController.text = item.itemCode ?? '';
    _hsnCodeController.text = item.hsnCode ?? '';
    _saleRateController.text = item.saleRate?.toString() ?? '';
    _purchaseRateController.text = item.purchaseRate?.toString() ?? '';
    _openingStockController.text = item.openingStock.toString();
    _minStockLevelController.text = item.minStockLevel.toString();
    _barcodeController.text = item.barcode ?? '';
    _descriptionController.text = item.description ?? '';
    _selectedGroup = item.itemGroup;
    _selectedUnit = item.unit;
    _taxRate = item.taxRate;
    _isStockTracked = item.isStockTracked;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _itemCodeController.dispose();
    _hsnCodeController.dispose();
    _saleRateController.dispose();
    _purchaseRateController.dispose();
    _openingStockController.dispose();
    _minStockLevelController.dispose();
    _barcodeController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  void _saveForm() {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final itemName = _nameController.text.trim();
    
    // Check for duplicate item name (case insensitive)
    final duplicates = widget.itemsBox.values.where(
      (item) => item.name.toLowerCase() == itemName.toLowerCase() && 
                (widget.item?.key != item.key),
    );

    if (!duplicates.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('An item with this name already exists')),
      );
      return;
    }

    final openingStock = double.tryParse(_openingStockController.text) ?? 0.0;
    final currentStock = _isStockTracked ? openingStock : 0.0;
    
    final item = Item(
      id: widget.item?.id ?? Uuid().v4(),
      name: _nameController.text.trim(),
      itemGroup: _selectedGroup,
      itemCode: _itemCodeController.text.trim().isNotEmpty
          ? _itemCodeController.text.trim()
          : '',
      unit: _selectedUnit!,
      taxRate: _taxRate,
      hsnCode: _hsnCodeController.text.trim().isNotEmpty
          ? _hsnCodeController.text.trim()
          : '',
      saleRate: double.tryParse(_saleRateController.text) ?? 0.0,
      purchaseRate: double.tryParse(_purchaseRateController.text) ?? 0.0,
      openingStock: openingStock,
      currentStock: currentStock,
      isStockTracked: _isStockTracked,
      minStockLevel: double.tryParse(_minStockLevelController.text) ?? 0.0,
      barcode: _barcodeController.text.trim().isNotEmpty
          ? _barcodeController.text.trim()
          : '',
      description: _descriptionController.text.trim().isNotEmpty
          ? _descriptionController.text.trim()
          : '',
    );

    // Handle stock movements
    if (_isStockTracked) {
      // For new items with opening stock
      if (widget.item == null && openingStock > 0) {
        final openingMovement = StockMovement(
          itemId: item.id,
          quantity: openingStock.toDouble(),
          dateTime: DateTime.now(),
          referenceId: 'Opening Stock',
          type: StockMovementType.openingStock,
          balance: openingStock.toDouble(),
        );
        item.addStockMovement(openingMovement);
      }
      // For existing items with updated opening stock
      else if (widget.item != null && widget.item!.openingStock != openingStock) {
        final stockDiff = openingStock - widget.item!.openingStock;
        if (stockDiff != 0) {
          final stockUpdate = StockMovement(
            itemId: item.id,
            quantity: stockDiff.toDouble(),
            dateTime: DateTime.now(),
            referenceId: 'Stock Adjustment',
            type: StockMovementType.adjustment,
            balance: openingStock.toDouble(),
          );
          item.addStockMovement(stockUpdate);
        }
      }
    }

    widget.onSave(item);
    Navigator.of(context).pop();
  }

  Future<void> _deleteItem() async {
    if (widget.item != null) {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Delete Item'),
          content: Text('Are you sure you want to delete ${widget.item!.name}?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: const Text('CANCEL'),
            ),
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(true),
              child: const Text('DELETE', style: TextStyle(color: Colors.red)),
            ),
          ],
        ),
      );

      if (confirmed == true) {
        // Call onSave with isDelete: true to indicate deletion
        widget.onSave(widget.item!, isDelete: true);
        if (mounted) {
          Navigator.of(context).pop();
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.item == null ? 'Add Item' : 'Edit Item'),
        actions: widget.item != null
            ? [
                IconButton(
                  icon: const Icon(Icons.delete, color: Colors.red),
                  onPressed: () => _deleteItem(),
                ),
              ]
            : null,
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16.0),
          children: [
            // Basic Information Section
            _buildSectionHeader('Basic Information'),
            _buildTextField(
              controller: _nameController,
              label: 'Item Name *',
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter item name';
                }
                return null;
              },
            ),
            const SizedBox(height: 8),
            _buildGroupDropdown(),
            const SizedBox(height: 8),
            _buildTextField(
              controller: _itemCodeController,
              label: 'Item Code',
            ),
            const SizedBox(height: 8),
            _buildUnitDropdown(),
            const SizedBox(height: 8),
            _buildTaxRateDropdown(),
            const SizedBox(height: 8),
            _buildTextField(
              controller: _hsnCodeController,
              label: 'HSN/SAC Code',
            ),
            const SizedBox(height: 24),

            // Pricing Section
            _buildSectionHeader('Pricing'),
            _buildTextField(
              controller: _saleRateController,
              label: 'Sale Rate',
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 8),
            _buildTextField(
              controller: _purchaseRateController,
              label: 'Purchase Rate',
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 24),

            // Stock Management Section
            _buildSectionHeader('Stock Management'),
            SwitchListTile(
              title: const Text('Track Stock'),
              value: _isStockTracked,
              onChanged: (value) {
                setState(() {
                  _isStockTracked = value;
                });
              },
            ),
            if (_isStockTracked) ...[
              _buildTextField(
                controller: _openingStockController,
                label: 'Opening Stock',
                keyboardType: TextInputType.number,
                initialValue: '0',
              ),
              const SizedBox(height: 8),
              _buildTextField(
                controller: _minStockLevelController,
                label: 'Minimum Stock Level',
                keyboardType: TextInputType.number,
                initialValue: '0',
              ),
              const SizedBox(height: 8),
            ],
            const SizedBox(height: 24),

            // Additional Information Section
            _buildSectionHeader('Additional Information'),
            _buildTextField(
              controller: _barcodeController,
              label: 'Barcode',
            ),
            const SizedBox(height: 8),
            _buildTextField(
              controller: _descriptionController,
              label: 'Description',
              maxLines: 3,
            ),
          ],
        ),
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ElevatedButton(
          onPressed: _saveForm,
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          child: Text(
            widget.item == null ? 'Save Item' : 'Update Item',
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: Theme.of(context).primaryColor,
            ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    TextInputType? keyboardType,
    String? initialValue,
    int? maxLines = 1,
    String? Function(String?)? validator,
  }) {
    if (initialValue != null && controller.text.isEmpty) {
      controller.text = initialValue;
    }

    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 12,
        ),
      ),
      keyboardType: keyboardType,
      maxLines: maxLines,
      validator: validator,
    );
  }

  Widget _buildGroupDropdown() {
    return ValueListenableBuilder<Box<ItemGroup>>(
      valueListenable: _groupBox.listenable(),
      builder: (context, box, _) {
        final groups = box.values.map((g) => g.name).toList();
        return DropdownButtonFormField<String>(
          value: _selectedGroup,
          decoration: const InputDecoration(
            labelText: 'Item Group',
            border: OutlineInputBorder(),
            contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          ),
          items: [
            const DropdownMenuItem<String>(
              value: null,
              child: Text('Select Group'),
            ),
            ...groups.map((group) {
              return DropdownMenuItem<String>(
                value: group,
                child: Text(group),
              );
            }).toList(),
          ],
          onChanged: (value) {
            setState(() {
              _selectedGroup = value;
            });
          },
          validator: (value) {
            // Group is optional
            return null;
          },
        );
      },
    );
  }

  Widget _buildUnitDropdown() {
    // Convert to list and ensure case-insensitive uniqueness
    final uniqueUnits = _commonUnits.toSet().toList()
      ..sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));
    
    // Ensure the current value is in the list if it's not 'other'
    if (_selectedUnit != null && 
        _selectedUnit != 'other' && 
        !uniqueUnits.any((u) => u == _selectedUnit)) {
      uniqueUnits.add(_selectedUnit!);
    }

    return DropdownButtonFormField<String>(
      value: _selectedUnit,
      decoration: const InputDecoration(
        labelText: 'Unit',
        border: OutlineInputBorder(),
        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        suffixIcon: Icon(Icons.arrow_drop_down),
      ),
      items: [
        ...uniqueUnits.map((unit) => DropdownMenuItem<String>(
              value: unit,
              child: Text(unit),
            )),
        if (!uniqueUnits.contains('other'))
          const DropdownMenuItem<String>(
            value: 'other',
            child: Text('Other (Specify)'),
          ),
      ],
      onChanged: (value) {
        if (value == null) return;
        
        setState(() {
          _selectedUnit = value;
          if (value == 'other') {
            _showCustomUnitDialog();
          }
        });
      },
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Please select a unit';
        }
        return null;
      },
    );
  }

  Widget _buildTaxRateDropdown() {
    return DropdownButtonFormField<double>(
      value: _taxRate,
      decoration: const InputDecoration(
        labelText: 'Tax Rate (%)',
        border: OutlineInputBorder(),
        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        suffixIcon: Icon(Icons.percent),
      ),
      items: _taxRates.map((rate) {
        return DropdownMenuItem<double>(
          value: rate,
          child: Text('$rate%' + (rate == 0 ? ' (Exempt)' : '')),
        );
      }).toList(),
      onChanged: (value) {
        if (value != null) {
          setState(() {
            _taxRate = value;
          });
        }
      },
    );
  }

  Future<void> _showCustomUnitDialog() async {
    final TextEditingController controller = TextEditingController();
    return showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Enter Custom Unit'),
          content: TextField(
            controller: controller,
            decoration: const InputDecoration(
              labelText: 'Unit',
              hintText: 'e.g., BOX, PKT, SET',
            ),
            textCapitalization: TextCapitalization.characters,
            maxLength: 10,
            autofocus: true,
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('CANCEL'),
            ),
            TextButton(
              onPressed: () {
                final unit = controller.text.trim().toUpperCase();
                if (unit.isEmpty) return;
                
                setState(() {
                  // Check if unit already exists (case-insensitive)
                  final existingUnit = _commonUnits.cast<String?>().firstWhere(
                    (u) => u?.toUpperCase() == unit,
                    orElse: () => null,
                  );

                  if (existingUnit != null) {
                    // Use the existing unit's exact case
                    _selectedUnit = existingUnit;
                  } else {
                    // Add new unit and select it
                    _commonUnits.add(unit);
                    _selectedUnit = unit;
                  }
                });
                
                Navigator.of(context).pop();
              },
              child: const Text('SAVE'),
            ),
          ],
        );
      },
    );
  }
}
