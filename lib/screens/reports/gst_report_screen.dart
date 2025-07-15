import 'package:flutter/material.dart';

class GSTReportScreen extends StatefulWidget {
  const GSTReportScreen({super.key});
  
  @override
  State<GSTReportScreen> createState() => _GSTReportScreenState();
}

class _GSTReportScreenState extends State<GSTReportScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  DateTime _fromDate = DateTime.now().subtract(Duration(days: 30));
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
        title: Text('GST Reports'),
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            Tab(text: 'GSTR-1'),
            Tab(text: 'GSTR-2'),
            Tab(text: 'GSTR-3B'),
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
                _buildGSTR1Tab(),
                _buildGSTR2Tab(),
                _buildGSTR3BTab(),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _exportReport,
        icon: Icon(Icons.file_download),
        label: Text('Export'),
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
            IconButton(
              icon: Icon(Icons.refresh),
              onPressed: _refreshData,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGSTR1Tab() {
    return ListView(
      children: [
        _buildReportSection('B2B Invoices', []),
        _buildReportSection('B2CS Invoices', []),
        _buildReportSection('Credit/Debit Notes', []),
      ],
    );
  }

  Widget _buildGSTR2Tab() {
    return ListView(
      children: [
        _buildReportSection('B2B Invoices', []),
        _buildReportSection('IMPS Imports', []),
        _buildReportSection('Credit/Debit Notes', []),
      ],
    );
  }

  Widget _buildGSTR3BTab() {
    return ListView(
      children: [
        _buildReportSection('Summary', []),
        _buildReportSection('Outward Supplies', []),
        _buildReportSection('Input Tax Credit', []),
      ],
    );
  }

  Widget _buildReportSection(String title, List<dynamic> items) {
    return Card(
      margin: EdgeInsets.all(8.0),
      child: ExpansionTile(
        title: Text(title, style: TextStyle(fontWeight: FontWeight.bold)),
        children: items.isEmpty
            ? [ListTile(title: Text('No data available'))]
            : items.map((item) => ListTile(
                  title: Text(item.toString()),
                  // Add more detailed item display here
                )).toList(),
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
    // Implement export functionality
    final snackBar = SnackBar(
      content: Text('Exporting report...'),
      duration: Duration(seconds: 2),
    );
    ScaffoldMessenger.of(context).showSnackBar(snackBar);
  }
}
