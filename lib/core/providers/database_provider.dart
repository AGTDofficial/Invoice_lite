import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:invoice_lite/core/database/database.dart';
import 'package:invoice_lite/features/items/data/item_dao.dart';
import 'package:invoice_lite/features/customers/data/customer_dao.dart';
import 'package:invoice_lite/features/invoices/data/invoice_dao.dart';

/// Provider for the database instance
final databaseProvider = Provider<AppDatabase>((ref) {
  return AppDatabase();
});

/// Provider for the ItemDao
final itemDaoProvider = Provider<ItemDao>((ref) {
  final db = ref.watch(databaseProvider);
  return ItemDao(db);
});

/// Provider for the CustomerDao
final customerDaoProvider = Provider<CustomerDao>((ref) {
  final db = ref.watch(databaseProvider);
  return CustomerDao(db);
});

/// Provider for the InvoiceDao
final invoiceDaoProvider = Provider<InvoiceDao>((ref) {
  final db = ref.watch(databaseProvider);
  return InvoiceDao(db);
});
