import 'package:drift/drift.dart';
import 'package:invoice_lite/core/database/database.dart';
import 'package:invoice_lite/features/customers/data/customer_model.dart';

part 'customer_dao.g.dart';

/// Data Access Object for the Customers table
@DriftAccessor(tables: [Customers])
class CustomerDao extends DatabaseAccessor<AppDatabase> with _$CustomerDaoMixin {
  CustomerDao(AppDatabase db) : super(db);

  /// Get all customers
  Future<List<Customer>> getAllCustomers() => select(customers).get();

  /// Watch all customers for changes
  Stream<List<Customer>> watchAllCustomers() => select(customers).watch();

  /// Get a single customer by ID
  Future<Customer?> getCustomer(int id) => 
      (select(customers)..where((tbl) => tbl.id.equals(id))).getSingleOrNull();

  /// Add a new customer
  Future<int> addCustomer(CustomersCompanion entry) => into(customers).insert(entry);

  /// Update an existing customer
  Future<bool> updateCustomer(CustomersCompanion entry) => update(customers).replace(entry);
  
  /// Convert Customer to CustomersCompanion for update
  CustomersCompanion toCompanion(Customer customer, [bool forUpdate = false]) {
    return CustomersCompanion(
      id: Value(customer.id),
      name: Value(customer.name),
      email: Value(customer.email),
      phone: Value(customer.phone),
      address: Value(customer.address),
      city: Value(customer.city),
      state: Value(customer.state),
      country: Value(customer.country),
      pinCode: Value(customer.pinCode),
      taxId: Value(customer.taxId),
      type: Value(customer.type),
      balance: Value(customer.balance),
      isActive: Value(customer.isActive),
      updatedAt: Value(DateTime.now()),
      createdAt: forUpdate ? Value(customer.createdAt) : Value(DateTime.now()),
    );
  }

  /// Delete a customer
  Future<int> deleteCustomer(int id) => 
      (delete(customers)..where((tbl) => tbl.id.equals(id))).go();

  /// Search customers by name, email, or phone
  Future<List<Customer>> searchCustomers(String query) {
    return (select(customers)
      ..where((tbl) {
        final searchTerm = '%$query%';
        return tbl.name.like(searchTerm) | 
               tbl.email.like(searchTerm) | 
               tbl.phone.like(searchTerm);
      })
      ..orderBy([(t) => OrderingTerm(expression: t.name)]))
      .get();
  }
}
