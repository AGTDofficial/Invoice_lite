import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:provider/provider.dart';
import 'package:path_provider/path_provider.dart' as path_provider;
import 'enums/invoice_type.dart';
import 'models/account.dart';
import 'models/account_group.dart';
import 'models/item_group.dart';
import 'models/company.dart';
import 'models/invoice.dart';
import 'models/invoice_item.dart';
import 'models/item_model.dart';
import 'models/stock_movement.dart';
import 'enums/stock_movement_type.dart';
import 'providers/account_provider.dart';
import 'providers/company_provider.dart';
import 'screens/home_screen.dart';

// Global box references
Box<Account>? accountsBox;
Box<AccountGroup>? groupsBox;

// Global navigator key
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();



Future<Map<String, Box>> _openHiveBoxes() async {
  final boxes = <String, Box>{};
  
  try {
    // Open each box with its specific type
    final accountsBox = await _openBoxSafely<Account>('accounts');
    final accountGroupsBox = await _openBoxSafely<AccountGroup>('accountgroups');
    final companiesBox = await _openBoxSafely<Company>('companies');
    final invoicesBox = await _openBoxSafely<Invoice>('invoices');
    final itemsBox = await _openBoxSafely<Item>('itemsBox');  // Changed from 'items' to 'itemsBox'
    final itemGroupsBox = await _openBoxSafely<ItemGroup>('itemGroups');
    final settingsBox = await Hive.openBox('settings');
    
    // Store boxes in the map
    if (accountsBox != null) {
      boxes['accounts'] = accountsBox;
      debugPrint('✅ Opened Account box: accounts');
    }
    
    if (accountGroupsBox != null) {
      boxes['accountgroups'] = accountGroupsBox;
      debugPrint('✅ Opened AccountGroup box: accountgroups');
    }
    
    if (companiesBox != null) {
      boxes['companies'] = companiesBox;
      debugPrint('✅ Opened Company box: companies');
    }
    
    if (invoicesBox != null) {
      boxes['invoices'] = invoicesBox;
      debugPrint('✅ Opened Invoice box: invoices');
    }
    
    if (itemsBox != null) {
      boxes['itemsBox'] = itemsBox;  // Changed key from 'items' to 'itemsBox'
      debugPrint('✅ Opened Item box: itemsBox');
    }
    
    if (itemGroupsBox != null) {
      boxes['itemGroups'] = itemGroupsBox;
      debugPrint('✅ Opened ItemGroup box: itemGroups');
    }
    
    boxes['settings'] = settingsBox;
    debugPrint('✅ Opened dynamic box: settings');
    
    return boxes;
  } catch (e) {
    debugPrint('❌ Error opening Hive boxes: $e');
    rethrow;
  }
}

Future<Box<T>?> _openBoxSafely<T>(String name) async {
  try {
    if (!Hive.isBoxOpen(name)) {
      return await Hive.openBox<T>(name);
    }
    return Hive.box<T>(name);
  } catch (e) {
    debugPrint('❌ Error opening box $name: $e');
    rethrow;
  }
}

void main() async {
  // Initialize Flutter bindings
  WidgetsFlutterBinding.ensureInitialized();

  // Show loading screen while initializing
  runApp(
    const MaterialApp(
      home: Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('Initializing app...'),
            ],
          ),
        ),
      ),
    ),
  );

  try {
    await _initializeApp();
  } catch (e, stackTrace) {
    _showErrorUI(e, stackTrace);
  }
}

Future<void> _initializeApp() async {
  debugPrint('🚀 Starting app initialization...');
  
  try {
    final appDocumentDir = await path_provider.getApplicationDocumentsDirectory();
    debugPrint('📁 App documents directory: ${appDocumentDir.path}');
    
    // Initialize Hive properly
    await Hive.initFlutter(appDocumentDir.path);
    
    // Register adapters
    await _registerHiveAdapters();
    
    // Open all Hive boxes
    debugPrint('\n📦 Opening Hive boxes...');
    final boxes = await _openHiveBoxes();
    
    // Get boxes with proper type inference
    final accountGroupsBox = boxes['accountgroups'] as Box<AccountGroup>;
    final companiesBox = boxes['companies'] as Box<Company>;
    final settingsBox = boxes['settings'] as Box<dynamic>;
    
    // Initialize global box references
    accountsBox = boxes['accounts'] as Box<Account>;
    groupsBox = accountGroupsBox;
    
    // Initialize providers
    final companyProvider = CompanyProvider();
    final accountProvider = AccountProvider();
    
    await companyProvider.init(companiesBox, settingsBox);
    await accountProvider.init();
    
    // Add default account groups if empty
    if (groupsBox!.isNotEmpty) {
      await _addDefaultAccountGroups();
    }
    
    // Add a default company if none exists
    if (companiesBox.isNotEmpty) {
      await _addDefaultCompany(companiesBox);
      companyProvider.setCurrentCompany(companiesBox.getAt(0)!);
      debugPrint('✅ Set default company as current');
    }
    
    // Run the main app
    runApp(
      MultiProvider(
        providers: [
          ChangeNotifierProvider.value(value: companyProvider),
          ChangeNotifierProvider.value(value: accountProvider),
        ],
        child: MyApp(
          navigatorKey: navigatorKey, 
          itemsBox: boxes['itemsBox'] as Box<Item>,
          itemGroupsBox: boxes['itemGroups'] as Box<ItemGroup>,
        ),
      ),
    );
  } catch (e, stackTrace) {
    debugPrint('❌ Fatal error during app initialization: $e');
    debugPrint('Stack trace: $stackTrace');
    rethrow;
  }
}

Future<void> _registerHiveAdapters() async {
  debugPrint('\n🔧 Registering Hive adapters...');
  
  try {
    // Register adapters with a small delay between each to ensure proper registration
    await Future.delayed(Duration(milliseconds: 100));
    
    // Clear any existing type registry
    try {
      // This is a hack to clear the type registry
      final typeRegistry = Hive; // Access the type registry
      // This will cause the type registry to be recreated on next access
      typeRegistry.close();
      await Future.delayed(Duration(milliseconds: 100));
    } catch (e) {
      debugPrint('⚠️ Warning: Could not clear type registry: $e');
    }
    
    // Register adapters with error handling for each one
    await _registerAdapter<AccountGroup>(
      () => AccountGroupAdapter(), 
      1, 
      'AccountGroupAdapter'
    );
    
    await _registerAdapter<Company>(
      () => CompanyAdapter(), 
      2, 
      'CompanyAdapter'
    );
    
    await _registerAdapter<Invoice>(
      () => InvoiceAdapter(), 
      3, 
      'InvoiceAdapter'
    );
    
    await _registerAdapter<Account>(
      () => AccountAdapter(), 
      4, 
      'AccountAdapter'
    );
    
    await _registerAdapter<InvoiceItem>(
      () => InvoiceItemAdapter(), 
      5, 
      'InvoiceItemAdapter'
    );
    
    await _registerAdapter<Item>(
      () => ItemAdapter(), 
      10, 
      'ItemAdapter'
    );
    
    await _registerAdapter(
      () => StockMovementAdapter(), 
      101, 
      'StockMovementAdapter'
    );

    // Register enum adapter for StockMovementType
    await _registerAdapter(
      () => StockMovementTypeAdapter(), 
      StockMovementTypeAdapter().typeId, 
      'StockMovementTypeAdapter'
    );
    
    await _registerAdapter(
      () => ItemGroupAdapter(), 
      6, 
      'ItemGroupAdapter'
    );
    
    // Register enum adapters with higher typeIds to avoid conflicts
    await _registerAdapter(
      () => InvoiceTypeAdapter(), 
      102, 
      'InvoiceTypeAdapter'
    );
    
    debugPrint('✅ All adapters registered successfully');
  } catch (e, stackTrace) {
    debugPrint('❌ Error registering adapters: $e');
    debugPrint('Stack trace: $stackTrace');
    rethrow;
  }
}

Future<void> _registerAdapter<T>(
  TypeAdapter<T> Function() createAdapter,
  int typeId,
  String adapterName,
) async {
  try {
    if (Hive.isAdapterRegistered(typeId)) {
      debugPrint('ℹ️ $adapterName with typeId: $typeId already registered, skipping...');
      return;
    }
    
    final adapter = createAdapter();
    Hive.registerAdapter<T>(adapter);
    debugPrint('✅ Registered $adapterName with typeId: $typeId');
    
    // Small delay to ensure proper registration
    await Future.delayed(Duration(milliseconds: 50));
  } catch (e) {
    debugPrint('❌ Error registering $adapterName (typeId: $typeId): $e');
    rethrow;
  }
}

Future<void> _addDefaultAccountGroups() async {
  if (groupsBox == null) return;
  
  debugPrint('Adding default account groups');
  final defaultGroups = [
    AccountGroup(name: 'Assets', categoryType: 'Assets', isSystemGroup: true),
    AccountGroup(name: 'Liabilities', categoryType: 'Liabilities', isSystemGroup: true),
    AccountGroup(name: 'Sales', categoryType: 'Income', isInventoryRelated: true, isSystemGroup: true),
    AccountGroup(name: 'Purchase', categoryType: 'Expenses', isInventoryRelated: true, isSystemGroup: true),
    AccountGroup(name: 'Loans', categoryType: 'Liabilities', isSystemGroup: true),
    AccountGroup(name: 'Expenses', categoryType: 'Expenses', isSystemGroup: true),
    AccountGroup(name: 'Income', categoryType: 'Income', isSystemGroup: true),
    AccountGroup(name: 'Sundry Debtors', categoryType: 'Assets', parentGroup: 'Current Assets', isSystemGroup: true),
    AccountGroup(name: 'Sundry Creditors', categoryType: 'Liabilities', parentGroup: 'Current Liabilities', isSystemGroup: true),
    AccountGroup(name: 'Bank Accounts', categoryType: 'Assets', parentGroup: 'Current Assets', isSystemGroup: true),
    AccountGroup(name: 'Cash-in-Hand', categoryType: 'Assets', parentGroup: 'Current Assets', isSystemGroup: true),
    AccountGroup(name: 'Current Assets', categoryType: 'Assets', isSystemGroup: true),
    AccountGroup(name: 'Current Liabilities', categoryType: 'Liabilities', isSystemGroup: true),
  ];
  
  await groupsBox!.addAll(defaultGroups);
  debugPrint('✅ Added ${defaultGroups.length} default account groups');
}

Future<void> _addDefaultCompany(Box<Company> companiesBox) async {
  debugPrint('Adding default company');
  final defaultCompany = Company(
    name: 'My Business',
    address: 'Your Business Address',
    gstin: '22AAAAA0000A1Z5',
    financialYearStart: DateTime(DateTime.now().year, 4, 1),
    mobileNumber: '9876543210',
    businessState: 'Maharashtra',
    dealerType: 'Regular',
    email: 'business@example.com',
    pincode: '400001',
    isRegistered: true,
    businessType: 'Proprietorship',
  );
  await companiesBox.add(defaultCompany);
  debugPrint('✅ Added default company');
}

void _showErrorUI(dynamic error, StackTrace stackTrace) {
  debugPrint('❌ Fatal error during app initialization: $error');
  debugPrint('Stack trace: $stackTrace');
  
  runApp(
    MaterialApp(
      home: Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, color: Colors.red, size: 64),
              const SizedBox(height: 16),
              const Text(
                'Failed to initialize app',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                error.toString(),
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.red),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () => main(),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

class MyApp extends StatelessWidget {
  final GlobalKey<NavigatorState> navigatorKey;
  final Box<Item> itemsBox;
  final Box<ItemGroup> itemGroupsBox;

  const MyApp({
    Key? key, 
    required this.navigatorKey,
    required this.itemsBox,
    required this.itemGroupsBox,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Invoice App',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      navigatorKey: navigatorKey,
      home: HomeScreen(
        itemsBox: itemsBox,
        itemGroupsBox: itemGroupsBox,
      ),
    );
  }
}
