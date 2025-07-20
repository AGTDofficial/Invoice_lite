import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:invoice_lite/core/routes/app_router.dart';
import 'package:invoice_lite/features/customers/presentation/screens/customers_list_screen.dart';
import 'package:invoice_lite/features/invoices/presentation/screens/invoices_list_screen.dart';

void main() async {
  // Ensure Flutter bindings are initialized
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize app
  runApp(
    const ProviderScope(
      child: InvoiceLiteApp(),
    ),
  );
}

class InvoiceLiteApp extends StatelessWidget {
  const InvoiceLiteApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Invoice Lite',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
        inputDecorationTheme: InputDecorationTheme(
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8.0),
          ),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16.0,
            vertical: 12.0,
          ),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 16.0),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8.0),
            ),
          ),
        ),
      ),
      onGenerateRoute: AppRouter.generateRoute,
      initialRoute: '/',
      routes: {
        '/': (context) => const HomeScreen(),
      },
    );
  }
}

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Invoice Lite'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            onPressed: () {
              // TODO: Navigate to settings
            },
          ),
        ],
      ),
      body: GridView.count(
        padding: const EdgeInsets.all(16),
        crossAxisCount: 2,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        children: [
          _buildMenuCard(
            context,
            title: 'Invoices',
            icon: Icons.receipt_long_outlined,
            color: Colors.blue,
            onTap: () {
              Navigator.of(context).pushNamed(InvoicesListScreen.routeName);
            },
          ),
          _buildMenuCard(
            context,
            title: 'Customers',
            icon: Icons.people_outline,
            color: Colors.green,
            onTap: () {
              AppRouter.navigateToCustomersList(context);
            },
          ),
          _buildMenuCard(
            context,
            title: 'Items',
            icon: Icons.inventory_2_outlined,
            color: Colors.orange,
            onTap: () {
              AppRouter.navigateToItemsList(context);
            },
          ),
          _buildMenuCard(
            context,
            title: 'Reports',
            icon: Icons.bar_chart_outlined,
            color: Colors.purple,
            onTap: () {
              AppRouter.navigateToReports(context);
            },
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          AppRouter.navigateToAddEditInvoice(context);
        },
        icon: const Icon(Icons.add),
        label: const Text('New Invoice'),
      ),
    );
  }
  
  Widget _buildMenuCard(
    BuildContext context, {
    required String title,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 2,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 32, color: color),
            ),
            const SizedBox(height: 12),
            Text(
              title,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
