import 'package:flutter/material.dart';

class DropdownTextFormField<T> extends StatelessWidget {
  final String label;
  final T? value;
  final List<T> items;
  final String Function(T) displayString;
  final void Function(T?) onChanged;
  final String? Function(T?)? validator;
  final bool isRequired;

  const DropdownTextFormField({
    super.key,
    required this.label,
    this.value,
    required this.items,
    required this.displayString,
    required this.onChanged,
    this.validator,
    this.isRequired = false,
  });

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<T>(
      value: value,
      items: items.map((T item) {
        return DropdownMenuItem<T>(
          value: item,
          child: Text(displayString(item)),
        );
      }).toList(),
      onChanged: onChanged,
      validator: validator ?? (
        T? value) => value == null && isRequired ? '$label is required' : null,
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      ),
      isExpanded: true,
      dropdownColor: Theme.of(context).cardColor,
    );
  }
}
