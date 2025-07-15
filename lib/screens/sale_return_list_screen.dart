import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:intl/intl.dart';
import '../enums/invoice_type.dart';
import '../models/invoice.dart';
import 'sale_return_screen.dart';

class SaleReturnListScreen extends StatefulWidget {
  const SaleReturnListScreen({super.key});

  @override
  State<SaleReturnListScreen> createState() => _SaleReturnListScreenState();
}

class _SaleReturnListScreenState extends State<SaleReturnListScreen> {
  late Box<Invoice> invoiceBox;
  bool _isLoading = true;
  final _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _initializeHive();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
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
          SnackBar(content: Text('Error loading sale returns: $e')),
        );
      }
    }
  }

  List<Invoice> _getSaleReturns() {
    try {
      final returns = (invoiceBox.values
          .where((invoice) =>
              invoice.isReturn == true &&
              (invoice.originalInvoiceNumber?.startsWith('SINV') == true ||
                  invoice.invoiceNumber.startsWith('SRET')))
          .toList()
            ..sort((a, b) => b.date.compareTo(a.date)));

      if (_searchQuery.isEmpty) return returns;

      return returns
          .where((inv) =>
              inv.invoiceNumber.toLowerCase().contains(_searchQuery.toLowerCase()) ||
              inv.partyName.toLowerCase().contains(_searchQuery.toLowerCase()) ||
              inv.originalInvoiceNumber?.toLowerCase().contains(_searchQuery.toLowerCase()) ==
                  true)
          .toList();
    } catch (e) {
      return [];
    }
  }

  double _calculateTotal(Invoice invoice) {
    return invoice.items.fold(
        0, (sum, item) => sum + (item.price * item.quantity));
  }

  Future<void> _navigateToReturn(Invoice returnInvoice) async {
    // Find the original sale invoice if it exists
    Invoice? originalInvoice;
    if (returnInvoice.originalInvoiceNumber != null) {
      originalInvoice = invoiceBox.values.firstWhere(
        (inv) => inv.invoiceNumber == returnInvoice.originalInvoiceNumber,
        orElse: () => Invoice(
          id: 'not-found',
          type: InvoiceType.sale,
          partyName: 'Unknown',
          date: DateTime.now(),
          invoiceNumber: 'Original not found',
          taxType: 'GST',
          items: [],
          total: 0,
        ),
      );
    }

    // Navigate to view the return
    final shouldRefresh = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (context) => SaleReturnScreen(
          originalInvoice: originalInvoice,
        ),
      ),
    );

    if (shouldRefresh == true && mounted) {
      setState(() {
        // Refresh the list
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Sale Returns'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(60),
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search by invoice #, customer...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                filled: true,
                fillColor: Theme.of(context).brightness == Brightness.light
                    ? Colors.grey[100]
                    : Colors.grey[800],
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
              ),
              onChanged: (value) {
                setState(() {
                  _searchQuery = value;
                });
              },
            ),
          ),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ValueListenableBuilder(
              valueListenable: invoiceBox.listenable(),
              builder: (context, Box<Invoice> box, _) {
                final returns = _getSaleReturns();
                if (returns.isEmpty) {
                  return const Center(
                    child: Text('No sale returns found'),
                  );
                }
                return ListView.builder(
                  itemCount: returns.length,
                  itemBuilder: (context, index) {
                    final returnInvoice = returns[index];
                    final total = _calculateTotal(returnInvoice);
                    return Card(
                      margin: const EdgeInsets.symmetric(
                        horizontal: 8.0,
                        vertical: 4.0,
                      ),
                      child: ListTile(
                        title: Text(
                          returnInvoice.invoiceNumber,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Customer: ${returnInvoice.partyName}',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            if (returnInvoice.originalInvoiceNumber != null)
                              Text(
                                'Original: ${returnInvoice.originalInvoiceNumber}',
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                            Text(
                              '${returnInvoice.items.length} items • ${DateFormat('dd MMM yyyy').format(returnInvoice.date)}',
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          ],
                        ),
                        trailing: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              '₹${total.toStringAsFixed(2)}',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.red[100],
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Text(
                                'RETURN',
                                style: TextStyle(
                                  color: Colors.red,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                        onTap: () => _navigateToReturn(returnInvoice),
                      ),
                    );
                  },
                );
              },
            ),
    );
  }
}
