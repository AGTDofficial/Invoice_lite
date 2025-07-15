import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:provider/provider.dart';
import '../models/invoice.dart';
import '../models/item_model.dart';
import '../models/item_group.dart';
import '../providers/company_provider.dart';
import 'company_selector_screen.dart';
import 'customers_suppliers_screen.dart';
import 'item_master_screen.dart';
import 'all_accounts_screen.dart';
import 'sales_invoice_screen.dart';
import 'purchase_invoice_screen.dart';
import 'sale_return_list_screen.dart';
import 'purchase_return_list_screen.dart';
import 'sales_list_screen.dart';
import 'purchase_list_screen.dart';

class HomeScreen extends StatefulWidget {
  final Box<Item> itemsBox;
  final Box<ItemGroup> itemGroupsBox;
  
  const HomeScreen({
    super.key,
    required this.itemsBox,
    required this.itemGroupsBox,
  });

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int todaySalesCount = 0;

  @override
  void initState() {
    super.initState();
    _fetchTodaySalesCount();
  }

  Future<void> _fetchTodaySalesCount() async {
    try {
      final today = DateTime.now();
      final invoiceBox = await Hive.openBox<Invoice>('invoices');

      if (!mounted) return;

      final todaySales = invoiceBox.values.where((invoice) {
        final isToday = invoice.date.year == today.year &&
            invoice.date.month == today.month &&
            invoice.date.day == today.day;
        final typeString = invoice.type.toString().toLowerCase();
        return isToday &&
            (typeString.contains('sale') ||
                typeString == 'sale invoice');
      }).toList();

      if (mounted) {
        setState(() {
          todaySalesCount = todaySales.length;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          todaySalesCount = 0;
        });
      }
    }
  }



  @override
  Widget build(BuildContext context) {
    final isTablet = MediaQuery.of(context).size.width >= 600;
    
    return Scaffold(
      appBar: AppBar(
        title: ValueListenableBuilder<dynamic>(
          valueListenable: currentCompany,
          builder: (context, company, _) {
            // Debug print to check the current company
            debugPrint('Current Company: ${company?.toString() ?? 'null'}');
            
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  company?.name?.isNotEmpty == true ? company.name : 'No Company Selected',
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
                if (company?.gstin != null)
                  Text(
                    'GSTIN: ${company.gstin}',
                    style: const TextStyle(fontSize: 12),
                  ),
              ],
            );
          },
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              // TODO: Navigate to settings screen
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Settings screen will be implemented here')),
              );
            },
            tooltip: 'Settings',
          ),
          const SizedBox(width: 8), // Add some spacing between icons
          IconButton(
            icon: const Icon(Icons.business),
            onPressed: () async {
              // Sign out and go back to company selector
              final companyProvider = Provider.of<CompanyProvider>(context, listen: false);
              await companyProvider.clearSelectedCompany();
              if (!mounted) return;
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (_) => const CompanySelectorScreen()),
              );
            },
            tooltip: 'Switch Company',
          ),
          const SizedBox(width: 8), // Add some right padding
        ],
      ),
      body: _buildBody(context, isTablet),
    );
  }

  Widget _buildBody(BuildContext context, bool isTablet) {
    final tileGroups = [
      // 3x3
      [
        _DashboardTile(
          icon: Icons.receipt, 
          label: 'Sale Invoice', 
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const SalesInvoiceScreen(),
              ),
            );
          },
        ),
        _DashboardTile(
          icon: Icons.file_download, 
          label: 'Purchase Invoice', 
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const PurchaseInvoiceScreen(),
              ),
            );
          },
        ),
        _DashboardTile(
          icon: Icons.assignment_return, 
          label: 'Sale Return',
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const SaleReturnListScreen(),
              ),
            );
          },
        ),
      ],
      // 3x3
      [
        _DashboardTile(
          icon: Icons.assignment_returned, 
          label: 'Purchase Return',
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const PurchaseReturnListScreen(),
              ),
            );
          },
        ),
        _DashboardTile(
          icon: Icons.list_alt, 
          label: 'Sale Invoices',
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const SalesListScreen(),
              ),
            );
          },
        ),
        _DashboardTile(
          icon: Icons.list, 
          label: 'Purchase Invoices',
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const PurchaseListScreen(),
              ),
            );
          },
        ),
      ],
      // 3x3
      [
        _DashboardTile(
          icon: Icons.currency_rupee,
          label: "Today's Sales",
          subtitle: "$todaySalesCount sales",
          onTap: () {},
        ),
        _DashboardTile(
          icon: Icons.people, 
          label: 'Customers & Suppliers', 
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const CustomersSuppliersScreen()),
            );
          },
        ),
        _DashboardTile(
          icon: Icons.account_balance_wallet, 
          label: 'Account Manager',
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const AllAccountsScreen()),
            );
          },
        ),
      ],
      // 2x2
      [
        _DashboardTile(
          icon: Icons.inventory, 
          label: 'Inventory', 
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => ItemMasterScreen(
                  itemsBox: widget.itemsBox,
                  itemGroupsBox: widget.itemGroupsBox,
                ),
              ),
            );
          },
        ),
        _DashboardTile(icon: Icons.bar_chart, label: 'GST Reports', onTap: () {}),
      ],
      // 2x1
      [
        _DashboardTile(
          icon: Icons.menu_book, 
          label: 'Day Book', 
          onTap: null
        ),
        _DashboardTile(
          icon: Icons.more_horiz, 
          label: 'More', 
          onTap: null
        ),
      ],
    ];

    return Padding(
      padding: const EdgeInsets.all(12.0),
      child: SingleChildScrollView(
        child: Column(
          children: tileGroups
              .map((group) => Padding(
                    padding: const EdgeInsets.only(bottom: 12.0),
                    child: GridView.count(
                      crossAxisCount: group.length == 2 ? 2 : 3,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      children: group,
                    ),
                  ))
              .toList(),
        ),
      ),
    );
  }
}

class _DashboardTile extends StatelessWidget {
  final IconData? icon;
  final String label;
  final String? subtitle;
  final VoidCallback? onTap;

  const _DashboardTile({
    Key? key,
    this.icon,
    required this.label,
    this.subtitle,
    this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    const Color navyBlue = Color(0xFF060B44);
    final backgroundColor = isDark ? const Color(0xFF1E1E1E) : const Color(0xFFF5F6FA);
    final iconColor = isDark ? navyBlue.withAlpha(204) : navyBlue; // 80% opacity
    final textColor = isDark ? Colors.white : Colors.black87;
    final subtitleColor = navyBlue;

    return Material(
      color: backgroundColor,
      elevation: 4,
      shadowColor: Colors.black.withAlpha(26), // ~10% opacity
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap != null ? () => onTap!() : null,
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(12.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (icon != null) ...[
                  Icon(icon, color: iconColor, size: 32),
                  const SizedBox(height: 8),
                ],
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: textColor,
                  ),
                  textAlign: TextAlign.center,
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    subtitle!,
                    style: TextStyle(
                      fontSize: 12,
                      color: subtitleColor,
                      fontWeight: FontWeight.w400,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
