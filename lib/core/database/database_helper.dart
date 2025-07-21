import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:drift/drift.dart';
import 'package:invoice_lite/core/providers/database_provider.dart';
import 'package:invoice_lite/features/customers/data/customer_dao.dart';
import 'package:invoice_lite/features/customers/data/customer_model.dart';
import 'package:invoice_lite/features/items/data/item_dao.dart';
import 'package:invoice_lite/features/items/data/item_model.dart';
import 'package:invoice_lite/features/invoices/data/invoice_dao.dart';
import 'package:invoice_lite/core/database/database.dart';

/// A helper class that provides easy access to all DAOs and common database operations
class DatabaseHelper {
  final Ref _ref;
  
  DatabaseHelper(this._ref);
  
  // DAO getters
  ItemDao get items => _ref.read(itemDaoProvider);
  CustomerDao get customers => _ref.read(customerDaoProvider);
  InvoiceDao get invoices => _ref.read(invoiceDaoProvider);
  
  /// Initialize the database with some sample data if it's empty
  Future<void> initializeDatabase() async {
    // Check if we already have data
    final hasItems = await items.getAllItems().then((list) => list.isNotEmpty);
    
    if (!hasItems) {
      await _seedSampleData();
    }
  }
  
  /// Seed the database with sample data
  Future<void> _seedSampleData() async {
    // Add sample items
    await items.addItem(ItemsCompanion.insert(
      name: 'Product A',
      itemCode: 'PROD-001',
      description: const Value('Sample product A'),
      saleRate: 99.99,
      purchaseRate: 49.99,
    ));
    
    await items.addItem(ItemsCompanion.insert(
      name: 'Product B',
      itemCode: 'PROD-002',
      description: const Value('Sample product B'),
      saleRate: 149.99,
      purchaseRate: 79.99,
    ));
    
    // Add sample customers
    await customers.addCustomer(CustomersCompanion.insert(
      name: 'John Doe',
      email: const Value('john@example.com'),
      phone: const Value('+1234567890'),
      address: const Value('123 Main St'),
      city: const Value('New York'),
      state: const Value('NY'),
    ));
    
    await customers.addCustomer(CustomersCompanion.insert(
      name: 'Jane Smith',
      email: const Value('jane@example.com'),
      phone: const Value('+1987654321'),
      address: const Value('456 Oak Ave'),
      city: const Value('Los Angeles'),
      state: const Value('CA'),
    ));
  }
  
  /// Clear all data from the database (for testing/development)
  Future<void> clearDatabase() async {
    // Delete all invoice items
    final allInvoices = await invoices.getAllInvoices();
    for (final invoice in allInvoices) {
      await invoices.deleteInvoiceWithItems(invoice.id);
    }
    
    // Delete all customers
    final allCustomers = await customers.getAllCustomers();
    for (final customer in allCustomers) {
      await customers.deleteCustomer(customer.id);
    }
    
    // Delete all items
    final allItems = await items.getAllItems();
    for (final item in allItems) {
      await items.deleteItem(item.id);
    }
  }
}

/// Provider for the DatabaseHelper
final databaseHelperProvider = Provider<DatabaseHelper>((ref) {
  return DatabaseHelper(ref);
});
