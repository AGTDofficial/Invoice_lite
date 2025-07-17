import 'package:flutter/material.dart';
import 'package:flutter_typeahead/flutter_typeahead.dart';

class SmartComboField<T> extends StatelessWidget {
  final TextEditingController controller;
  final List<T> items;
  final String Function(T) itemAsString;
  final String labelText;
  final String? hintText;
  final Function(T)? onSelected;
  final FocusNode? focusNode;
  final TextInputAction? textInputAction;
  final Function(String)? onSubmitted;
  final String? Function(String?)? validator;
  final bool autofocus;
  final Widget Function(BuildContext, T)? itemBuilder;
  final bool hideOnEmpty;
  final bool hideOnError;
  final bool hideOnLoading;

  const SmartComboField({
    Key? key,
    required this.controller,
    required this.items,
    required this.itemAsString,
    required this.labelText,
    this.hintText,
    this.onSelected,
    this.focusNode,
    this.textInputAction,
    this.onSubmitted,
    this.validator,
    this.autofocus = false,
    this.itemBuilder,
    this.hideOnEmpty = true,
    this.hideOnError = true,
    this.hideOnLoading = true,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return TypeAheadField<T>(
      controller: controller,
      focusNode: focusNode,
      builder: (context, controller, focusNode) {
        return TextField(
          controller: controller,
          focusNode: focusNode,
          textInputAction: textInputAction,
          autofocus: autofocus,
          onSubmitted: onSubmitted,
          decoration: InputDecoration(
            labelText: labelText,
            hintText: hintText,
            border: const OutlineInputBorder(),
            suffixIcon: controller.text.isNotEmpty
                ? IconButton(
                    icon: const Icon(Icons.clear, size: 20),
                    onPressed: () {
                      controller.clear();
                      if (onSelected != null) onSelected!(null as T);
                    },
                  )
                : null,
          ),
        );
      },
      suggestionsCallback: (pattern) {
        if (pattern.isEmpty) return [];
        return items.where((item) {
          final itemStr = itemAsString(item).toLowerCase();
          return itemStr.contains(pattern.toLowerCase());
        }).toList();
      },
      itemBuilder: (context, item) => itemBuilder?.call(context, item) ?? _defaultItemBuilder(context, item),
      onSelected: (T suggestion) {
        final displayString = itemAsString(suggestion);
        controller.text = displayString;
        if (onSelected != null) onSelected!(suggestion);
      },
      hideOnEmpty: hideOnEmpty,
      hideOnError: hideOnError,
      hideOnLoading: hideOnLoading,
      emptyBuilder: (context) => const Padding(
        padding: EdgeInsets.all(8.0),
        child: Text('No matches found'),
      ),
    );
  }

  Widget _defaultItemBuilder(BuildContext context, T item) {
    return ListTile(
      title: Text(itemAsString(item)),
      dense: true,
    );
  }
}
