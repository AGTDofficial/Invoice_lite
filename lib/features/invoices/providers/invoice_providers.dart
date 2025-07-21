import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:invoice_lite/core/database/database.dart';
import 'package:invoice_lite/features/invoices/data/invoice_dao.dart';

// Provider for InvoiceDao
final invoiceDaoProvider = Provider<InvoiceDao>((ref) {
  final db = ref.watch(databaseProvider);
  return InvoiceDao(db.db);
});

// Provider for invoice list stream
final invoiceListStreamProvider = StreamProvider.autoDispose<List<Invoice>>((ref) {
  final dao = ref.watch(invoiceDaoProvider);
  return dao.watchAllInvoices();
});

// Provider for a single invoice stream
final invoiceStreamProvider = StreamProvider.autoDispose.family<Invoice?, int>((ref, id) {
  final dao = ref.watch(invoiceDaoProvider);
  return dao.watchInvoice(id);
});

// Provider for invoice items stream
final invoiceItemsStreamProvider = StreamProvider.autoDispose.family<List<InvoiceItem>, int>((ref, invoiceId) {
  final dao = ref.watch(invoiceDaoProvider);
  return dao.watchInvoiceItems(invoiceId);
});

// Provider for invoice statistics
final invoiceStatsProvider = FutureProvider.autoDispose<Map<String, dynamic>>((ref) async {
  final dao = ref.watch(invoiceDaoProvider);
  
  final totalInvoices = await dao.getInvoiceCount();
  final totalRevenue = await dao.getTotalRevenue();
  final pendingInvoices = await dao.getPendingInvoicesCount();
  
  return {
    'totalInvoices': totalInvoices,
    'totalRevenue': totalRevenue,
    'pendingInvoices': pendingInvoices,
  };
});

// Provider for recent invoices
final recentInvoicesProvider = StreamProvider.autoDispose<List<Invoice>>((ref) {
  final dao = ref.watch(invoiceDaoProvider);
  return dao.watchRecentInvoices(limit: 5);
});

// Provider for customer invoices
final customerInvoicesProvider = StreamProvider.autoDispose.family<List<Invoice>, int>((ref, customerId) {
  final dao = ref.watch(invoiceDaoProvider);
  return dao.watchInvoicesByCustomer(customerId);
});
