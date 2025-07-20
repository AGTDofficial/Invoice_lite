import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:syncfusion_flutter_charts/charts.dart';

class ReportsScreen extends ConsumerStatefulWidget {
  static const String routeName = '/reports';

  const ReportsScreen({super.key});

  @override
  ConsumerState<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends ConsumerState<ReportsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  DateTimeRange _dateRange = DateTimeRange(
    start: DateTime.now().subtract(const Duration(days: 30)),
    end: DateTime.now(),
  );

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _selectDateRange(BuildContext context) async {
    final DateTimeRange? picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
      initialDateRange: _dateRange,
    );
    
    if (picked != null && picked != _dateRange) {
      setState(() {
        _dateRange = picked;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dateFormat = DateFormat('MMM dd, yyyy');
    final currencyFormat = NumberFormat.currency(symbol: '₹');

    return Scaffold(
      appBar: AppBar(
        title: const Text('Reports'),
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          tabs: const [
            Tab(text: 'Overview'),
            Tab(text: 'Sales'),
            Tab(text: 'Products'),
            Tab(text: 'Customers'),
          ],
        ),
      ),
      body: Column(
        children: [
          // Date range selector
          Container(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                const Icon(Icons.date_range, size: 20),
                const SizedBox(width: 8),
                Text(
                  '${dateFormat.format(_dateRange.start)} - ${dateFormat.format(_dateRange.end)}',
                  style: theme.textTheme.bodyMedium,
                ),
                const Spacer(),
                TextButton(
                  onPressed: () => _selectDateRange(context),
                  child: const Text('Change Date Range'),
                ),
              ],
            ),
          ),
          
          // Tab content
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildOverviewTab(theme, currencyFormat),
                _buildSalesTab(theme, currencyFormat),
                _buildProductsTab(theme, currencyFormat),
                _buildCustomersTab(theme, currencyFormat),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOverviewTab(ThemeData theme, NumberFormat currencyFormat) {
    final financialSummaryAsync = ref.watch(financialSummaryProvider(
      (startDate: _dateRange.start, endDate: _dateRange.end),
    ));

    return RefreshIndicator(
      onRefresh: () async {
        ref.invalidate(financialSummaryProvider);
        ref.invalidate(inventoryStatusProvider);
      },
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Financial Summary', style: theme.textTheme.titleLarge),
            const SizedBox(height: 16),
            financialSummaryAsync.when(
              data: (summary) => _buildSummaryCards(theme, currencyFormat, summary),
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, stack) => Text('Error: $error'),
            ),
            const SizedBox(height: 24),
            
            Text('Inventory Status', style: theme.textTheme.titleLarge),
            const SizedBox(height: 16),
            _buildInventoryStatus(theme),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryCards(ThemeData theme, NumberFormat currencyFormat, Map<String, dynamic> summary) {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      crossAxisSpacing: 16,
      mainAxisSpacing: 16,
      childAspectRatio: 1.5,
      children: [
        _buildSummaryCard(
          theme,
          title: 'Gross Sales',
          value: currencyFormat.format(summary['grossSales'] ?? 0),
          icon: Icons.attach_money,
          color: Colors.blue,
        ),
        _buildSummaryCard(
          theme,
          title: 'Net Sales',
          value: currencyFormat.format(summary['netSales'] ?? 0),
          icon: Icons.account_balance_wallet,
          color: Colors.green,
        ),
        _buildSummaryCard(
          theme,
          title: 'Total Tax',
          value: currencyFormat.format(summary['totalTax'] ?? 0),
          icon: Icons.receipt,
          color: Colors.orange,
        ),
        _buildSummaryCard(
          theme,
          title: 'Total Discount',
          value: currencyFormat.format(summary['totalDiscount'] ?? 0),
          icon: Icons.discount,
          color: Colors.purple,
        ),
      ],
    );
  }

  Widget _buildInventoryStatus(ThemeData theme) {
    final inventoryStatusAsync = ref.watch(inventoryStatusProvider);

    return inventoryStatusAsync.when(
      data: (status) => Container(
        padding: const EdgeInsets.all(16),
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
        child: Column(
          children: [
            _buildInventoryStat(
              'Total Items',
              '${status['totalItems'] ?? 0}',
              Icons.inventory_2,
              theme,
            ),
            const Divider(),
            _buildInventoryStat(
              'Total Stock',
              '${status['totalStock']?.toInt() ?? 0} units',
              Icons.stacked_bar_chart,
              theme,
            ),
            const Divider(),
            _buildInventoryStat(
              'Average Stock',
              '${status['averageStock']?.toStringAsFixed(1) ?? 0} units',
              Icons.analytics,
              theme,
            ),
            const Divider(),
            _buildInventoryStat(
              'Low Stock Items',
              '${status['lowStockCount'] ?? 0} items',
              Icons.warning_amber,
              theme,
              isWarning: true,
            ),
          ],
        ),
      ),
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) => Text('Error: $error'),
    );
  }

  Widget _buildSalesTab(ThemeData theme, NumberFormat currencyFormat) {
    final salesSummaryAsync = ref.watch(salesSummaryProvider(
      (startDate: _dateRange.start, endDate: _dateRange.end),
    ));

    return RefreshIndicator(
      onRefresh: () async {
        ref.invalidate(salesSummaryProvider);
      },
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Sales Summary', style: theme.textTheme.titleLarge),
            const SizedBox(height: 16),
            salesSummaryAsync.when(
              data: (summary) {
                final statuses = List<MapEntry<String, dynamic>>.from(
                  (summary['statuses'] as Map<String, dynamic>).entries,
                );
                
                return Column(
                  children: [
                    // Sales chart
                    SizedBox(
                      height: 200,
                      child: SfCartesianChart(
                        primaryXAxis: CategoryAxis(
                          labelRotation: -45,
                          labelStyle: theme.textTheme.bodySmall,
                        ),
                        primaryYAxis: NumericAxis(
                          numberFormat: NumberFormat.compactCurrency(symbol: '₹'),
                          labelStyle: theme.textTheme.bodySmall,
                        ),
                        series: <CartesianSeries>[
                          ColumnSeries<MapEntry<String, dynamic>, String>(
                            dataSource: statuses,
                            xValueMapper: (entry, _) => '${entry.key}\n${entry.value['count']} ${entry.value['count'] == 1 ? 'sale' : 'sales'}' ,
                            yValueMapper: (entry, _) => entry.value['total'] ?? 0,
                            dataLabelSettings: DataLabelSettings(
                              isVisible: true,
                              labelAlignment: ChartDataLabelAlignment.top,
                              textStyle: theme.textTheme.bodySmall!,
                            ),
                            color: theme.colorScheme.primary,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    
                    // Status summary
                    ...statuses.map((entry) {
                      return ListTile(
                        title: Text(
                          '${entry.key[0].toUpperCase()}${entry.key.substring(1).replaceAll('_', ' ')}',
                          style: theme.textTheme.bodyMedium,
                        ),
                        trailing: Text(
                          '${entry.value['count']} • ${currencyFormat.format(entry.value['total'])}',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      );
                    }).toList(),
                  ],
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, stack) => Text('Error: $error'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProductsTab(ThemeData theme, NumberFormat currencyFormat) {
    final topSellingItemsAsync = ref.watch(topSellingItemsProvider(
      (startDate: _dateRange.start, endDate: _dateRange.end, limit: 10),
    ));

    return RefreshIndicator(
      onRefresh: () async {
        ref.invalidate(topSellingItemsProvider);
      },
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Top Selling Products', style: theme.textTheme.titleLarge),
            const SizedBox(height: 16),
            topSellingItemsAsync.when(
              data: (items) {
                if (items.isEmpty) {
                  return const Center(
                    child: Text('No sales data available for the selected period'),
                  );
                }
                
                return ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: items.length,
                  itemBuilder: (context, index) {
                    final item = items[index];
                    return ListTile(
                      leading: CircleAvatar(
                        child: Text('${index + 1}'),
                      ),
                      title: Text(item['name'] ?? 'Unknown Item'),
                      subtitle: Text('${item['quantity']?.toStringAsFixed(0) ?? 0} sold'),
                      trailing: Text(
                        currencyFormat.format(item['total'] ?? 0),
                        style: theme.textTheme.bodyLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    );
                  },
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, stack) => Text('Error: $error'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCustomersTab(ThemeData theme, NumberFormat currencyFormat) {
    final salesByCustomerAsync = ref.watch(salesByCustomerProvider(
      (startDate: _dateRange.start, endDate: _dateRange.end, limit: 10),
    ));

    return RefreshIndicator(
      onRefresh: () async {
        ref.invalidate(salesByCustomerProvider);
      },
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Top Customers', style: theme.textTheme.titleLarge),
            const SizedBox(height: 16),
            salesByCustomerAsync.when(
              data: (customers) {
                if (customers.isEmpty) {
                  return const Center(
                    child: Text('No customer data available for the selected period'),
                  );
                }
                
                return ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: customers.length,
                  itemBuilder: (context, index) {
                    final customer = customers[index];
                    return ListTile(
                      leading: CircleAvatar(
                        child: Text(customer['name']?[0] ?? '?'),
                      ),
                      title: Text(customer['name'] ?? 'Unknown Customer'),
                      subtitle: Text('${customer['count']} ${customer['count'] == 1 ? 'purchase' : 'purchases'}' ),
                      trailing: Text(
                        currencyFormat.format(customer['total'] ?? 0),
                        style: theme.textTheme.bodyLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    );
                  },
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, stack) => Text('Error: $error'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryCard(
    ThemeData theme, {
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.hintColor,
                ),
              ),
              Icon(icon, color: color, size: 20),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInventoryStat(
    String label,
    String value,
    IconData icon,
    ThemeData theme, {
    bool isWarning = false,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(
            icon,
            size: 20,
            color: isWarning ? Colors.orange : theme.primaryColor,
          ),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.hintColor,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: theme.textTheme.titleMedium?.copyWith(
                  color: isWarning ? Colors.orange : null,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
