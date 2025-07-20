import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:invoice_lite/core/database/database.dart';
import 'package:invoice_lite/features/customers/data/customer_dao.dart';

/// Provider for the customer DAO
final customerDaoProvider = Provider<CustomerDao>((ref) {
  final db = ref.watch(databaseProvider);
  return CustomerDao(db);
});

/// Provider for the list of all customers
final customersListProvider = StreamProvider<List<Customer>>((ref) {
  final customerDao = ref.watch(customerDaoProvider);
  return customerDao.watchAllCustomers();
});

/// Provider for a single customer by ID
final customerProvider = FutureProvider.family<Customer?, int>((ref, id) async {
  final customerDao = ref.watch(customerDaoProvider);
  return await customerDao.getCustomer(id);
});
