import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/account.dart';

class CustomerSupplierScreen extends StatefulWidget {
  const CustomerSupplierScreen({Key? key}) : super(key: key);

  @override
  _CustomerSupplierScreenState createState() => _CustomerSupplierScreenState();
}

class _CustomerSupplierScreenState extends State<CustomerSupplierScreen> 
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _customerSearchController = TextEditingController();
  final TextEditingController _supplierSearchController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  
  String get _currentSearchQuery => _tabController.index == 0 
      ? _customerSearchController.text 
      : _supplierSearchController.text;
      
  void _onSearchChanged(String value) {
    setState(() {});
  }
  
  void _clearSearch() {
    if (_tabController.index == 0) {
      _customerSearchController.clear();
    } else {
      _supplierSearchController.clear();
    }
    setState(() {});
  }

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this)
      ..addListener(() {
        setState(() {}); // Rebuild when tab changes
      });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _customerSearchController.dispose();
    _supplierSearchController.dispose();
    super.dispose();
  }

  Future<void> _addAccount(bool isCustomer) async {
    if (!Hive.isBoxOpen('accounts')) {
      await Hive.openBox<Account>('accounts');
    }
    
    final accountsBox = Hive.box<Account>('accounts');
    final newAccount = Account(
      name: 'New ${isCustomer ? 'Customer' : 'Supplier'} #${accountsBox.length + 1}',
      phone: '',
      openingBalance: 0.0,
      isCustomer: isCustomer,
      isSupplier: !isCustomer,
      group: isCustomer ? 'Sundry Debtor' : 'Sundry Creditor',
    );
    
    await _showEditDialog(newAccount);
  }

  Future<void> _showEditDialog(Account account) async {
    final nameController = TextEditingController(text: account.name);
    final phoneController = TextEditingController(text: account.phone);
    final balanceController = TextEditingController(
      text: account.balance != 0 ? account.balance.toString() : '',
    );
    
    final isNew = !account.isInBox;

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('${isNew ? 'Add' : 'Edit'} ${account.isCustomer ? 'Customer' : 'Supplier'}'),
        content: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: nameController,
                  decoration: const InputDecoration(labelText: 'Name'),
                  validator: (value) => value?.isEmpty ?? true ? 'Name is required' : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: phoneController,
                  decoration: const InputDecoration(labelText: 'Phone'),
                  keyboardType: TextInputType.phone,
                  validator: (value) => value?.isEmpty ?? true ? 'Phone is required' : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: balanceController,
                  decoration: const InputDecoration(
                    labelText: 'Opening Balance',
                    hintText: '0.00',
                    prefixText: '₹ ',
                  ),
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('CANCEL'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (_formKey.currentState?.validate() ?? false) {
                try {
                  final updatedAccount = account.copyWith(
                    name: nameController.text.trim(),
                    phone: phoneController.text.trim(),
                    openingBalance: double.tryParse(balanceController.text) ?? 0.0,
                  );
                  
                  final accountsBox = Hive.box<Account>('accounts');
                  if (isNew) {
                    await accountsBox.add(updatedAccount);
                  } else {
                    await updatedAccount.save();
                  }
                  
                  if (mounted) {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('${isNew ? 'Added' : 'Updated'} successfully')),
                    );
                  }
                } catch (e) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Error: $e')),
                    );
                  }
                }
              }
            },
            child: Text(isNew ? 'ADD' : 'UPDATE'),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    final isCustomerTab = _tabController.index == 0;
    final currentController = isCustomerTab ? _customerSearchController : _supplierSearchController;
    final hasSearchText = currentController.text.isNotEmpty;
    
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: TextField(
        controller: currentController,
        decoration: InputDecoration(
          hintText: 'Search ${isCustomerTab ? 'Customers' : 'Suppliers'}',
          prefixIcon: const Icon(Icons.search, color: Colors.grey),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(color: Colors.grey[300]!),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(color: Colors.grey[300]!),
          ),
          filled: true,
          fillColor: Colors.grey[100],
          contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 16),
          suffixIcon: hasSearchText
              ? IconButton(
                  icon: const Icon(Icons.clear, size: 20, color: Colors.grey),
                  onPressed: _clearSearch,
                )
              : null,
        ),
        onChanged: _onSearchChanged,
      ),
    );
  }

  Widget _buildList(bool isCustomer) {
    if (!Hive.isBoxOpen('accounts')) {
      return const Center(child: CircularProgressIndicator());
    }
    
    final accountsBox = Hive.box<Account>('accounts');
    
    return ValueListenableBuilder<Box<Account>>(
      valueListenable: accountsBox.listenable(),
      builder: (context, box, _) {
        try {
          var accounts = box.values
              .where((account) => account.isCustomer == isCustomer)
              .toList();
              
          final searchQuery = _currentSearchQuery;
          if (searchQuery.isNotEmpty) {
            final searchLower = searchQuery.toLowerCase();
            accounts = accounts.where((account) {
              return account.name.toLowerCase().contains(searchLower) ||
                     account.phone.toLowerCase().contains(searchLower);
            }).toList();
          }

          if (accounts.isEmpty) {
            return Center(
              child: Text('No ${isCustomer ? 'customers' : 'suppliers'} found'),
            );
          }

          return ListView.builder(
            itemCount: accounts.length,
            itemBuilder: (context, index) {
              final account = accounts[index];
              return ListTile(
                key: ValueKey(account.key),
                leading: CircleAvatar(
                  child: Text(account.name.isNotEmpty ? account.name[0].toUpperCase() : '?'),
                ),
                title: Text(account.name),
                subtitle: Text(account.phone),
                trailing: Text(
                  '₹${account.balance.toStringAsFixed(2)}',
                  style: TextStyle(
                    color: account.balance < 0 ? Colors.red : Colors.green,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                onTap: () => _showEditDialog(account),
                onLongPress: () {
                  showModalBottomSheet(
                    context: context,
                    builder: (context) => Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        ListTile(
                          leading: const Icon(Icons.edit, color: Colors.blue),
                          title: const Text('Edit'),
                          onTap: () {
                            Navigator.pop(context);
                            _showEditDialog(account);
                          },
                        ),
                        ListTile(
                          leading: const Icon(Icons.delete, color: Colors.red),
                          title: const Text('Delete', style: TextStyle(color: Colors.red)),
                          onTap: () {
                            Navigator.pop(context);
                            _deleteAccount(account);
                          },
                        ),
                      ],
                    ),
                  );
                },
              );
            },
          );
        } catch (e) {
          debugPrint('Error building account list: $e');
          return Center(
            child: Text('Error loading ${isCustomer ? 'customers' : 'suppliers'}: $e'),
          );
        }
      },
    );
  }

  Future<void> _deleteAccount(Account account) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Delete'),
        content: Text('Are you sure you want to delete ${account.name}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('CANCEL'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('DELETE'),
          ),
        ],
      ),
    );

    if (confirmed == true && account.isInBox) {
      try {
        await account.delete();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Deleted successfully')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error deleting: $e')),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Customers & Suppliers'),
          bottom: TabBar(
            controller: _tabController,
            tabs: const [
              Tab(text: 'CUSTOMERS'),
              Tab(text: 'SUPPLIERS'),
            ],
            onTap: (index) => setState(() {}),
          ),
        ),
        body: Column(
          children: [
            _buildSearchBar(),
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildList(true),  // Customers
                  _buildList(false), // Suppliers
                ],
              ),
            ),
          ],
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: () => _addAccount(_tabController.index == 0),
          child: const Icon(Icons.add),
        ),
      ),
    );
  }
}
