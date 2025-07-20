import 'package:drift/drift.dart';

// Import other table models
import 'package:invoice_lite/features/items/data/item_model.dart';
import 'package:invoice_lite/features/customers/data/customer_model.dart';

// This is the table definition for invoices
@DataClassName('Invoice')
class Invoices extends Table {
  // Auto-incrementing integer ID
  IntColumn get id => integer().autoIncrement()();
  
  // Invoice details
  TextColumn get invoiceNumber => text().withLength(min: 1, max: 50)();
  
  // Customer reference
  IntColumn get customerId => integer().nullable().references(Customers, #id)();
  
  // Invoice dates
  DateTimeColumn get invoiceDate => dateTime()();
  DateTimeColumn get dueDate => dateTime().nullable()();
  
  // Status (draft, sent, paid, cancelled, etc.)
  TextColumn get status => text().withDefault(const Constant('draft'))();
  
  // Totals
  RealColumn get subtotal => real().withDefault(const Constant(0))();
  RealColumn get taxAmount => real().withDefault(const Constant(0))();
  RealColumn get discountAmount => real().withDefault(const Constant(0))();
  RealColumn get total => real().withDefault(const Constant(0))();
  
  // Payment information
  TextColumn get paymentMethod => text().nullable()();
  TextColumn get paymentStatus => text().withDefault(const Constant('unpaid'))();
  
  // Notes and terms
  TextColumn get notes => text().nullable()();
  TextColumn get terms => text().nullable()();
  
  // Timestamps
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();
  
  // Ensure invoice numbers are unique
  @override
  List<Set<Column<Object>>>? get uniqueKeys => [
    {invoiceNumber},
  ];
}

// This is the table definition for invoice items
@DataClassName('InvoiceItem')
class InvoiceItems extends Table {
  // Auto-incrementing integer ID
  IntColumn get id => integer().autoIncrement()();
  
  // Invoice reference
  IntColumn get invoiceId => integer().references(Invoices, #id)();
  
  // Item reference
  IntColumn get itemId => integer().references(Items, #id)();
  
  // Item details at the time of invoice
  TextColumn get description => text().nullable()();
  RealColumn get quantity => real()();
  RealColumn get unitPrice => real()();
  
  // Discount and tax
  RealColumn get discountPercent => real().withDefault(const Constant(0))();
  RealColumn get taxPercent => real().withDefault(const Constant(0))();
  
  // Calculated amounts
  RealColumn get amount => real()();
  RealColumn get discountAmount => real().withDefault(const Constant(0))();
  RealColumn get taxAmount => real().withDefault(const Constant(0))();
  RealColumn get total => real()();
}
