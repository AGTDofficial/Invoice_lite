import 'package:drift/drift.dart';
import 'package:invoice_lite/features/invoices/data/invoice_model.dart';

part 'invoice_dao.g.dart';

/// Data Access Object for the Invoices table
@DriftAccessor(tables: [Invoices, InvoiceItems])
class InvoiceDao extends DatabaseAccessor<AppDatabase> with _$InvoiceDaoMixin {
  final AppDatabase db;

  InvoiceDao(this.db) : super(db);

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
      ..where((tbl) => 
          tbl.invoiceNumber.like('%$query%') |
          // Note: This would ideally join with the customers table for better search
          const Constant(false).equals(true)) // Placeholder for customer name search
      ..orderBy([(t) => OrderingTerm.desc(t.invoiceDate)]))
        .get();
  }

  /// Get the next available invoice number
  Future<String> getNextInvoiceNumber() async {
    // This is a simple implementation that gets the max invoice number and increments it
    // You might want to implement a more sophisticated numbering system
    final maxInvoice = await selectOnly(invoices)
      ..addColumns([invoices.invoiceNumber])
      ..orderBy([OrderByTerm.desc(invoices.id)])
      ..limit(1);

    final result = await maxInvoice.getSingleOrNull();
    
    if (result == null) {
      // First invoice
      return 'INV-${DateTime.now().year}-0001';
    }

    // Extract the number part and increment it
    final parts = result.read(invoices.invoiceNumber)!.split('-');
    final number = int.tryParse(parts.last) ?? 0;
    return 'INV-${DateTime.now().year}-${(number + 1).toString().padLeft(4, '0')}';
  }
}
