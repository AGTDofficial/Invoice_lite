import 'package:drift/drift.dart';
import 'package:invoice_lite/features/customers/data/customer_model.dart';

part 'customer_dao.g.dart';

/// Data Access Object for the Customers table
@DriftAccessor(tables: [Customers])
class CustomerDao extends DatabaseAccessor<AppDatabase> with _$CustomerDaoMixin {
  final AppDatabase db;

  CustomerDao(this.db) : super(db);

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

  /// Delete a customer
  Future<int> deleteCustomer(int id) => 
      (delete(customers)..where((tbl) => tbl.id.equals(id))).go();

  /// Search customers by name, email, or phone
  Future<List<Customer>> searchCustomers(String query) {
    return (select(customers)
      ..where((tbl) => 
          tbl.name.like('%$query%') | 
          tbl.email.like('%$query%') | 
          tbl.phone.like('%$query%'))
      ..orderBy([(t) => OrderingTerm(expression: tbl.name)]))
        .get();
  }
}
