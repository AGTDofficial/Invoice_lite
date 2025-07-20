import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:invoice_lite/features/reports/data/report_repository.dart';
import 'package:invoice_lite/core/database/database.dart';
import 'package:invoice_lite/features/invoices/data/invoice_dao.dart';
import 'package:invoice_lite/features/items/data/item_dao.dart';
import 'package:invoice_lite/features/customers/data/customer_dao.dart';

final reportRepositoryProvider = Provider<ReportRepository>((ref) {
  final db = ref.watch(databaseProvider);
  final invoiceDao = ref.watch(invoiceDaoProvider);
  final itemDao = ref.watch(itemDaoProvider);
  final customerDao = ref.watch(customerDaoProvider);
  
  return ReportRepository(
    db: db,
    invoiceDao: invoiceDao,
    itemDao: itemDao,
    customerDao: customerDao,
  );
});

final salesSummaryProvider = FutureProvider.family<Map<String, dynamic>, ({DateTime startDate, DateTime endDate})>(
  (ref, dateRange) async {
    final repository = ref.watch(reportRepositoryProvider);
    return repository.getSalesSummary(
      startDate: dateRange.startDate,
      endDate: dateRange.endDate,
    );
  },
);

final topSellingItemsProvider = FutureProvider.family<List<Map<String, dynamic>>, ({DateTime startDate, DateTime endDate, int limit})>(
  (ref, params) async {
    final repository = ref.watch(reportRepositoryProvider);
    return repository.getTopSellingItems(
      startDate: params.startDate,
      endDate: params.endDate,
      limit: params.limit,
    );
  },
);

final salesByCustomerProvider = FutureProvider.family<List<Map<String, dynamic>>, ({DateTime startDate, DateTime endDate, int limit})>(
  (ref, params) async {
    final repository = ref.watch(reportRepositoryProvider);
    return repository.getSalesByCustomer(
      startDate: params.startDate,
      endDate: params.endDate,
      limit: params.limit,
    );
  },
);

final inventoryStatusProvider = FutureProvider<Map<String, dynamic>>(
  (ref) async {
    final repository = ref.watch(reportRepositoryProvider);
    return repository.getInventoryStatus();
  },
);

final financialSummaryProvider = FutureProvider.family<Map<String, dynamic>, ({DateTime startDate, DateTime endDate})>(
  (ref, dateRange) async {
    final repository = ref.watch(reportRepositoryProvider);
    return repository.getFinancialSummary(
      startDate: dateRange.startDate,
      endDate: dateRange.endDate,
    );
  },
);
