import 'package:flutter/material.dart';

class CustomTextField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final String hint;
  final IconData? prefixIcon;
  final Widget? suffixIcon;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final TextCapitalization textCapitalization;
  final bool obscureText;
  final int? maxLines;
  final int? minLines;
  final int? maxLength;
  final bool enabled;
  final bool readOnly;
  final bool autofocus;
  final Function(String)? onChanged;
  final Function()? onTap;
  final Function(String)? onFieldSubmitted;
  final String? Function(String?)? validator;
  final TextAlign textAlign;
  final FocusNode? focusNode;
  final String? initialValue;
  final bool expands;
  final TextAlignVertical? textAlignVertical;
  final String? counterText;
  final String? errorText;
  final String? helperText;
  final InputDecoration? decoration;
  final EdgeInsetsGeometry? contentPadding;
  final bool showCursor;

  const CustomTextField({
    Key? key,
    required this.controller,
    required this.label,
    required this.hint,
    this.prefixIcon,
    this.suffixIcon,
    this.keyboardType,
    this.textInputAction,
    this.textCapitalization = TextCapitalization.none,
    this.obscureText = false,
    this.maxLines = 1,
    this.minLines,
    this.maxLength,
    this.enabled = true,
    this.readOnly = false,
    this.autofocus = false,
    this.onChanged,
    this.onTap,
    this.onFieldSubmitted,
    this.validator,
    this.textAlign = TextAlign.start,
    this.focusNode,
    this.initialValue,
    this.expands = false,
    this.textAlignVertical,
    this.counterText,
    this.errorText,
    this.helperText,
    this.decoration,
    this.contentPadding,
    this.showCursor = true,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      textInputAction: textInputAction,
      textCapitalization: textCapitalization,
      obscureText: obscureText,
      maxLines: maxLines,
      minLines: minLines,
      maxLength: maxLength,
      enabled: enabled,
      readOnly: readOnly,
      autofocus: autofocus,
      onChanged: onChanged,
      onTap: onTap,
      onFieldSubmitted: onFieldSubmitted,
      validator: validator,
      textAlign: textAlign,
      focusNode: focusNode,
      initialValue: initialValue,
      expands: expands,
      textAlignVertical: textAlignVertical,
      showCursor: showCursor,
      decoration: decoration ?? InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: prefixIcon != null ? Icon(prefixIcon) : null,
        suffixIcon: suffixIcon,
        counterText: counterText,
        errorText: errorText,
        helperText: helperText,
        contentPadding: contentPadding ?? const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 16,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(
            color: theme.dividerColor,
            width: 1,
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(
            color: theme.dividerColor,
            width: 1,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(
            color: theme.primaryColor,
            width: 2,
          ),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(
            color: theme.colorScheme.error,
            width: 1,
          ),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(
            color: theme.colorScheme.error,
            width: 2,
          ),
        ),
        disabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(
            color: theme.disabledColor,
            width: 1,
          ),
        ),
      ),
    );
  }
}
