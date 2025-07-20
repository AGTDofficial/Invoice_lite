import 'package:flutter/material.dart';
import 'package:invoice_lite/features/customers/presentation/screens/customers_list_screen.dart';
import 'package:invoice_lite/features/invoices/presentation/screens/add_edit_invoice_screen.dart';
import 'package:invoice_lite/features/invoices/presentation/screens/invoice_detail_screen.dart';
import 'package:invoice_lite/features/invoices/presentation/screens/select_item_screen.dart';
import 'package:invoice_lite/features/items/presentation/screens/add_edit_item_screen.dart';
import 'package:invoice_lite/features/items/presentation/screens/items_list_screen.dart';
import 'package:invoice_lite/features/items/data/item_model.dart';
import 'package:invoice_lite/features/reports/presentation/screens/reports_screen.dart';
import 'package:invoice_lite/features/customers/presentation/screens/add_edit_customer_screen.dart';

export 'package:invoice_lite/features/invoices/presentation/screens/select_item_screen.dart' show SelectedItem;

class AppRouter {
  static Route<dynamic> generateRoute(RouteSettings settings) {
    switch (settings.name) {
      case CustomersListScreen.routeName:
        return MaterialPageRoute(
          builder: (_) => const CustomersListScreen(),
          settings: settings,
        );
        
      case AddEditCustomerScreen.routeName:
        final customerId = settings.arguments as String?;
        return MaterialPageRoute(
          builder: (_) => AddEditCustomerScreen(customerId: customerId),
          settings: settings,
        );
        
      case AddEditInvoiceScreen.routeName:
        return MaterialPageRoute(
          builder: (_) => const AddEditInvoiceScreen(),
          settings: settings,
        );
        
      case InvoiceDetailScreen.routeName:
        final invoiceId = settings.arguments as int;
        return MaterialPageRoute(
          builder: (_) => InvoiceDetailScreen(invoiceId: invoiceId),
          settings: settings,
        );
        
      case SelectItemScreen.routeName:
        final args = settings.arguments as List<SelectedItem>?;
        return MaterialPageRoute(
          builder: (_) => SelectItemScreen(
            selectedItems: args ?? const [],
          ),
          settings: settings,
        );
        
      case ItemsListScreen.routeName:
        return MaterialPageRoute(
          builder: (_) => const ItemsListScreen(),
          settings: settings,
        );
        
      case AddEditItemScreen.routeName:
        final itemId = settings.arguments as int?;
        return MaterialPageRoute(
          builder: (_) => AddEditItemScreen(itemId: itemId),
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
  
  // Customer navigation
  static void navigateToCustomersList(BuildContext context) {
    Navigator.of(context).pushNamedAndRemoveUntil(
      CustomersListScreen.routeName,
      (route) => false,
    );
  }
  
  static Future<bool?> navigateToAddEditCustomer(
    BuildContext context, {
    String? customerId,
  }) async {
    return await Navigator.of(context).pushNamed<bool>(
      AddEditCustomerScreen.routeName,
      arguments: customerId,
    );
  }
  
  // Invoice navigation
  static void navigateToAddEditInvoice(BuildContext context) {
    Navigator.of(context).pushNamed(AddEditInvoiceScreen.routeName);
  }
  
  static void navigateToInvoiceDetail(BuildContext context, int invoiceId) {
    Navigator.of(context).pushNamed(
      InvoiceDetailScreen.routeName,
      arguments: invoiceId,
    );
  }
  
  // Reports navigation
  static void navigateToReports(BuildContext context) {
    Navigator.of(context).pushNamedAndRemoveUntil(
      ReportsScreen.routeName,
      (route) => false,
    );
  }
  
  static Future<List<SelectedItem>?> navigateToSelectItems(
    BuildContext context, {
    List<SelectedItem> selectedItems = const [],
  }) async {
    final result = await Navigator.of(context).push<List<SelectedItem>>(
      MaterialPageRoute(
        builder: (context) => SelectItemScreen(
          selectedItems: selectedItems,
        ),
      ),
    );
    
    return result;
  }
  
  // Item navigation
  static void navigateToItemsList(BuildContext context) {
    Navigator.of(context).pushNamedAndRemoveUntil(
      ItemsListScreen.routeName,
      (route) => false,
    );
  }
  
  static Future<bool?> navigateToAddEditItem(
    BuildContext context, {
    int? itemId,
  }) async {
    return await Navigator.of(context).pushNamed<bool>(
      AddEditItemScreen.routeName,
      arguments: itemId,
    );
  }
}
