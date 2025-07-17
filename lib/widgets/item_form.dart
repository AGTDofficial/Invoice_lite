import 'package:flutter/material.dart';
import '../models/item_model.dart';

class ItemForm extends StatefulWidget {
  final Function(Item) onSave;
  final Item? item;

  const ItemForm({
    Key? key,
    required this.onSave,
    this.item,
  }) : super(key: key);

  @override
  _ItemFormState createState() => _ItemFormState();
}

class _ItemFormState extends State<ItemForm> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _itemCodeController = TextEditingController();
  String? _selectedItemGroup;
  final _unitController = TextEditingController(text: 'PCS');
  final _saleRateController = TextEditingController();
  final _purchaseRateController = TextEditingController();
  final _openingQtyController = TextEditingController(text: '0');
  final _minStockController = TextEditingController(text: '0');
  final _descriptionController = TextEditingController();
  bool _isStockTracked = true;

  @override
  void initState() {
    super.initState();
    if (widget.item != null) {
      _nameController.text = widget.item!.name;
      _itemCodeController.text = widget.item!.itemCode ?? '';
      _selectedItemGroup = widget.item!.itemGroup;
      _unitController.text = widget.item!.unit;
      _saleRateController.text = widget.item!.saleRate?.toString() ?? '';
      _purchaseRateController.text = widget.item!.purchaseRate?.toString() ?? '';
      _openingQtyController.text = widget.item!.openingStock.toString();
      _minStockController.text = widget.item!.minStockLevel.toString();
      _descriptionController.text = widget.item!.description ?? '';
      _isStockTracked = widget.item!.isStockTracked;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _itemCodeController.dispose();
    _unitController.dispose();
    _saleRateController.dispose();
    _purchaseRateController.dispose();
    _openingQtyController.dispose();
    _minStockController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  void _submitForm() {
    if (_formKey.currentState!.validate()) {
      final openingQty = double.tryParse(_openingQtyController.text) ?? 0.0;
      
      final item = Item(
        id: widget.item?.id,
        name: _nameController.text.trim(),
        itemGroup: _selectedItemGroup,
        itemCode: _itemCodeController.text.trim().isNotEmpty ? _itemCodeController.text.trim() : null,
        unit: _unitController.text.trim(),
        saleRate: double.tryParse(_saleRateController.text),
        purchaseRate: double.tryParse(_purchaseRateController.text),
        openingStock: openingQty,
        currentStock: _isStockTracked ? openingQty : 0.0,
        isStockTracked: _isStockTracked,
        minStockLevel: double.tryParse(_minStockController.text) ?? 0.0,
        description: _descriptionController.text.trim().isNotEmpty ? _descriptionController.text.trim() : null,
      );
      
      widget.onSave(item);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(labelText: 'Item Name *'),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Please enter item name';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _itemCodeController,
              decoration: const InputDecoration(labelText: 'Item Code'),
              keyboardType: TextInputType.text,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _unitController,
              decoration: const InputDecoration(labelText: 'Unit *'),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Required';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _openingQtyController,
                    decoration: const InputDecoration(labelText: 'Opening Qty *'),
                    keyboardType: TextInputType.number,
                    enabled: _isStockTracked,
                    validator: (value) {
                      if (_isStockTracked && (value == null || value.trim().isEmpty)) {
                        return 'Required';
                      }
                      if (value != null && value.trim().isNotEmpty && double.tryParse(value) == null) {
                        return 'Invalid number';
                      }
                      return null;
                    },
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: TextFormField(
                    controller: _purchaseRateController,
                    decoration: const InputDecoration(labelText: 'Purchase Rate', prefixText: '₹ '),
                    keyboardType: TextInputType.number,
                    validator: (value) {
                      if (value != null && value.trim().isNotEmpty && double.tryParse(value) == null) {
                        return 'Invalid number';
                      }
                      return null;
                    },
                  ),
                ),
              ],
            ),
            if (_isStockTracked) ...[
              const SizedBox(height: 16),
              TextFormField(
                controller: _minStockController,
                decoration: const InputDecoration(labelText: 'Minimum Stock Level'),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value != null && value.trim().isNotEmpty && double.tryParse(value) == null) {
                    return 'Invalid number';
                  }
                  return null;
                },
              ),
            ],
            const SizedBox(height: 16),
            const SizedBox(height: 16),
            TextFormField(
              controller: _saleRateController,
              decoration: const InputDecoration(labelText: 'Sale Rate', prefixText: '₹ '),
              keyboardType: TextInputType.number,
              validator: (value) {
                if (value != null && value.trim().isNotEmpty && double.tryParse(value) == null) {
                  return 'Invalid number';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _descriptionController,
              decoration: const InputDecoration(labelText: 'Description'),
              maxLines: 2,
              keyboardType: TextInputType.multiline,
            ),
            const SizedBox(height: 16),
            SwitchListTile(
              title: const Text('Track Stock'),
              value: _isStockTracked,
              onChanged: (value) {
                setState(() {
                  _isStockTracked = value;
                });
              },
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _submitForm,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: Text(widget.item == null ? 'Add Item' : 'Update Item'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
