import 'package:hive/hive.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:path_provider/path_provider.dart' as path_provider;
import '../enums/invoice_type.dart';
import '../models/account.dart';
import '../models/account_group.dart';
import '../models/company.dart';
import '../models/invoice.dart';
import '../models/invoice_item.dart';
import '../models/item_group.dart';
import '../models/item_model.dart';
import '../models/party.dart';
import '../models/stock_movement.dart';
import '../enums/stock_movement_type.dart';

class HiveInitializer {
  static Future<void> initializeHive() async {
    try {
      // Initialize Hive with the app's document directory
      final appDocumentDir = await path_provider.getApplicationDocumentsDirectory();
      await Hive.initFlutter(appDocumentDir.path);

      // First register all basic type adapters
      Hive.registerAdapter<InvoiceType>(InvoiceTypeAdapter());
      
      // Register StockMovementType adapter
      if (!Hive.isAdapterRegistered(3)) {  // typeId 3 matches the one in StockMovementType
        Hive.registerAdapter(StockMovementTypeAdapter());
      }
      
      // Register model adapters in dependency order
      // Basic models first
      Hive.registerAdapter<AccountGroup>(AccountGroupAdapter());
      Hive.registerAdapter<Account>(AccountAdapter());
      Hive.registerAdapter<Company>(CompanyAdapter());
      Hive.registerAdapter<Party>(PartyAdapter());
      Hive.registerAdapter<ItemGroup>(ItemGroupAdapter());
      
      // Register StockMovement adapter
      if (!Hive.isAdapterRegistered(StockMovementAdapter().typeId)) {
        Hive.registerAdapter(StockMovementAdapter());
      }
      
      // Register Item which depends on StockMovement
      Hive.registerAdapter<Item>(ItemAdapter());
      
      // Register invoice related adapters
      Hive.registerAdapter<InvoiceItem>(InvoiceItemAdapter());
      Hive.registerAdapter<Invoice>(InvoiceAdapter());
      
      // Verify critical adapters are registered
      if (!Hive.isAdapterRegistered(StockMovementAdapter().typeId) ||
          !Hive.isAdapterRegistered(ItemAdapter().typeId)) {
        throw Exception('Failed to register critical Hive adapters');
      }

      // Open all boxes
      await Future.wait([
        Hive.openBox<Account>('accounts'),
        Hive.openBox<AccountGroup>('account_groups'),
        Hive.openBox<Company>('companies'),
        Hive.openBox<dynamic>('invoices'),
        Hive.openBox<Item>('itemsBox'),
        Hive.openBox<ItemGroup>('itemGroups'),
        Hive.openBox<Party>('parties'),
      ]);

      print('Hive initialized successfully');
    } catch (e) {
      print('Error initializing Hive: $e');
      rethrow;
    }
  }
}
