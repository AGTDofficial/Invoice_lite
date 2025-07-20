import 'package:drift/drift.dart';

// This is the table definition for customers
@DataClassName('Customer')
class Customers extends Table {
  // Auto-incrementing integer ID
  IntColumn get id => integer().autoIncrement()();
  
  // Customer details
  TextColumn get name => text().withLength(min: 1, max: 100)();
  TextColumn get email => text().nullable()();
  TextColumn get phone => text().nullable()();
  
  // Address information
  TextColumn get address => text().nullable()();
  TextColumn get city => text().nullable()();
  TextColumn get state => text().nullable()();
  TextColumn get country => text().withDefault(const Constant('India'))();
  TextColumn get pinCode => text().nullable()();
  
  // Tax information (GST, etc.)
  TextColumn get taxId => text().nullable()();
  
  // Customer type (e.g., regular, wholesale, retail)
  TextColumn get type => text().withDefault(const Constant('retail'))();
  
  // Account balance (positive means customer owes money, negative means credit)
  RealColumn get balance => real().withDefault(const Constant(0))();
  
  // Timestamps
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();
  
  // Ensure email is unique if provided
  @override
  List<Set<Column<Object>>>? get uniqueKeys => [
    {email},
  ];
}
