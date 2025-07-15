import 'package:flutter/material.dart';

class FinancialReportsScreen extends StatefulWidget {
  const FinancialReportsScreen({super.key});
  
  @override
  State<FinancialReportsScreen> createState() => _FinancialReportsScreenState();
}

class _FinancialReportsScreenState extends State<FinancialReportsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  DateTime _fromDate = DateTime(DateTime.now().year, 1, 1);
  DateTime _toDate = DateTime.now();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Financial Reports'),
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            Tab(text: 'Profit & Loss'),
            Tab(text: 'Balance Sheet'),
            Tab(text: 'Cash Flow'),
          ],
        ),
      ),
      body: Column(
        children: [
          _buildDateRangeSelector(),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildProfitAndLossTab(),
                _buildBalanceSheetTab(),
                _buildCashFlowTab(),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _exportReport,
        icon: Icon(Icons.picture_as_pdf),
        label: Text('Export PDF'),
      ),
    );
  }

  Widget _buildDateRangeSelector() {
    return Card(
      margin: EdgeInsets.all(8.0),
      child: Padding(
        padding: EdgeInsets.all(12.0),
        child: Row(
          children: [
            Expanded(
              child: ListTile(
                title: Text('From'),
                subtitle: Text('${_fromDate.toLocal()}'.split(' ')[0]),
                onTap: () => _selectDate(context, true),
              ),
            ),
            Icon(Icons.arrow_forward),
            Expanded(
              child: ListTile(
                title: Text('To'),
                subtitle: Text('${_toDate.toLocal()}'.split(' ')[0]),
                onTap: () => _selectDate(context, false),
              ),
            ),
            PopupMenuButton<String>(
              onSelected: (value) {
                final now = DateTime.now();
                setState(() {
                  switch (value) {
                    case 'this_month':
                      _fromDate = DateTime(now.year, now.month, 1);
                      _toDate = now;
                      break;
                    case 'last_month':
                      _fromDate = DateTime(now.year, now.month - 1, 1);
                      _toDate = DateTime(now.year, now.month, 0);
                      break;
                    case 'this_year':
                      _fromDate = DateTime(now.year, 1, 1);
                      _toDate = now;
                      break;
                    case 'last_year':
                      _fromDate = DateTime(now.year - 1, 1, 1);
                      _toDate = DateTime(now.year - 1, 12, 31);
                      break;
                  }
                });
                _refreshData();
              },
              itemBuilder: (BuildContext context) => [
                PopupMenuItem(
                  value: 'this_month',
                  child: Text('This Month'),
                ),
                PopupMenuItem(
                  value: 'last_month',
                  child: Text('Last Month'),
                ),
                PopupMenuItem(
                  value: 'this_year',
                  child: Text('This Year'),
                ),
                PopupMenuItem(
                  value: 'last_year',
                  child: Text('Last Year'),
                ),
              ],
              icon: Icon(Icons.date_range),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfitAndLossTab() {
    return ListView(
      children: [
        _buildSectionHeader('Income'),
        _buildAccountItem('Sales', 50000.0, true),
        _buildAccountItem('Other Income', 2000.0, true),
        _buildSectionTotal('Total Income', 52000.0, true),
        
        _buildSectionHeader('Expenses'),
        _buildAccountItem('Purchases', 30000.0, false),
        _buildAccountItem('Salary', 10000.0, false),
        _buildAccountItem('Rent', 5000.0, false),
        _buildAccountItem('Utilities', 2000.0, false),
        _buildSectionTotal('Total Expenses', 47000.0, false),
        
        _buildNetProfitLoss(5000.0),
      ],
    );
  }

  Widget _buildBalanceSheetTab() {
    return ListView(
      children: [
        _buildSectionHeader('Assets'),
        _buildAccountItem('Current Assets', 100000.0, true),
        _buildAccountItem('Fixed Assets', 200000.0, true),
        _buildSectionTotal('Total Assets', 300000.0, true),
        
        _buildSectionHeader('Liabilities'),
        _buildAccountItem('Current Liabilities', 50000.0, false),
        _buildAccountItem('Long Term Liabilities', 100000.0, false),
        _buildSectionTotal('Total Liabilities', 150000.0, false),
        
        _buildSectionHeader('Equity'),
        _buildAccountItem('Retained Earnings', 50000.0, true),
        _buildAccountItem('Current Year Profit', 100000.0, true),
        _buildSectionTotal('Total Equity', 150000.0, true),
      ],
    );
  }

  Widget _buildCashFlowTab() {
    return ListView(
      children: [
        _buildSectionHeader('Operating Activities'),
        _buildCashFlowItem('Cash from Sales', 55000.0, true),
        _buildCashFlowItem('Cash Paid to Suppliers', -30000.0, false),
        _buildCashFlowItem('Cash Paid for Expenses', -15000.0, false),
        _buildSectionTotal('Net Cash from Operations', 10000.0, true),
        
        _buildSectionHeader('Investing Activities'),
        _buildCashFlowItem('Purchase of Assets', -20000.0, false),
        _buildSectionTotal('Net Cash from Investing', -20000.0, false),
        
        _buildSectionHeader('Financing Activities'),
        _buildCashFlowItem("Owner's Investment", 50000.0, true),
        _buildCashFlowItem('Drawings', -10000.0, false),
        _buildSectionTotal('Net Cash from Financing', 40000.0, true),
        
        _buildNetCashFlow(30000.0),
      ],
    );
  }

  Widget _buildSectionHeader(String title) {
    return Container(
      padding: EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
      color: Theme.of(context).primaryColor.withAlpha(26), // ~10% opacity (255 * 0.1 ≈ 26)
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleMedium?.copyWith(
          fontWeight: FontWeight.bold,
          color: Theme.of(context).primaryColor,
        ),
      ),
    );
  }

  Widget _buildAccountItem(String name, double amount, bool isPositive) {
    return ListTile(
      title: Text(name),
      trailing: Text(
        '${isPositive ? '+' : '-'}₹${amount.abs().toStringAsFixed(2)}',
        style: TextStyle(
          color: isPositive ? Colors.green : Colors.red,
          fontWeight: FontWeight.bold,
        ),
      ),
      onTap: () {
        // Navigate to account details
      },
    );
  }

  Widget _buildCashFlowItem(String name, double amount, bool isInflow) {
    return _buildAccountItem(name, amount, isInflow);
  }

  Widget _buildSectionTotal(String label, double amount, bool isPositive) {
    return Container(
      padding: EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(color: Colors.grey.shade300),
          bottom: BorderSide(color: Colors.grey.shade300),
        ),
        color: Colors.grey.shade100,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          Text(
            '${isPositive ? '+' : ''}₹${amount.toStringAsFixed(2)}',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: isPositive ? Colors.green : Colors.red,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNetProfitLoss(double amount) {
    final isProfit = amount >= 0;
    return Container(
      padding: EdgeInsets.all(16.0),
      margin: EdgeInsets.all(8.0),
      decoration: BoxDecoration(
        color: isProfit ? Colors.green.shade50 : Colors.red.shade50,
        borderRadius: BorderRadius.circular(8.0),
        border: Border.all(
          color: isProfit ? Colors.green.shade200 : Colors.red.shade200,
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            isProfit ? 'Net Profit' : 'Net Loss',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 18.0,
            ),
          ),
          Text(
            '${isProfit ? '+' : ''}₹${amount.abs().toStringAsFixed(2)}',
            style: TextStyle(
              fontSize: 20.0,
              fontWeight: FontWeight.bold,
              color: isProfit ? Colors.green : Colors.red,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNetCashFlow(double amount) {
    final isPositive = amount >= 0;
    return Container(
      padding: EdgeInsets.all(16.0),
      margin: EdgeInsets.all(8.0),
      decoration: BoxDecoration(
        color: isPositive ? Colors.blue.shade50 : Colors.orange.shade50,
        borderRadius: BorderRadius.circular(8.0),
        border: Border.all(
          color: isPositive ? Colors.blue.shade200 : Colors.orange.shade200,
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            isPositive ? 'Net Increase in Cash' : 'Net Decrease in Cash',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 18.0,
            ),
          ),
          Text(
            '${isPositive ? '+' : ''}₹${amount.abs().toStringAsFixed(2)}',
            style: TextStyle(
              fontSize: 20.0,
              fontWeight: FontWeight.bold,
              color: isPositive ? Colors.blue : Colors.orange,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _selectDate(BuildContext context, bool isFromDate) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: isFromDate ? _fromDate : _toDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
    );
    if (picked != null) {
      setState(() {
        if (isFromDate) {
          _fromDate = picked;
        } else {
          _toDate = picked;
        }
      });
      _refreshData();
    }
  }

  void _refreshData() {
    // Refresh data based on selected date range
    // Implement your data fetching logic here
  }

  void _exportReport() {
    // Implement PDF export functionality
    final snackBar = SnackBar(
      content: Text('Exporting report to PDF...'),
      duration: Duration(seconds: 2),
    );
    ScaffoldMessenger.of(context).showSnackBar(snackBar);
  }
}
