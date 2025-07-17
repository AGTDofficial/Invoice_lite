import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../models/account.dart';
import '../providers/account_provider.dart';
import 'account_form_screen.dart';

class CustomersSuppliersScreen extends StatefulWidget {
  const CustomersSuppliersScreen({Key? key}) : super(key: key);

  @override
  _CustomersSuppliersScreenState createState() => _CustomersSuppliersScreenState();
}

class _CustomersSuppliersScreenState extends State<CustomersSuppliersScreen> with SingleTickerProviderStateMixin {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  late TabController _tabController;
  final _numberFormat = NumberFormat.currency(symbol: '₹', decimalDigits: 2);

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text.toLowerCase();
      });
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _tabController.dispose();
    super.dispose();
  }

  void _navigateToAccountForm({Account? account, bool isSupplier = false}) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AccountFormScreen(
          account: account,
          isSupplier: isSupplier,
        ),
      ),
    ).then((_) => setState(() {}));
  }

  Widget _buildListTile(Account account) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: ListTile(
        leading: CircleAvatar(
          child: Icon(account.group == 'Sundry Creditor' ? Icons.business : Icons.person),
        ),
        title: Text(
          account.name,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (account.phone.isNotEmpty)
              Text('Phone: ${account.phone}'),
            if (account.panNumber != null && account.panNumber!.isNotEmpty)
              Text('PAN: ${account.panNumber}'),
            Text(
              'Balance: ${_numberFormat.format(account.balance)}',
              style: TextStyle(
                color: account.balance < 0 ? Colors.red : Colors.green,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        onTap: () => _navigateToAccountForm(
          account: account,
          isSupplier: account.group == 'Sundry Creditor' || account.isSupplier,
        ),
      ),
    );
  }

  Widget _buildAccountList(List<Account> accounts) {
    if (accounts.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.people_outline, size: 64, color: Colors.grey),
            const SizedBox(height: 16),
            Text(
              'No accounts found',
              style: Theme.of(context).textTheme.titleLarge,
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      itemCount: accounts.length,
      itemBuilder: (context, index) => _buildListTile(accounts[index]),
    );
  }

  Widget _buildTabContent(AccountProvider accountProvider, bool isSupplier) {
    final accounts = isSupplier ? accountProvider.suppliers : accountProvider.customers;
    
    if (accounts.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              isSupplier ? Icons.business_outlined : Icons.people_outline,
              size: 64,
              color: Colors.grey,
            ),
            const SizedBox(height: 16),
            Text(
              'No ${isSupplier ? 'suppliers' : 'customers'} found',
              style: Theme.of(context).textTheme.titleLarge,
            ),
          ],
        ),
      );
    }
    
    if (_searchQuery.isNotEmpty) {
      final searchLower = _searchQuery.toLowerCase();
      final filteredAccounts = accounts.where((account) {
        if (account.name.toLowerCase().contains(searchLower)) return true;
        
        if (account.phone.toLowerCase().contains(searchLower)) return true;
        
        if (account.panNumber?.toLowerCase().contains(searchLower) == true) return true;
        
        return false;
      }).toList();
      
      if (filteredAccounts.isEmpty) {
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                isSupplier ? Icons.search_off_outlined : Icons.people_outline,
                size: 64,
                color: Colors.grey,
              ),
              const SizedBox(height: 16),
              Text(
                'No matching ${isSupplier ? 'suppliers' : 'customers'}',
                style: Theme.of(context).textTheme.titleLarge,
              ),
            ],
          ),
        );
      }
      
      return _buildAccountList(filteredAccounts);
    }
    
    return _buildAccountList(accounts);
  }

  @override
  Widget build(BuildContext context) {
    final accountProvider = Provider.of<AccountProvider>(context);
    
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Customers & Suppliers'),
          bottom: TabBar(
            controller: _tabController,
            tabs: const [
              Tab(icon: Icon(Icons.people_outline), text: 'Customers'),
              Tab(icon: Icon(Icons.business), text: 'Suppliers'),
            ],
          ),
        ),
        body: Column(
          children: [
            // Search bar
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'Search...',
                  prefixIcon: const Icon(Icons.search),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  suffixIcon: _searchController.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear),
                          onPressed: () {
                            _searchController.clear();
                            setState(() => _searchQuery = '');
                          },
                        )
                      : null,
                ),
              ),
            ),
            
            // Tab bar view
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildTabContent(accountProvider, false), // Customers
                  _buildTabContent(accountProvider, true),  // Suppliers
                ],
              ),
            ),
          ],
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: () => _navigateToAccountForm(
            isSupplier: _tabController.index == 1,
          ),
          child: Icon(_tabController.index == 1 ? Icons.add_business : Icons.person_add),
          tooltip: _tabController.index == 1 ? 'Add Supplier' : 'Add Customer',
        ),
      ),
    );
  }
}
