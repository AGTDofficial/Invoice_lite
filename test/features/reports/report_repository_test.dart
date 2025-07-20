import 'package:flutter_test/flutter_test.dart';
import 'package:drift/drift.dart';
import 'package:invoice_lite/core/database/database.dart';
import 'package:invoice_lite/features/customers/data/customer_dao.dart';
import 'package:invoice_lite/features/customers/data/customer_model.dart';
import 'package:invoice_lite/features/invoices/data/invoice_dao.dart';
import 'package:invoice_lite/features/invoices/data/invoice_model.dart';
import 'package:invoice_lite/features/items/data/item_dao.dart';
import 'package:invoice_lite/features/items/data/item_model.dart';
import 'package:invoice_lite/features/reports/data/report_repository.dart';
import 'package:drift/native.dart';

void main() {
  late AppDatabase database;
  late ReportRepository repository;
  late InvoiceDao invoiceDao;
  late ItemDao itemDao;
  late CustomerDao customerDao;

  setUp(() async {
    // Create an in-memory database for testing
    database = AppDatabase(NativeDatabase.memory());
    invoiceDao = InvoiceDao(database);
    itemDao = ItemDao(database);
    customerDao = CustomerDao(database);
    repository = ReportRepository(
      db: database,
      invoiceDao: invoiceDao,
      itemDao: itemDao,
      customerDao: customerDao,
    );

    // Add test data
    await _populateTestData();
  });

  tearDown(() async {
    await database.close();
  });

  Future<void> _populateTestData() async {
    // Add customers
    final customer1 = await customerDao.addCustomer(
      CustomersCompanion.insert(
        name: 'Test Customer 1',
        email: Value('customer1@test.com'),
        phone: Value('1234567890'),
        address: Value('Test Address 1'),
        city: Value('Test City'),
        state: Value('Test State'),
        country: Value('India'),
        pinCode: Value('123456'),
        taxId: Value('GST123'),
        type: Value('retail'),
        balance: const Value(0.0),
        createdAt: Value(DateTime.now()),
        updatedAt: Value(DateTime.now()),
      ),
    );

    final customer2 = await customerDao.addCustomer(
      CustomersCompanion.insert(
        name: 'Test Customer 2',
        email: Value('customer2@test.com'),
        phone: Value('0987654321'),
        address: Value('Test Address 2'),
        city: Value('Test City'),
        state: Value('Test State'),
        country: Value('India'),
        pinCode: Value('654321'),
        taxId: Value('GST456'),
        type: Value('retail'),
        balance: const Value(0.0),
        createdAt: Value(DateTime.now()),
        updatedAt: Value(DateTime.now()),
      ),
    );

    // Add items
    final item1 = await itemDao.addItem(
      ItemsCompanion.insert(
        name: 'Test Item 1',
        description: const Value('Test Item 1 Description'),
        itemCode: const Value('ITEM001'),
        saleRate: const Value(100.0),
        purchaseRate: const Value(50.0),
        currentStock: const Value(10.0),
        minStockLevel: const Value(2.0),
        unit: const Value('PCS'),
        hsnCode: const Value(''),
        taxRate: const Value(18.0),
        isActive: const Value(true),
        createdAt: Value(DateTime.now()),
        updatedAt: Value(DateTime.now()),
      ),
    );

    final item2 = await itemDao.addItem(
      ItemsCompanion.insert(
        name: 'Test Item 2',
        description: const Value('Test Item 2 Description'),
        itemCode: const Value('ITEM002'),
        saleRate: const Value(200.0),
        purchaseRate: const Value(100.0),
        currentStock: const Value(5.0),
        minStockLevel: const Value(2.0),
        unit: const Value('PCS'),
        hsnCode: const Value(''),
        taxRate: const Value(18.0),
        isActive: const Value(true),
        createdAt: Value(DateTime.now()),
        updatedAt: Value(DateTime.now()),
      ),
    );

    // Add invoices
    final now = DateTime.now();
    final lastMonth = now.subtract(const Duration(days: 30));
    
    // Paid invoice from last month
    final invoice1 = await invoiceDao.createInvoiceWithItems(
      invoice: InvoicesCompanion.insert(
        invoiceNumber: const Value('INV23-24/0001'),
        customerId: Value(customer1),
        invoiceDate: Value(lastMonth),
        dueDate: Value(lastMonth.add(const Duration(days: 15))),
        status: const Value('paid'),
        subtotal: const Value(300.0),
        taxAmount: const Value(54.0),
        discountAmount: const Value(0.0),
        total: const Value(354.0),
        notes: const Value(''),
        terms: const Value(''),
        referenceNumber: const Value(''),
        paymentStatus: const Value('paid'),
        paymentDate: Value(lastMonth),
        paymentMethod: const Value('cash'),
        paymentReference: const Value(''),
        shippingAddress: const Value(''),
        shippingCharges: const Value(0.0),
        adjustment: const Value(0.0),
        createdAt: Value(lastMonth),
        updatedAt: Value(lastMonth),
      ),
      items: [
        InvoiceItemsCompanion.insert(
          itemId: Value(item1),
          description: const Value('Test Item 1'),
          quantity: const Value(2.0),
          unitPrice: const Value(100.0),
          amount: const Value(200.0),
          discountAmount: const Value(0.0),
          taxAmount: const Value(36.0),
          total: const Value(236.0),
          taxRate: const Value(18.0),
          discountRate: const Value(0.0),
          unit: const Value('PCS'),
          hsnCode: const Value(''),
          createdAt: Value(lastMonth),
          updatedAt: Value(lastMonth),
        ),
        InvoiceItemsCompanion.insert(
          itemId: Value(item2),
          description: const Value('Test Item 2'),
          quantity: const Value(1.0),
          unitPrice: const Value(100.0),
          amount: const Value(100.0),
          discountAmount: const Value(0.0),
          taxAmount: const Value(18.0),
          total: const Value(118.0),
          taxRate: const Value(18.0),
          discountRate: const Value(0.0),
          unit: const Value('PCS'),
          hsnCode: const Value(''),
          createdAt: Value(lastMonth),
          updatedAt: Value(lastMonth),
        ),
      ],
    );

    // Unpaid invoice from this month
    await invoiceDao.createInvoiceWithItems(
      invoice: InvoicesCompanion.insert(
        invoiceNumber: const Value('INV23-24/0002'),
        customerId: Value(customer2),
        invoiceDate: Value(now),
        dueDate: Value(now.add(const Duration(days: 15))),
        status: const Value('unpaid'),
        subtotal: const Value(200.0),
        taxAmount: const Value(36.0),
        discountAmount: const Value(0.0),
        total: const Value(236.0),
        notes: const Value(''),
        terms: const Value(''),
        referenceNumber: const Value(''),
        paymentStatus: const Value('pending'),
        paymentDate: Value(now),
        paymentMethod: const Value(''),
        paymentReference: const Value(''),
        shippingAddress: const Value(''),
        shippingCharges: const Value(0.0),
        adjustment: const Value(0.0),
        createdAt: Value(now),
        updatedAt: Value(now),
      ),
      items: [
        InvoiceItemsCompanion.insert(
          itemId: Value(item2),
          description: const Value('Test Item 2'),
          quantity: const Value(1.0),
          unitPrice: const Value(200.0),
          amount: const Value(200.0),
          discountAmount: const Value(0.0),
          taxAmount: const Value(36.0),
          total: const Value(236.0),
          taxRate: const Value(18.0),
          discountRate: const Value(0.0),
          unit: const Value('PCS'),
          hsnCode: const Value(''),
          createdAt: Value(now),
          updatedAt: Value(now),
        ),
      ],
    );
  }

  group('ReportRepository Tests', () {
    test('getSalesSummary returns correct data', () async {
    final now = DateTime.now();
    final lastMonth = now.subtract(const Duration(days: 30));
    
    // Test with date range including both invoices
    var result = await repository.getSalesSummary(
      startDate: lastMonth.subtract(const Duration(days: 1)),
      endDate: now.add(const Duration(days: 1)),
    );

    // The values are now doubles due to the schema changes
    expect(result['totalSales'], closeTo(590.0, 0.01)); // 354 + 236
    expect(result['totalInvoices'], 2);
    expect(result['statuses']['paid']?['count'], 1);
    expect(result['statuses']['unpaid']?['count'], 1);

    // Test with date range including only the first invoice
    result = await repository.getSalesSummary(
      startDate: lastMonth.subtract(const Duration(days: 1)),
      endDate: lastMonth.add(const Duration(days: 1)),
    );

    expect(result['totalSales'], closeTo(354.0, 0.01));
    expect(result['totalInvoices'], 1);
    expect(result['statuses']['paid']?['count'], 1);
    expect(result['statuses']['unpaid'], isNull);
  });

    test('getTopSellingItems returns correct data', () async {
      final now = DateTime.now();
      final lastMonth = now.subtract(const Duration(days: 30));
      
      final result = await repository.getTopSellingItems(
        startDate: lastMonth.subtract(const Duration(days: 1)),
        endDate: now.add(const Duration(days: 1)),
      );

      expect(result.length, 2);
      expect(result[0]['name'], 'Test Item 1');
      expect(result[0]['quantity'], 2.0);
      expect(result[1]['name'], 'Test Item 2');
      expect(result[1]['quantity'], 1.0);
    });

    test('getSalesByCustomer returns correct data', () async {
      final now = DateTime.now();
      final lastMonth = now.subtract(const Duration(days: 30));
      
      final result = await repository.getSalesByCustomer(
        startDate: lastMonth.subtract(const Duration(days: 1)),
        endDate: now.add(const Duration(days: 1)),
      );

      expect(result.length, 2);
      expect(result[0]['name'], 'Test Customer 1');
      expect(result[0]['total'], 354.0);
      expect(result[0]['count'], 1);
      expect(result[1]['name'], 'Test Customer 2');
      expect(result[1]['total'], 236.0);
      expect(result[1]['count'], 1);
    });

    test('getInventoryStatus returns correct data', () async {
      final result = await repository.getInventoryStatus();
      
      expect(result['totalItems'], 2);
      expect(result['totalStock'], 15); // 10 + 5
      expect(result['averageStock'], 7.5); // 15 / 2
      expect(result['lowStockCount'], 0);
    });

    test('getFinancialSummary returns correct data', () async {
      final now = DateTime.now();
      final lastMonth = now.subtract(const Duration(days: 30));
      
      final result = await repository.getFinancialSummary(
        startDate: lastMonth.subtract(const Duration(days: 1)),
        endDate: now.add(const Duration(days: 1)),
      );

      expect(result['grossSales'], 500.0); // 300 + 200
      expect(result['totalTax'], 90.0); // 54 + 36
      expect(result['totalDiscount'], 0.0);
      expect(result['netSales'], 590.0); // 354 + 236
    });
  });
}
