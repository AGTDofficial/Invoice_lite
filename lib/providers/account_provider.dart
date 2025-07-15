import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';
import 'package:collection/collection.dart';

import '../models/account.dart';

class AccountProvider with ChangeNotifier {
  static const String _boxName = 'accounts';
  late Box<Account> _accountsBox;
  
  List<Account> _accounts = [];
  
  List<Account> get accounts => _accounts.toList();
  
  // Get customers (accounts with isCustomer = true or in Sundry Debtor group)
  List<Account> get customers => _accounts.where((a) => a.isCustomer || a.group == 'Sundry Debtor').toList();
  
  // Get suppliers (accounts with isSupplier = true or in Sundry Creditor group)
  List<Account> get suppliers => _accounts.where((a) => a.isSupplier || a.group == 'Sundry Creditor').toList();

  Future<void> init() async {
    _accountsBox = await Hive.openBox<Account>(_boxName);
    _loadAccounts();
  }

  void _loadAccounts() {
    _accounts = _accountsBox.values.toList();
    notifyListeners();
  }

  Future<void> addAccount(Account account) async {
    // Check for duplicate name (case-insensitive)
    final exists = _accounts.any((a) => 
      a.name.toLowerCase() == account.name.toLowerCase() && a.key != account.key);
    
    if (exists) {
      throw Exception('An account with this name already exists');
    }
    
    await _accountsBox.add(account);
    _loadAccounts();
  }

  Future<void> updateAccount(Account account) async {
    if (account.key == null) {
      throw Exception('Cannot update account without a key');
    }
    
    // Check for duplicate name (case-insensitive), excluding current account
    final exists = _accounts.any((a) => 
      a.name.toLowerCase() == account.name.toLowerCase() && a.key != account.key);
    
    if (exists) {
      throw Exception('Another account with this name already exists');
    }
    
    await account.save();
    _loadAccounts();
  }

  Future<void> deleteAccount(Account account) async {
    // Check if account is used in any transaction before deleting
    final hasTransactions = await _hasTransactionReferences(account);
    
    if (hasTransactions) {
      throw Exception('Cannot delete account: It has associated transactions');
    }
    
    await account.delete();
    _loadAccounts();
  }
  
  // Check if an account has any transaction references
  Future<bool> _hasTransactionReferences(Account account) async {
    // TODO: Implement actual transaction reference check
    // For now, we'll just check if there are any transactions in the transactions box
    try {
      final transactionBox = await Hive.openBox('transactions');
      // If transactions box doesn't exist, no transactions to check against
      if (!transactionBox.isOpen) return false;
      
      // TODO: Implement proper transaction reference check
      // For now, we'll assume no transactions exist
      return false;
    } catch (e) {
      // If there's any error, assume no transactions to be safe
      return false;
    }
  }
  
  Future<Account?> getAccountByKey(int key) async {
    return _accountsBox.get(key);
  }
  
  List<Account> searchAccounts(String query) {
    if (query.isEmpty) return [];
    
    final lowerQuery = query.toLowerCase();
    return _accounts.where((account) {
      if (account.name.toLowerCase().contains(lowerQuery)) return true;
      
      if (account.phone.toLowerCase().contains(lowerQuery)) return true;
      
      final email = account.email;
      if (email != null && email.toLowerCase().contains(lowerQuery)) return true;
      
      final gstinUin = account.gstinUin;
      if (gstinUin != null && gstinUin.toLowerCase().contains(lowerQuery)) return true;
      
      return false;
    }).toList();
  }
  
  // Get accounts by group
  List<Account> getAccountsByGroup(String groupName) {
    return _accounts.where((a) => a.group == groupName).toList();
  }
  
  // Get account balance including opening balance and transactions
  double getAccountBalance(int accountKey) {
    final account = _accounts.firstWhereOrNull((a) => a.key == accountKey);
    if (account == null) return 0.0;
    
    // Start with opening balance (already considers isCredit)
    double balance = account.openingBalance * (account.isCredit ? -1 : 1);
    
    // TODO: Add transaction calculations here when transaction system is implemented
    // For now, we're just using the opening balance with proper sign
    
    return balance;
  }
  
  // Get total balance for all accounts in a group
  double getGroupBalance(String groupName) {
    return _accounts
        .where((a) => a.group == groupName)
        .fold(0.0, (sum, account) => sum + account.openingBalance);
  }
}
