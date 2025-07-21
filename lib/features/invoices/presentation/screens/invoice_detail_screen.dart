import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:invoice_lite/core/theme/app_colors.dart';
import 'package:invoice_lite/features/customers/data/customer_model.dart';
import 'package:invoice_lite/features/invoices/data/invoice_dao.dart';
import 'package:invoice_lite/features/invoices/data/invoice_model.dart';
import 'package:invoice_lite/features/invoices/presentation/widgets/invoice_actions.dart';

import '../../../../core/database/database.dart';
import '../../../../core/providers/database_provider.dart';

class InvoiceDetailScreen extends ConsumerStatefulWidget {
  static const String routeName = '/invoices/detail';
  final int invoiceId;

  const InvoiceDetailScreen({
    super.key,
    required this.invoiceId,
  });

  @override
  ConsumerState<InvoiceDetailScreen> createState() => _InvoiceDetailScreenState();
}

class _InvoiceDetailScreenState extends ConsumerState<InvoiceDetailScreen> {
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final invoiceAsync = ref.watch(invoiceProvider(widget.invoiceId));
    final itemsAsync = ref.watch(invoiceItemsProvider(widget.invoiceId));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Invoice Details'),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () {
              // TODO: Implement edit functionality
              // Navigator.pushNamed(
              //   context,
              //   AddEditInvoiceScreen.routeName,
              //   arguments: widget.invoiceId,
              // );
            },
          ),
        ],
      ),
      body: invoiceAsync.when(
        data: (invoice) {
          return itemsAsync.when(
            data: (items) {
              // Get customer data
              final customerAsync = ref.watch(customerProvider(invoice.customerId ?? 0));
              
              return customerAsync.when(
                data: (customer) {
                  return Stack(
                    children: [
                      SingleChildScrollView(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Invoice header
                            _buildInvoiceHeader(context, invoice, customer, theme),
                            const SizedBox(height: 24),
                            
                            // Invoice items
                            _buildInvoiceItemsTable(items, theme),
                            const SizedBox(height: 24),
                            
                            // Totals
                            _buildInvoiceTotals(invoice, theme),
                            const SizedBox(height: 24),
                            
                            // Notes
                            if (invoice.notes?.isNotEmpty ?? false) ...[
                              _buildSectionTitle('Notes', theme),
                              const SizedBox(height: 8),
                              Text(
                                invoice.notes!,
                                style: theme.textTheme.bodyMedium,
                              ),
                              const SizedBox(height: 24),
                            ],
                            
                            // Terms
                            if (invoice.terms?.isNotEmpty ?? false) ...[
                              _buildSectionTitle('Terms & Conditions', theme),
                              const SizedBox(height: 8),
                              Text(
                                invoice.terms!,
                                style: theme.textTheme.bodyMedium,
                              ),
                              const SizedBox(height: 24),
                            ],
                          ],
                        ),
                      ),
                      
                      // Actions (PDF, Share, Print)
                      Positioned(
                        left: 0,
                        right: 0,
                        bottom: 0,
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: theme.scaffoldBackgroundColor,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.1),
                                blurRadius: 8,
                                offset: const Offset(0, -4),
                              ),
                            ],
                          ),
                          child: InvoiceActions(
                            invoice: invoice,
                            customer: customer,
                            items: items,
                            isLoading: _isLoading,
                            onPrintComplete: () {
                              setState(() {
                                _isLoading = false;
                              });
                            },
                          ),
                        ),
                      ),
                    ],
                  );
                },
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (error, stack) => Center(
                  child: Text('Error loading customer: $error'),
                ),
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (error, stack) => Center(
              child: Text('Error loading items: $error'),
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(
          child: Text('Error loading invoice: $error'),
        ),
      ),
    );
  }

  Widget _buildInvoiceHeader(
    BuildContext context,
    Invoice invoice,
    Customer customer,
    ThemeData theme,
  ) {
    final dateFormat = DateFormat('MMM dd, yyyy');
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'INVOICE',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  invoice.invoiceNumber,
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: theme.hintColor,
                  ),
                ),
              ],
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: _getStatusColor(invoice.status).withOpacity(0.1),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Text(
                invoice.status.toUpperCase(),
                style: theme.textTheme.labelSmall?.copyWith(
                  color: _getStatusColor(invoice.status),
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),
        
        // Dates
        Row(
          children: [
            Expanded(
              child: _buildInfoCard(
                context,
                title: 'Invoice Date',
                value: dateFormat.format(invoice.invoiceDate),
                icon: Icons.calendar_today,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildInfoCard(
                context,
                title: 'Due Date',
                value: invoice.dueDate != null 
                    ? dateFormat.format(invoice.dueDate!)
                    : 'N/A',
                icon: Icons.calendar_month,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        
        // Customer info
        _buildSectionTitle('Bill To', theme),
        const SizedBox(height: 8),
        _buildInfoRow('Name', customer.name, theme),
        if (customer.companyName?.isNotEmpty ?? false)
          _buildInfoRow('Company', customer.companyName!, theme),
        if (customer.email?.isNotEmpty ?? false)
          _buildInfoRow('Email', customer.email!, theme),
        if (customer.phone?.isNotEmpty ?? false)
          _buildInfoRow('Phone', customer.phone!, theme),
        if (customer.gstin?.isNotEmpty ?? false)
          _buildInfoRow('GSTIN', customer.gstin!, theme),
      ],
    );
  }

  Widget _buildInfoCard(
    BuildContext context, {
    required String title,
    required String value,
    required IconData icon,
  }) {
    final theme = Theme.of(context);
    
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.dividerColor.withOpacity(0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: theme.hintColor),
              const SizedBox(width: 8),
              Text(
                title,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.hintColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title, ThemeData theme) {
    return Text(
      title,
      style: theme.textTheme.titleMedium?.copyWith(
        fontWeight: FontWeight.bold,
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              '$label:',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.hintColor,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              value,
              style: theme.textTheme.bodyMedium,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInvoiceItemsTable(List<InvoiceItem> items, ThemeData theme) {
    final currencyFormat = NumberFormat.currency(symbol: '₹');
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('Items', theme),
        const SizedBox(height: 12),
        Container(
          decoration: BoxDecoration(
            color: theme.cardColor,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: theme.dividerColor.withOpacity(0.1)),
          ),
          child: Column(
            children: [
              // Table header
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceVariant.withOpacity(0.5),
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                ),
                child: const Row(
                  children: [
                    Expanded(
                      flex: 3,
                      child: Text('Description', style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                    Expanded(
                      child: Text('Qty', style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                    Expanded(
                      child: Text('Rate', style: TextStyle(fontWeight: FontWeight.bold), textAlign: TextAlign.right),
                    ),
                    Expanded(
                      child: Text('Amount', style: TextStyle(fontWeight: FontWeight.bold), textAlign: TextAlign.right),
                    ),
                  ],
                ),
              ),
              
              // Table rows
              ...List.generate(
                items.length,
                (index) {
                  final item = items[index];
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          flex: 3,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                item.description.isNotEmpty 
                                    ? item.description 
                                    : 'Item ${index + 1}',
                                style: theme.textTheme.bodyMedium,
                              ),
                              if (item.taxAmount > 0) ...[
                                const SizedBox(height: 4),
                                Text(
                                  'Tax: ${currencyFormat.format(item.taxAmount)} (${item.taxPercent}%)',
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: theme.hintColor,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                        Expanded(
                          child: Text(
                            item.quantity.toStringAsFixed(2),
                            style: theme.textTheme.bodyMedium,
                          ),
                        ),
                        Expanded(
                          child: Text(
                            currencyFormat.format(item.unitPrice),
                            style: theme.textTheme.bodyMedium,
                            textAlign: TextAlign.right,
                          ),
                        ),
                        Expanded(
                          child: Text(
                            currencyFormat.format(item.total),
                            style: theme.textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.w500,
                            ),
                            textAlign: TextAlign.right,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildInvoiceTotals(Invoice invoice, ThemeData theme) {
    final currencyFormat = NumberFormat.currency(symbol: '₹');
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.dividerColor.withOpacity(0.1)),
      ),
      child: Column(
        children: [
          _buildTotalRow(
            'Subtotal',
            currencyFormat.format(invoice.subtotal),
            theme,
          ),
          if (invoice.discountAmount > 0)
            _buildTotalRow(
              'Discount',
              '-${currencyFormat.format(invoice.discountAmount)}',
              theme,
              isDiscount: true,
            ),
          if (invoice.taxAmount > 0)
            _buildTotalRow(
              'Tax',
              currencyFormat.format(invoice.taxAmount),
              theme,
            ),
          const Divider(height: 24),
          _buildTotalRow(
            'Total',
            currencyFormat.format(invoice.total),
            theme,
            isTotal: true,
          ),
        ],
      ),
    );
  }

  Widget _buildTotalRow(
    String label,
    String value,
    ThemeData theme, {
    bool isTotal = false,
    bool isDiscount = false,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: isTotal
                ? theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  )
                : theme.textTheme.bodyMedium?.copyWith(
                    color: isDiscount
                        ? theme.colorScheme.error
                        : theme.hintColor,
                  ),
          ),
          Text(
            value,
            style: isTotal
                ? theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.primary,
                  )
                : theme.textTheme.bodyMedium?.copyWith(
                    color: isDiscount
                        ? theme.colorScheme.error
                        : theme.hintColor,
                    fontWeight: isTotal ? FontWeight.bold : null,
                  ),
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'paid':
        return Colors.green;
      case 'overdue':
        return Colors.red;
      case 'partially_paid':
        return Colors.orange;
      case 'refunded':
        return Colors.purple;
      case 'draft':
      default:
        return Colors.grey;
    }
  }
}

// Providers
final invoiceProvider = FutureProvider.family<Invoice, int>((ref, invoiceId) async {
  final invoiceDao = ref.read(invoiceDaoProvider);
  final invoice = await invoiceDao.getInvoice(invoiceId);
  if (invoice == null) {
    throw Exception('Invoice not found');
  }
  return invoice;
});

final invoiceItemsProvider = FutureProvider.family<List<InvoiceItem>, int>((ref, invoiceId) async {
  final invoiceDao = ref.read(invoiceDaoProvider);
  return await invoiceDao.getInvoiceItems(invoiceId);
});

final customerProvider = FutureProvider.family<Customer, int>((ref, customerId) async {
  final customerDao = ref.read(customerDaoProvider);
  final customer = await customerDao.getCustomer(customerId);
  if (customer == null) {
    throw Exception('Customer not found');
  }
  return customer;
});
