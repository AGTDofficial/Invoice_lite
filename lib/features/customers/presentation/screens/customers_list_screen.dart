import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shimmer/shimmer.dart';

import '../../../../core/database/database.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/searchable_dropdown.dart';
import '../../../../core/routes/app_router.dart';
import '../../../invoices/presentation/screens/add_edit_invoice_screen.dart';
import '../../providers/customer_providers.dart';
import '../../data/customer_model.dart';
import '../screens/add_edit_customer_screen.dart';

class CustomersListScreen extends ConsumerStatefulWidget {
  static const String routeName = '/customers';
  
  const CustomersListScreen({super.key});

  @override
  ConsumerState<CustomersListScreen> createState() => _CustomersListScreenState();
}

class _CustomersListScreenState extends ConsumerState<CustomersListScreen> {
  final TextEditingController _searchController = TextEditingController();
  bool _isSearching = false;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<Customer> _filterCustomers(List<Customer> customers, String query) {
    if (query.isEmpty) return customers;
    
    final lowercaseQuery = query.toLowerCase();
    return customers.where((customer) {
      final name = customer.name.toLowerCase();
      final phone = customer.phone?.toLowerCase() ?? '';
      final email = customer.email?.toLowerCase() ?? '';
      
      return name.contains(lowercaseQuery) ||
          phone.contains(lowercaseQuery) ||
          email.contains(lowercaseQuery);
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
          hintText: 'Search customers...',
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
  Widget build(BuildContext context) {
    final customersAsync = ref.watch(customersListProvider);
    final theme = Theme.of(context);
    final filteredCustomers = _filterCustomers(
      customersAsync.value ?? [],
      _searchController.text,
    );
    
    return Scaffold(
      backgroundColor: theme.colorScheme.background,
      appBar: AppBar(
        title: _isSearching 
            ? null 
            : const Text('Customers', style: TextStyle(fontWeight: FontWeight.w600)),
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
          ref.invalidate(customersListProvider);
        },
        child: customersAsync.when(
          data: (customers) {
            if (customers.isEmpty) {
              return _buildEmptyState(theme);
            }
            
            final filteredCustomers = _filterCustomers(customers, _searchController.text);
            
            if (filteredCustomers.isEmpty) {
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
                          '${filteredCustomers.length} ${filteredCustomers.length == 1 ? 'customer' : 'customers'} found',
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
                  child: _buildCustomerListView(filteredCustomers),
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
                  'Failed to load customers',
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
                  onPressed: () => ref.invalidate(customerProvider),
                  icon: const Icon(Icons.refresh, size: 18),
                  label: const Text('Retry'),
                ),
              ],
            ),
          ),
        ),
      ),
      floatingActionButton: _buildFloatingActionButton(),
    );
  }

  Widget _buildCustomerListView(List<Customer> customers) {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: customers.length,
      itemBuilder: (context, index) {
        final customer = customers[index];
        return _buildCustomerCard(customer);
      },
    );
  }

  Widget _buildFloatingActionButton() {
    return FloatingActionButton(
      onPressed: () {
        Navigator.pushNamed(
          context,
          AddEditCustomerScreen.routeName,
          arguments: null, // No customerId when adding a new customer
        );
      },
      child: const Icon(Icons.add),
    );
  }

  Widget _buildCustomerCard(Customer customer) {
    final theme = Theme.of(context);
    final name = customer.name.isNotEmpty ? customer.name : 'Unnamed Customer';
    
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: ListTile(
        onTap: () {
          Navigator.pushNamed(
            context,
            AddEditCustomerScreen.routeName,
            arguments: customer.id.toString(),
          );
        },
        leading: CircleAvatar(
          backgroundColor: theme.primaryColor.withOpacity(0.1),
          child: Text(
            name[0].toUpperCase(),
            style: theme.textTheme.titleMedium?.copyWith(
              color: theme.primaryColor,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        title: Text(
          name,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (customer.phone?.isNotEmpty ?? false) 
              Text(customer.phone!),
            if (customer.email?.isNotEmpty ?? false) 
              Text(customer.email!),
          ],
        ),
        trailing: const Icon(Icons.chevron_right),
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
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: 120,
                            height: 16,
                            color: Colors.white,
                          ),
                          const SizedBox(height: 6),
                          Container(
                            width: 100,
                            height: 12,
                            color: Colors.white,
                          ),
                        ],
                      ),
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
                const SizedBox(height: 12),
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
    final hintColor = theme.hintColor.withOpacity(0.5);
    final titleStyle = theme.textTheme.titleMedium?.copyWith(
      fontWeight: FontWeight.w600,
    ) ?? const TextStyle(fontWeight: FontWeight.w600);
    final bodyStyle = theme.textTheme.bodyMedium?.copyWith(
      color: hintColor,
    ) ?? TextStyle(color: hintColor);
    
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.people_alt_outlined,
              size: 72,
              color: hintColor,
            ),
            const SizedBox(height: 16),
            Text(
              'No Customers Yet',
              style: titleStyle,
            ),
            const SizedBox(height: 8),
            Text(
              'Add your first customer by tapping the + button below',
              textAlign: TextAlign.center,
              style: bodyStyle,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNoResultsFound(ThemeData theme) {
    final hintColor = theme.hintColor?.withOpacity(0.5) ?? Colors.grey.withOpacity(0.5);
    final titleStyle = theme.textTheme.titleMedium?.copyWith(
      fontWeight: FontWeight.w600,
    ) ?? const TextStyle(fontWeight: FontWeight.w600);
    final bodyStyle = theme.textTheme.bodyMedium?.copyWith(
      color: hintColor,
    ) ?? TextStyle(color: hintColor);
    
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.search_off_rounded,
              size: 72,
              color: hintColor,
            ),
            const SizedBox(height: 16),
            Text(
              'No Results Found',
              style: titleStyle,
            ),
            const SizedBox(height: 8),
            Text(
              'Try a different search term',
              style: bodyStyle,
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
}
