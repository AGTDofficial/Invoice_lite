import 'dart:async';
import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:provider/provider.dart';
import '../models/company.dart';
import '../models/item_model.dart';
import '../models/item_group.dart';
import '../providers/company_provider.dart';
import 'home_screen.dart';
import 'company_form_screen.dart';

class CompanySelectorScreen extends StatefulWidget {
  const CompanySelectorScreen({super.key});

  @override
  State<CompanySelectorScreen> createState() => _CompanySelectorScreenState();
}

class _CompanySelectorScreenState extends State<CompanySelectorScreen> {
  late Box<Company> companyBox;
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _initializeHive();
  }

  Future<void> _initializeHive() async {
    try {
      // Ensure Hive is initialized
      if (!Hive.isBoxOpen('companies')) {
        await Hive.openBox<Company>('companies');
      }
      companyBox = Hive.box<Company>('companies');
      setState(() {
        _isLoading = false;
      });
    } catch (e, stackTrace) {
      debugPrint('Error initializing CompanySelectorScreen: $e');
      debugPrint('Stack trace: $stackTrace');
      setState(() {
        _errorMessage = 'Failed to load companies. Please try again.';
        _isLoading = false;
      });
    }
  }

  Future<void> _onCompanySelected(Company company) async {
    final companyProvider = Provider.of<CompanyProvider>(context, listen: false);
    await companyProvider.setSelectedCompany(company);
    if (!mounted) return;
    
    // Get the boxes from the global Hive instance
    final itemsBox = Hive.box<Item>('itemsBox');
    final itemGroupsBox = Hive.box<ItemGroup>('itemGroups');
    
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => HomeScreen(
          itemsBox: itemsBox,
          itemGroupsBox: itemGroupsBox,
        ),
      ),
    );
  }

  void _navigateToAddCompany() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const CompanyFormScreen()),
    ).then((_) => setState(() {}));
  }

  void _navigateToEditCompany(Company company, int index) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => CompanyFormScreen(company: company, companyIndex: index),
      ),
    ).then((_) => setState(() {}));
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('Loading companies...'),
            ],
          ),
        ),
      );
    }

    if (_errorMessage != null) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, color: Colors.red, size: 48),
              const SizedBox(height: 16),
              Text(
                _errorMessage!,
                style: Theme.of(context).textTheme.titleMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _initializeHive,
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    final companies = companyBox.values.toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Select a Company'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: _navigateToAddCompany,
          ),
        ],
      ),
      body: companies.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.business, size: 48, color: Colors.grey),
                  const SizedBox(height: 16),
                  const Text(
                    'No companies found',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  const Text('Tap the + button to add a new company'),
                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    onPressed: _navigateToAddCompany,
                    icon: const Icon(Icons.add_business),
                    label: const Text('Add Company'),
                  ),
                ],
              ),
            )
          : ListView.builder(
              itemCount: companies.length,
              itemBuilder: (_, index) {
                final company = companies[index];
                return Card(
                  margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  child: ListTile(
                    title: Text(
                      company.name,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Text(company.gstin),
                    onTap: () async => await _onCompanySelected(company),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.edit, color: Colors.blue),
                          onPressed: () => _navigateToEditCompany(company, company.key as int),
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete, color: Colors.red),
                          onPressed: () => _confirmDeleteCompany(company, context, index),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }

  Future<void> _confirmDeleteCompany(Company company, BuildContext context, int index) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Confirm Deletion'),
        content: Text('Are you sure you want to delete ${company.name}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await companyBox.deleteAt(index);
        if (mounted) {
          setState(() {});
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Company deleted successfully'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error deleting company: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }
}
