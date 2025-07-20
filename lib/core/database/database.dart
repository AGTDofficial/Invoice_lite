import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

// Import all table models
import 'package:invoice_lite/features/items/data/item_model.dart';
import 'package:invoice_lite/features/customers/data/customer_model.dart';
import 'package:invoice_lite/features/invoices/data/invoice_model.dart';

// Import DAOs
import 'package:invoice_lite/features/items/data/item_dao.dart';
import 'package:invoice_lite/features/customers/data/customer_dao.dart';
import 'package:invoice_lite/features/invoices/data/invoice_dao.dart';

part 'database.g.dart';

/// The main database class that manages all tables and DAOs
@DriftDatabase(
  tables: [
    Items,
    Customers,
    Invoices,
    InvoiceItems,
  ],
  daos: [
    ItemDao,
    CustomerDao,
    InvoiceDao,
  ],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  @override
  int get schemaVersion => 1;

  // Run database migrations
  @override
  MigrationStrategy get migration => MigrationStrategy(
        onCreate: (Migrator m) async {
          await m.createAll();
        },
        // Add your migrations here
      );
}

LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final dbFolder = await getApplicationDocumentsDirectory();
    final file = File(p.join(dbFolder.path, 'invoice_lite.sqlite'));
    return NativeDatabase.createInBackground(file);
  });
}
