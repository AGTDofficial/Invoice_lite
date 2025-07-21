import 'package:drift/drift.dart';
import 'package:invoice_lite/core/database/database.dart';
import 'package:invoice_lite/features/invoices/data/invoice_model.dart';
import 'package:invoice_lite/features/items/data/item_model.dart';
import 'package:invoice_lite/features/customers/data/customer_model.dart';

part 'invoice_dao.g.dart';

/// Data Access Object for the Invoices table
@DriftAccessor(tables: [Invoices, InvoiceItems, Items, Customers])
class InvoiceDao extends DatabaseAccessor<AppDatabase> with _$InvoiceDaoMixin {
  InvoiceDao(AppDatabase db) : super(db);

  /// Get all invoices
  Future<List<Invoice>> getAllInvoices() => select(invoices).get();

  /// Watch all invoices for changes
  Stream<List<Invoice>> watchAllInvoices() => select(invoices).watch();

  /// Get a single invoice by ID
  Future<Invoice?> getInvoice(int id) => 
      (select(invoices)..where((tbl) => tbl.id.equals(id))).getSingleOrNull();

  /// Get all items for an invoice
  Future<List<InvoiceItem>> getInvoiceItems(int invoiceId) => 
      (select(invoiceItems)..where((tbl) => tbl.invoiceId.equals(invoiceId))).get();

  /// Watch all items for an invoice
  Stream<List<InvoiceItem>> watchInvoiceItems(int invoiceId) => 
      (select(invoiceItems)..where((tbl) => tbl.invoiceId.equals(invoiceId))).watch();

  /// Create a new invoice with items
  Future<int> createInvoiceWithItems({
    required InvoicesCompanion invoice,
    required List<InvoiceItemsCompanion> items,
  }) async {
    return transaction(() async {
      final invoiceId = await into(invoices).insert(invoice);
      
      // Add all items with the new invoice ID
      for (var item in items) {
        await into(invoiceItems).insert(item.copyWith(
          invoiceId: Value(invoiceId),
        ));
      }
      
      return invoiceId;
    });
  }

  /// Update an existing invoice and its items
  Future<void> updateInvoiceWithItems({
    required int invoiceId,
    required InvoicesCompanion invoice,
    required List<InvoiceItemsCompanion> items,
  }) async {
    await transaction(() async {
      // Update the invoice
      await (update(invoices)..where((t) => t.id.equals(invoiceId))).write(invoice);
      
      // Delete existing items
      await (delete(invoiceItems)..where((t) => t.invoiceId.equals(invoiceId))).go();
      
      // Add updated items
      for (var item in items) {
        await into(invoiceItems).insert(item.copyWith(
          invoiceId: Value(invoiceId),
        ));
      }
    });
  }

  /// Delete an invoice and all its items
  Future<void> deleteInvoiceWithItems(int invoiceId) async {
    await transaction(() async {
      // Delete all items first
      await (delete(invoiceItems)..where((t) => t.invoiceId.equals(invoiceId))).go();
      
      // Then delete the invoice
      await (delete(invoices)..where((t) => t.id.equals(invoiceId))).go();
    });
  }

  /// Search invoices by number or customer name
  Future<List<Invoice>> searchInvoices(String query) {
    return (select(invoices)
      ..where((tbl) => tbl.invoiceNumber.like('%$query%'))
      ..orderBy([(t) => OrderingTerm.desc(t.invoiceDate)]))
        .get();
  }

  /// Get the financial year range (e.g., 24-25 for 2024-25)
  String _getFinancialYearRange() {
    final now = DateTime.now();
    final currentYear = now.year;
    final nextYear = now.year + 1;
    
    if (now.month >= 4) {
      // April to December - current year to next year (e.g., 24-25)
      final startYear = (currentYear % 100).toString().padLeft(2, '0');
      final endYear = (nextYear % 100).toString().padLeft(2, '0');
      return '$startYear-$endYear';
    } else {
      // January to March - previous year to current year (e.g., 23-24)
      final startYear = ((currentYear - 1) % 100).toString().padLeft(2, '0');
      final endYear = (currentYear % 100).toString().padLeft(2, '0');
      return '$startYear-$endYear';
    }
  }

  /// Get the next available invoice number
  Future<String> getNextInvoiceNumber() async {
    final financialYear = _getFinancialYearRange();
    const prefix = 'INV/';
    const padding = 4;
    
    // Get the highest invoice number for the current financial year
    final invoiceNumbers = await (select(invoices)
      ..where((tbl) => tbl.invoiceNumber.contains(financialYear))
      ..orderBy([(t) => OrderingTerm.desc(t.id)]))
      .get();
    
    int nextNumber = 1;
    if (invoiceNumbers.isNotEmpty) {
      // Extract the numeric part of the last invoice number and increment
      final lastNumberStr = invoiceNumbers.first.invoiceNumber
          .split('/')
          .last
          .split('-')[0];
      nextNumber = (int.tryParse(lastNumberStr) ?? 0) + 1;
    }
    
    return '$prefix${nextNumber.toString().padLeft(padding, '0')}-$financialYear';
  }
}
