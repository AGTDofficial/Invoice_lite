import 'package:flutter/material.dart';

class PartyListScreen extends StatelessWidget {
  const PartyListScreen({super.key});
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Customers & Suppliers'),
        actions: [
          PopupMenuButton<String>(
            onSelected: (value) {
              // Handle filter selection
            },
            itemBuilder: (BuildContext context) => [
              PopupMenuItem(
                value: 'all',
                child: Text('All Parties'),
              ),
              PopupMenuItem(
                value: 'customer',
                child: Text('Customers Only'),
              ),
              PopupMenuItem(
                value: 'supplier',
                child: Text('Suppliers Only'),
              ),
            ],
            icon: Icon(Icons.filter_list),
          ),
        ],
      ),
      body: ListView.builder(
        itemCount: 0, // Replace with actual item count
        itemBuilder: (context, index) {
          // Replace with actual party item
          return ListTile(
            title: Text('Party Name'),
            subtitle: Text('GSTIN: 22AAAAA0000A1Z5'),
            trailing: Icon(Icons.chevron_right),
            onTap: () {
              // Navigate to party details/edit screen
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // Navigate to add new party screen
        },
        child: Icon(Icons.add),
      ),
    );
  }
}
