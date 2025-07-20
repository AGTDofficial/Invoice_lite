import 'package:flutter/material.dart';
import 'package:invoice_lite/features/invoices/presentation/screens/add_edit_invoice_screen.dart';
import 'package:invoice_lite/features/invoices/presentation/screens/select_item_screen.dart';

class AppRouter {
  static Route<dynamic> generateRoute(RouteSettings settings) {
    switch (settings.name) {
      case AddEditInvoiceScreen.routeName:
        return MaterialPageRoute(
          builder: (_) => const AddEditInvoiceScreen(),
          settings: settings,
        );
        
      case SelectItemScreen.routeName:
        final args = settings.arguments as Map<String, dynamic>?;
        return MaterialPageRoute(
          builder: (_) => SelectItemScreen(
            selectedItems: args?['selectedItems'] ?? [],
          ),
          settings: settings,
        );
        
      default:
        return MaterialPageRoute(
          builder: (_) => Scaffold(
            body: Center(
              child: Text('No route defined for ${settings.name}'),
            ),
          ),
        );
    }
  }
  
  // Static navigation methods
  static void navigateToAddEditInvoice(BuildContext context) {
    Navigator.of(context).pushNamed(AddEditInvoiceScreen.routeName);
  }
  
  static Future<List<dynamic>?> navigateToSelectItems(
    BuildContext context, {
    required List<dynamic> selectedItems,
  }) async {
    return await Navigator.of(context).pushNamed(
      SelectItemScreen.routeName,
      arguments: {
        'selectedItems': selectedItems,
      },
    );
  }
}
