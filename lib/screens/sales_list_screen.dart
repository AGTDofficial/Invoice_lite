import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:intl/intl.dart';
import '../models/invoice.dart';
import 'sales_invoice_screen.dart';

class SalesListScreen extends StatefulWidget {
  const SalesListScreen({super.key});

  @override
  State<SalesListScreen> createState() => _SalesListScreenState();
}

class _SalesListScreenState extends State<SalesListScreen> {
  late Box<Invoice> invoiceBox;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _initializeHive();
  }

  Future<void> _initializeHive() async {
    try {
      invoiceBox = await Hive.openBox<Invoice>('invoices');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading invoices: $e')),
        );
      }
    }
  }

  List<Invoice> _getSalesInvoices() {
    try {
      return invoiceBox.values
          .where((invoice) => invoice.invoiceNumber.startsWith('SINV'))
          .toList()
            ..sort((a, b) => b.date.compareTo(a.date)); // Newest first
    } catch (e) {
      return [];
    }
  }

  double _calculateTotal(Invoice invoice) {
    return invoice.items.fold(0, (sum, item) {
      return sum + (item.price * item.quantity) - item.discount;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Sales Invoices'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const SalesInvoiceScreen(),
                ),
              );
            },
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ValueListenableBuilder(
              valueListenable: invoiceBox.listenable(),
              builder: (context, Box<Invoice> box, _) {
                final invoices = _getSalesInvoices();
                if (invoices.isEmpty) {
                  return const Center(child: Text('No sales invoices found'));
                }
                return SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: DataTable(
                    columns: const [
                      DataColumn(label: Text('S.No')),
                      DataColumn(label: Text('Date')),
                      DataColumn(label: Text('Invoice No.')),
                      DataColumn(label: Text('Customer')),
                      DataColumn(
                        label: Text('Amount'),
                        numeric: true,
                      ),
                      DataColumn(label: Text('Actions')),
                    ],
                    rows: List<DataRow>.generate(
                      invoices.length,
                      (index) {
                        final invoice = invoices[index];
                        return DataRow(
                          cells: [
                            DataCell(Text('${index + 1}')),
                            DataCell(Text(
                                DateFormat('dd/MM/yyyy').format(invoice.date))),
                            DataCell(Text(invoice.invoiceNumber)),
                            DataCell(Text(invoice.partyName)),
                            DataCell(Text(
                              '₹${_calculateTotal(invoice).toStringAsFixed(2)}',
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            )),
                            DataCell(
                              IconButton(
                                icon: const Icon(Icons.visibility),
                                onPressed: () {
                                  // TODO: Implement view details
                                },
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                  ),
                );
              },
            ),
    );
  }
}
