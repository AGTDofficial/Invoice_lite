import 'package:flutter/material.dart';

class AppColors {
  // Primary colors
  static const Color primary = Color(0xFF2196F3);
  static const Color primaryDark = Color(0xFF1976D2);
  static const Color primaryLight = Color(0xFFBBDEFB);
  
  // Accent colors
  static const Color accent = Color(0xFFFF9800);
  
  // Background colors
  static const Color background = Color(0xFFFFFFFF);
  static const Color surface = Color(0xFFF5F5F5);
  
  // Text colors
  static const Color textPrimary = Color(0xFF212121);
  static const Color textSecondary = Color(0xFF757575);
  static const Color textOnPrimary = Color(0xFFFFFFFF);
  static const Color textOnAccent = Color(0xFFFFFFFF);
  
  // Status colors
  static const Color success = Color(0xFF4CAF50);
  static const Color error = Color(0xFFF44336);
  static const Color warning = Color(0xFFFFC107);
  static const Color info = Color(0xFF2196F3);
  
  // Divider color
  static const Color divider = Color(0xFFE0E0E0);
  
  // Disabled colors
  static const Color disabled = Color(0xFFBDBDBD);
  static const Color disabledText = Color(0xFF9E9E9E);
  
  // Other UI elements
  static const Color card = Color(0xFFFFFFFF);
  static const Color border = Color(0xFFE0E0E0);
  static const Color shadow = Color(0x1F000000);
  
  // Custom colors for specific UI elements
  static const Color buttonPrimary = primary;
  static const Color buttonPrimaryText = textOnPrimary;
  static const Color buttonSecondary = Color(0xFFE0E0E0);
  static const Color buttonSecondaryText = textPrimary;
  
  // Form field colors
  static const Color inputBorder = Color(0xFFBDBDBD);
  static const Color inputFocusedBorder = primary;
  static const Color inputErrorBorder = error;
  static const Color inputBackground = Color(0xFFFFFFFF);
  
  // App bar
  static const Color appBarBackground = primary;
  static const Color appBarText = textOnPrimary;
  
  // Bottom navigation
  static const Color bottomNavBackground = Color(0xFFFFFFFF);
  static const Color bottomNavSelectedItem = primary;
  static const Color bottomNavUnselectedItem = Color(0xFF9E9E9E);
  
  // Tab bar
  static const Color tabBarBackground = Color(0xFFFFFFFF);
  static const Color tabBarSelected = primary;
  static const Color tabBarUnselected = textSecondary;
  static const Color tabBarIndicator = primary;
  
  // List items
  static const Color listItem = Color(0xFFFFFFFF);
  static const Color listItemSelected = Color(0xFFE3F2FD);
  static const Color listItemHover = Color(0xFFF5F5F5);
  
  // Status indicators
  static const Color statusActive = Color(0xFF4CAF50);
  static const Color statusInactive = Color(0xFF9E9E9E);
  static const Color statusPending = Color(0xFFFFC107);
  
  // Invoice status colors
  static const Color invoicePaid = Color(0xFF4CAF50);
  static const Color invoiceUnpaid = Color(0xFFFFC107);
  static const Color invoiceOverdue = Color(0xFFF44336);
  static const Color invoiceDraft = Color(0xFF9E9E9E);
  
  // Chart colors
  static const List<Color> chartColors = [
    Color(0xFF2196F3), // Blue
    Color(0xFFFF9800), // Orange
    Color(0xFF4CAF50), // Green
    Color(0xFFF44336), // Red
    Color(0xFF9C27B0), // Purple
    Color(0xFF00BCD4), // Cyan
    Color(0xFFFFEB3B), // Yellow
    Color(0xFF795548), // Brown
  ];
}
