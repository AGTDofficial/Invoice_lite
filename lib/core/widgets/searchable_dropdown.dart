import 'package:flutter/material.dart';
import 'package:search_choices/search_choices.dart';

class SearchableDropdown<T> extends StatelessWidget {
  final String hint;
  final T? value;
  final List<DropdownMenuItem<T>> items;
  final ValueChanged<T?> onChanged;
  final FormFieldValidator<T>? validator;
  final bool isRequired;
  final bool enabled;
  final String? label;
  final Widget? prefixIcon;
  final bool showSearchBox;
  final String? searchHint;

  const SearchableDropdown({
    Key? key,
    required this.hint,
    required this.value,
    required this.items,
    required this.onChanged,
    this.validator,
    this.isRequired = false,
    this.enabled = true,
    this.label,
    this.prefixIcon,
    this.showSearchBox = true,
    this.searchHint,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (label != null) ...[
          RichText(
            text: TextSpan(
              text: label,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w500,
              ),
              children: [
                if (isRequired)
                  TextSpan(
                    text: ' *',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.error,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 4),
        ],
        SearchChoices.single(
          value: value,
          items: items,
          hint: hint,
          searchHint: searchHint ?? 'Search $hint',
          onChanged: enabled ? onChanged : null,
          isExpanded: true,
          displayClearIcon: false,
          underline: Container(
            height: 1.0,
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(
                  color: theme.dividerColor,
                  width: 1.0,
                ),
              ),
            ),
          ),
          selectedValueWidgetFn: (item) {
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              child: Text(
                item?.toString() ?? '',
                style: theme.textTheme.bodyMedium,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            );
          },
          menuItemStyle: MenuItemStyle(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          ),
          dropdownSearchDecoration: InputDecoration(
            hintText: hint,
            border: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
            prefixIcon: prefixIcon,
            suffixIcon: const Icon(Icons.arrow_drop_down, size: 24),
          ),
          isCaseSensitiveSearch: false,
          searchInputDecoration: InputDecoration(
            hintText: searchHint ?? 'Search $hint',
            border: const OutlineInputBorder(),
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
            prefixIcon: const Icon(Icons.search),
          ),
          selectedValueWidgetFn: (item) {
            return Text(
              item?.toString() ?? '',
              style: theme.textTheme.bodyMedium,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            );
          },
          onClear: () => onChanged(null),
          clearIcon: const Icon(Icons.clear, size: 18),
          displayItem: (item, selected) {
            return ListTile(
              title: Text(
                item.toString(),
                style: theme.textTheme.bodyMedium,
              ),
              selected: selected,
            );
          },
          validator: validator != null
              ? (value) => value == null && isRequired
                  ? 'This field is required'
                  : validator!(value)
              : null,
        ),
      ],
    );
  }
}

// Example usage:
/*
SearchableDropdown<Item>(
  hint: 'Select an item',
  label: 'Item',
  isRequired: true,
  value: selectedItem,
  items: items.map((item) => DropdownMenuItem(
    value: item,
    child: Text(item.name),
  )).toList(),
  onChanged: (value) {
    setState(() {
      selectedItem = value;
    });
  },
  prefixIcon: Icon(Icons.inventory_2_outlined),
)
*/
