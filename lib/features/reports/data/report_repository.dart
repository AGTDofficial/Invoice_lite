import 'package:drift/drift.dart';
import 'package:invoice_lite/core/database/database.dart';
import 'package:invoice_lite/features/invoices/data/invoice_dao.dart';
import 'package:invoice_lite/features/items/data/item_dao.dart';
import 'package:invoice_lite/features/customers/data/customer_dao.dart';

// Add this import for OrderByTerm
import 'package:drift/drift.dart' show OrderBy, OrderingMode;

class ReportRepository {
  final AppDatabase _db;
  final InvoiceDao _invoiceDao;
  final ItemDao _itemDao;
  final CustomerDao _customerDao;

  ReportRepository({
    required AppDatabase db,
    required InvoiceDao invoiceDao,
    required ItemDao itemDao,
    required CustomerDao customerDao,
  })  : _db = db,
        _invoiceDao = invoiceDao,
        _itemDao = itemDao,
        _customerDao = customerDao;

  // Get sales summary by date range
  Future<Map<String, dynamic>> getSalesSummary({
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    final query = _db.selectOnly(_db.invoices)
      ..addColumns([
        _db.invoices.status,
        _db.invoices.total.sum(),
        _db.invoices.id.count(),
      ])
      ..where(_db.invoices.invoiceDate.isBetweenValues(startDate, endDate))
      ..groupBy([_db.invoices.status]);

    final results = await query.get();
    
    double totalSales = 0;
    int totalInvoices = 0;
    final statuses = <String, Map<String, dynamic>>{};
    
    for (final row in results) {
      final status = row.read(_db.invoices.status) ?? 'unknown';
      final total = row.read(_db.invoices.total.sum()) ?? 0;
      final count = row.read(_db.invoices.id.count()) ?? 0;
      
      statuses[status] = {
        'total': total,
        'count': count,
      };
      
      totalSales += total;
      totalInvoices += count;
    }
    
    return {
      'totalSales': totalSales,
      'totalInvoices': totalInvoices,
      'statuses': statuses,
      'startDate': startDate,
      'endDate': endDate,
    };
  }

  // Get top selling items
  Future<List<Map<String, dynamic>>> getTopSellingItems({
    required DateTime startDate,
    required DateTime endDate,
    int limit = 10,
  }) async {
    final query = _db.selectOnly(_db.invoiceItems)
      ..join([
        innerJoin(
          _db.items,
          _db.items.id.equalsExp(_db.invoiceItems.itemId),
        ),
        innerJoin(
          _db.invoices,
          _db.invoices.id.equalsExp(_db.invoiceItems.invoiceId),
        ),
      ])
      ..addColumns([
        _db.items.id,
        _db.items.name,
        _db.invoiceItems.quantity.sum(),
        _db.invoiceItems.total.sum(),
      ])
      ..where(_db.invoices.invoiceDate.isBetweenValues(startDate, endDate))
      ..groupBy([_db.items.id, _db.items.name])
      ..orderBy([
        (t) => OrderingTerm.desc(
          _db.invoiceItems.quantity.sum(),
        ),
      ])
      ..limit(limit);

    final results = await query.get();
    
    return results.map((row) {
      return {
        'id': row.read(_db.items.id),
        'name': row.read(_db.items.name) ?? 'Unknown Item',
        'quantity': row.read(_db.invoiceItems.quantity.sum()) ?? 0,
        'total': row.read(_db.invoiceItems.total.sum()) ?? 0,
      };
    }).toList();
  }

  // Get sales by customer
  Future<List<Map<String, dynamic>>> getSalesByCustomer({
    required DateTime startDate,
    required DateTime endDate,
    int limit = 10,
  }) async {
    final query = _db.selectOnly(_db.invoices)
      ..join([
        innerJoin(
          _db.customers,
          _db.customers.id.equalsExp(_db.invoices.customerId),
        ),
      ])
      ..addColumns([
        _db.customers.id,
        _db.customers.name,
        _db.invoices.total.sum(),
        _db.invoices.id.count(),
      ])
      ..where(_db.invoices.invoiceDate.isBetweenValues(startDate, endDate))
      ..groupBy([_db.customers.id, _db.customers.name])
      ..orderBy([
        (t) => OrderingTerm.desc(_db.invoices.total.sum()),
      ])
      ..limit(limit);

    final results = await query.get();
    
    return results.map((row) {
      return {
        'id': row.read(_db.customers.id),
        'name': row.read(_db.customers.name) ?? 'Unknown Customer',
        'total': row.read(_db.invoices.total.sum()) ?? 0,
        'count': row.read(_db.invoices.id.count()) ?? 0,
      };
    }).toList();
  }

  // Get inventory status
  Future<Map<String, dynamic>> getInventoryStatus() async {
    final query = _db.selectOnly(_db.items)
      ..addColumns([
        _db.items.currentStock.avg(),
        _db.items.currentStock.sum(),
        _db.items.id.count(),
        _db.case_(
          when: _db.items.currentStock.lessOrEqual(_db.items.minStockLevel),
          then: const Constant(1),
          orElse: const Constant(0),
        ).sum().as('low_stock_count'),
      ]);

    final result = await query.getSingle();
    
    return {
      'averageStock': result.read(_db.items.currentStock.avg()) ?? 0,
      'totalStock': result.read(_db.items.currentStock.sum()) ?? 0,
      'totalItems': result.read(_db.items.id.count()) ?? 0,
      'lowStockCount': result.read<int>('low_stock_count') ?? 0,
    };
  }

  // Get financial summary
  Future<Map<String, dynamic>> getFinancialSummary({
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    final query = _db.selectOnly(_db.invoices)
      ..addColumns([
        _db.invoices.total.sum(),
        _db.invoices.taxAmount.sum(),
        _db.invoices.discountAmount.sum(),
        _db.invoices.subtotal.sum(),
      ])
      ..where(_db.invoices.invoiceDate.isBetweenValues(startDate, endDate));

    final result = await query.getSingle();
    
    return {
      'grossSales': result.read(_db.invoices.subtotal.sum()) ?? 0,
      'totalTax': result.read(_db.invoices.taxAmount.sum()) ?? 0,
      'totalDiscount': result.read(_db.invoices.discountAmount.sum()) ?? 0,
      'netSales': result.read(_db.invoices.total.sum()) ?? 0,
    };
  }
}
