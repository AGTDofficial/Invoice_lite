import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shimmer/shimmer.dart';
import 'package:intl/intl.dart';
import 'package:invoice_lite/core/routes/app_router.dart';

import 'package:invoice_lite/features/invoices/data/invoice_model.dart';
import 'package:invoice_lite/features/invoices/data/invoice_dao.dart';
import 'package:invoice_lite/features/invoices/presentation/screens/add_edit_invoice_screen.dart';
import 'package:invoice_lite/core/theme/app_colors.dart';

import '../../../../core/database/database.dart';

class InvoicesListScreen extends ConsumerStatefulWidget {
  static const String routeName = '/invoices';
  
  const InvoicesListScreen({super.key});

  @override
  ConsumerState<InvoicesListScreen> createState() => _InvoicesListScreenState();
}

class _InvoicesListScreenState extends ConsumerState<InvoicesListScreen> {
  final TextEditingController _searchController = TextEditingController();
  bool _isSearching = false;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<Invoice> _filterInvoices(List<Invoice> invoices, String query) {
    if (query.isEmpty) return invoices;
    
    final lowercaseQuery = query.toLowerCase();
    return invoices.where((invoice) {
      return invoice.customerName.toLowerCase().contains(lowercaseQuery) ||
          'INV-${invoice.invoiceNumber.padLeft(6, '0')}'.toLowerCase().contains(lowercaseQuery) ||
          invoice.total.toString().contains(query);
    }).toList();
  }

  Widget _buildSearchBar(ThemeData theme) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: TextField(
        controller: _searchController,
        onChanged: (_) => setState(() {}),
        decoration: InputDecoration(
          hintText: 'Search invoices...',
          hintStyle: TextStyle(color: theme.hintColor),
          prefixIcon: Icon(Icons.search, color: theme.hintColor),
          suffixIcon: _searchController.text.isNotEmpty
              ? IconButton(
                  icon: Icon(Icons.close, color: theme.hintColor),
                  onPressed: () {
                    _searchController.clear();
                    setState(() {});
                    FocusScope.of(context).unfocus();
                  },
                )
              : null,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 16),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final invoicesAsync = ref.watch(invoicesProvider);
    final theme = Theme.of(context);
    
    return Scaffold(
      backgroundColor: theme.colorScheme.background,
      appBar: AppBar(
        title: _isSearching 
            ? null 
            : const Text('Invoices', style: TextStyle(fontWeight: FontWeight.w600)),
        elevation: 0,
        centerTitle: false,
        actions: [
          if (_isSearching) ...[
            Expanded(
              child: _buildSearchBar(theme),
            ),
            IconButton(
              icon: const Text('Cancel'),
              onPressed: () {
                setState(() {
                  _isSearching = false;
                  _searchController.clear();
                  FocusScope.of(context).unfocus();
                });
              },
            ),
          ] else ...[
            IconButton(
              icon: const Icon(Icons.search, size: 24),
              onPressed: () {
                setState(() {
                  _isSearching = true;
                });
              },
            ),
            const SizedBox(width: 8),
          ],
        ],
      ),
      body: RefreshIndicator(
        color: theme.primaryColor,
        onRefresh: () async {
          ref.invalidate(invoicesProvider);
        },
        child: invoicesAsync.when(
          data: (invoices) {
            if (invoices.isEmpty) {
              return _buildEmptyState(theme);
            }
            
            final filteredInvoices = _filterInvoices(invoices, _searchController.text);
            
            if (filteredInvoices.isEmpty) {
              return _buildNoResultsFound(theme);
            }
            
            return Column(
              children: [
                if (_isSearching || _searchController.text.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: Row(
                      children: [
                        Text(
                          '${filteredInvoices.length} ${filteredInvoices.length == 1 ? 'invoice' : 'invoices'} found',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.hintColor,
                          ),
                        ),
                        const Spacer(),
                        if (_searchController.text.isNotEmpty)
                          TextButton(
                            onPressed: () {
                              setState(() {
                                _searchController.clear();
                              });
                            },
                            child: const Text('Clear'),
                          ),
                      ],
                    ),
                  ),
                Expanded(
                  child: ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                    itemCount: filteredInvoices.length,
                    separatorBuilder: (context, index) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final invoice = filteredInvoices[index];
                      return _buildInvoiceCard(context, invoice, theme);
                    },
                  ),
                ),
              ],
            );
          },
          loading: () => _buildShimmerLoading(theme),
          error: (error, stack) => Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.error_outline, size: 48, color: Colors.red),
                const SizedBox(height: 16),
                Text(
                  'Failed to load invoices',
                  style: theme.textTheme.titleMedium?.copyWith(color: Colors.red),
                ),
                const SizedBox(height: 8),
                Text(
                  error.toString(),
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodySmall,
                ),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  onPressed: () => ref.invalidate(invoicesProvider),
                  icon: const Icon(Icons.refresh, size: 18),
                  label: const Text('Retry'),
                ),
              ],
            ),
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.pushNamed(context, AddEditInvoiceScreen.routeName);
        },
        icon: const Icon(Icons.add),
        label: const Text('New Invoice'),
        elevation: 2,
      ),
    );
  }
  
  Widget _buildInvoiceCard(BuildContext context, Invoice invoice, ThemeData theme) {
    final dateFormat = DateFormat('MMM dd, yyyy');
    final currencyFormat = NumberFormat.currency(symbol: '\$');
    final statusColor = _getStatusColor(invoice.status);
    
    return Material(
      color: theme.cardColor,
      borderRadius: BorderRadius.circular(12),
      elevation: 0,
      child: InkWell(
        onTap: () {
          AppRouter.navigateToInvoiceDetail(context, invoice.id);
        },
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            border: Border.all(color: theme.dividerColor.withOpacity(0.1)),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'INV-${invoice.invoiceNumber.padLeft(6, '0')}',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: statusColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      invoice.status.toUpperCase(),
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: statusColor,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                '\$${invoice.total.toStringAsFixed(2)}',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.primary,
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Icon(
                    Icons.person_outline,
                    size: 16,
                    color: theme.hintColor,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      invoice.customerName,
                      style: theme.textTheme.bodyMedium,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  Icon(
                    Icons.calendar_today_outlined,
                    size: 14,
                    color: theme.hintColor,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Due ${dateFormat.format(invoice.dueDate)}',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.hintColor,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  Widget _buildShimmerLoading(ThemeData theme) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: 5,
      itemBuilder: (context, index) {
        return Shimmer.fromColors(
          baseColor: theme.brightness == Brightness.light
              ? Colors.grey[300]!
              : Colors.grey[800]!,
          highlightColor: theme.brightness == Brightness.light
              ? Colors.grey[100]!
              : Colors.grey[700]!,
          child: Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: theme.cardColor,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: theme.dividerColor.withOpacity(0.1)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      width: 100,
                      height: 20,
                      color: Colors.white,
                    ),
                    Container(
                      width: 60,
                      height: 20,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Container(
                  width: 120,
                  height: 24,
                  color: Colors.white,
                ),
                const SizedBox(height: 16),
                Container(
                  width: double.infinity,
                  height: 14,
                  color: Colors.white,
                ),
                const SizedBox(height: 8),
                Container(
                  width: 200,
                  height: 14,
                  color: Colors.white,
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildEmptyState(ThemeData theme) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.receipt_long_outlined,
              size: 72,
              color: theme.hintColor.withOpacity(0.5),
            ),
            const SizedBox(height: 16),
            Text(
              'No Invoices Yet',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Create your first invoice by tapping the + button below',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.hintColor,
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildNoResultsFound(ThemeData theme) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.search_off_rounded,
              size: 72,
              color: theme.hintColor.withOpacity(0.5),
            ),
            const SizedBox(height: 16),
            Text(
              'No Results Found',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'No invoices match your search criteria',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.hintColor,
              ),
            ),
            const SizedBox(height: 16),
            if (_searchController.text.isNotEmpty)
              ElevatedButton.icon(
                onPressed: () {
                  setState(() {
                    _searchController.clear();
                  });
                },
                icon: const Icon(Icons.clear_all, size: 18),
                label: const Text('Clear Search'),
              ),
          ],
        ),
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'paid':
        return const Color(0xFF10B981); // Green
      case 'pending':
        return const Color(0xFFF59E0B); // Amber
      case 'overdue':
        return const Color(0xFFEF4444); // Red
      case 'draft':
        return const Color(0xFF6B7280); // Gray
      default:
        return const Color(0xFF6B7280); // Gray
    }
  }
}

// Provider to fetch all invoices
final invoicesProvider = FutureProvider<List<Invoice>>((ref) async {
  final invoiceDao = ref.read(invoiceDaoProvider);
  return await invoiceDao.getAllInvoices();
});
