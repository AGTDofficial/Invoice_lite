import 'package:flutter/material.dart';

class QuantitySelector extends StatelessWidget {
  static const double _buttonSize = 24.0;
  final int quantity;
  final ValueChanged<int> onChanged;
  
  const QuantitySelector({
    super.key,
    required this.quantity,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;
    
    return Container(
      decoration: BoxDecoration(
        color: isDarkMode ? Colors.grey[850] : Colors.grey[100],
        border: Border.all(
          color: isDarkMode ? Colors.grey[700]! : Colors.grey[300]!,
          width: 1.0,
        ),
        borderRadius: BorderRadius.circular(20.0),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 2.0,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Decrease button
          Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: const BorderRadius.horizontal(left: Radius.circular(20.0)),
              onTap: quantity > 0 ? () => onChanged(quantity - 1) : null,
              child: Container(
                width: _buttonSize,
                height: _buttonSize,
                alignment: Alignment.center,
                child: Icon(
                  Icons.remove,
                  size: 16,
                  color: quantity > 0 ? theme.colorScheme.primary : theme.disabledColor,
                ),
              ),
            ),
          ),
          
          // Quantity display
          Container(
            width: _buttonSize,
            height: _buttonSize,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              border: Border.symmetric(
                vertical: BorderSide(
                  color: isDarkMode ? Colors.grey[700]! : Colors.grey[300]!,
                  width: 1.0,
                ),
              ),
            ),
            child: Text(
              quantity.toString(),
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          
          // Increase button
          Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: const BorderRadius.horizontal(right: Radius.circular(20.0)),
              onTap: () => onChanged(quantity + 1),
              child: Container(
                width: _buttonSize,
                height: _buttonSize,
                alignment: Alignment.center,
                child: Icon(
                  Icons.add,
                  size: 16,
                  color: theme.colorScheme.primary,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
