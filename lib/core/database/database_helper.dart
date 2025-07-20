import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:invoice_lite/core/providers/database_provider.dart';
import 'package:invoice_lite/features/customers/data/customer_dao.dart';
import 'package:invoice_lite/features/invoices/data/invoice_dao.dart';
import 'package:invoice_lite/features/items/data/item_dao.dart';

// Import generated models and companions
import 'package:invoice_lite/features/items/data/item_model.dart';
import 'package:invoice_lite/features/customers/data/customer_model.dart';
import 'package:invoice_lite/features/invoices/data/invoice_model.dart';

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
      description: 'Sample product A',
      saleRate: 99.99,
      purchaseRate: 49.99,
      currentStock: 100,
      minStockLevel: 10,
      unit: 'PCS',
    ));
    
    await items.addItem(ItemsCompanion.insert(
      name: 'Product B',
      itemCode: 'PROD-002',
      description: 'Sample product B',
      saleRate: 149.99,
      purchaseRate: 79.99,
      currentStock: 50,
      minStockLevel: 5,
      unit: 'PCS',
    ));
    
    // Add sample customers
    await customers.addCustomer(CustomersCompanion.insert(
      name: 'John Doe',
      email: 'john@example.com',
      phone: '+1234567890',
      address: '123 Main St',
      city: 'New York',
      state: 'NY',
      country: 'USA',
      pinCode: '10001',
      type: 'retail',
      balance: 0,
    ));
    
    await customers.addCustomer(CustomersCompanion.insert(
      name: 'Jane Smith',
      email: 'jane@example.com',
      phone: '+1987654321',
      address: '456 Oak Ave',
      city: 'Los Angeles',
      state: 'CA',
      country: 'USA',
      pinCode: '90001',
      type: 'wholesale',
      balance: 0,
    ));
  }
  
  /// Clear all data from the database (for testing/development)
  Future<void> clearDatabase() async {
    // Delete all invoice items
    await invoices.deleteInvoiceItems();
    
    // Delete all invoices
    final allInvoices = await invoices.getAllInvoices();
    for (final invoice in allInvoices) {
      await invoices.deleteInvoice(invoice.id);
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
