import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../models/account.dart';
import '../providers/account_provider.dart';
import 'account_form_screen.dart';
import 'account_group_screen.dart';

class AllAccountsScreen extends StatefulWidget {
  const AllAccountsScreen({Key? key}) : super(key: key);

  @override
  _AllAccountsScreenState createState() => _AllAccountsScreenState();
}

class _AllAccountsScreenState extends State<AllAccountsScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _selectedGroup = 'All';
  String _searchQuery = '';
  final _numberFormat = NumberFormat.currency(symbol: '₹', decimalDigits: 2);

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text.toLowerCase();
      });
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _navigateToAccountForm({Account? account}) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AccountFormScreen(
          account: account,
          isCustomer: _selectedGroup == 'Sundry Debtor',
          isSupplier: _selectedGroup == 'Sundry Creditor',
        ),
      ),
    ).then((_) {
      // Refresh the list when returning from the form
      setState(() {});
    });
  }

  Widget _buildAccountCard(Account account) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: ListTile(
        title: Text(
          account.name,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (account.phone.isNotEmpty)
              Text('Phone: ${account.phone}'),
            if (account.email != null && account.email!.isNotEmpty)
              Text('Email: ${account.email}'),
            Text('Group: ${account.group}'),
          ],
        ),
        trailing: Text(
          _numberFormat.format(account.balance),
          style: TextStyle(
            color: account.balance < 0 ? Colors.red : Colors.green,
            fontWeight: FontWeight.bold,
          ),
        ),
        onTap: () => _navigateToAccountForm(account: account),
      ),
    );
  }

  Widget _buildAccountsList(AccountProvider accountProvider) {
    final accounts = accountProvider.accounts;
    
    // Filter accounts based on search query and selected group
    final filteredAccounts = accounts.where((account) {
      final phone = account.phone;
      final email = account.email ?? '';
      final searchLower = _searchQuery.toLowerCase();
      final matchesSearch = _searchQuery.isEmpty ||
          account.name.toLowerCase().contains(searchLower) ||
          phone.toLowerCase().contains(searchLower) ||
          email.toLowerCase().contains(searchLower);

      if (!matchesSearch) return false;
      if (_selectedGroup == 'All') return true;
      return account.group == _selectedGroup;
    }).toList();

    if (filteredAccounts.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.account_balance_wallet_outlined, size: 64, color: Colors.grey),
            const SizedBox(height: 16),
            Text(
              _searchQuery.isEmpty ? 'No accounts found' : 'No matching accounts',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            if (_searchQuery.isNotEmpty || _selectedGroup != 'All')
              TextButton(
                onPressed: () {
                  setState(() {
                    _searchController.clear();
                    _searchQuery = '';
                    _selectedGroup = 'All';
                  });
                },
                child: const Text('Clear filters'),
              ),
          ],
        ),
      );
    }

    return ListView.builder(
      itemCount: filteredAccounts.length,
      itemBuilder: (context, index) => _buildAccountCard(filteredAccounts[index]),
    );
  }

  void _showFilterDialog(AccountProvider accountProvider) {
    final groups = accountProvider.accounts.map((a) => a.group).toSet().toList()..sort();
    groups.insert(0, 'All');
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Filter by Account Group'),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: groups.length,
            itemBuilder: (context, index) {
              final group = groups[index];
              return RadioListTile<String>(
                title: Text(group),
                value: group,
                groupValue: _selectedGroup,
                onChanged: (value) {
                  setState(() {
                    _selectedGroup = value!;
                  });
                  Navigator.pop(context);
                },
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              setState(() {
                _selectedGroup = 'All';
              });
              Navigator.pop(context);
            },
            child: const Text('Clear Filter'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final accountProvider = Provider.of<AccountProvider>(context);
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('All Accounts'),
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_alt),
            onPressed: () => _showFilterDialog(accountProvider),
            tooltip: 'Filter by account group',
          ),
          const SizedBox(width: 4),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _navigateToAccountForm(),
        tooltip: 'Add new account',
        child: const Icon(Icons.add),
      ),
      body: Column(
        children: [
          // Account Group Button
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
            child: Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const AccountGroupScreen(),
                        ),
                      );
                    },
                    icon: const Icon(Icons.group_work),
                    label: const Text('Account Groups'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Selected filter indicator
          if (_selectedGroup != 'All')
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
              child: Row(
                children: [
                  Chip(
                    label: Text('Group: $_selectedGroup'),
                    deleteIcon: const Icon(Icons.close, size: 16),
                    onDeleted: () {
                      setState(() {
                        _selectedGroup = 'All';
                      });
                    },
                  ),
                ],
              ),
            ),
          // Search bar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search accounts...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          setState(() {
                            _searchQuery = '';
                          });
                        },
                      )
                    : null,
              ),
            ),
          ),
          

          
          // Accounts list
          Expanded(
            child: _buildAccountsList(accountProvider),
          ),
        ],
      ),
    );
  }
}
