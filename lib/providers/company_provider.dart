import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import '../models/company.dart';

final ValueNotifier<Company?> currentCompany = ValueNotifier<Company?>(null);

class CompanyProvider extends ChangeNotifier {
  static const String _selectedCompanyKey = 'selected_company_id';
  late final Box<Company> _companyBox;
  late final Box<dynamic> _settingsBox;
  bool _isInitialized = false;
  Company? _currentCompany;

  Company? get currentCompany => _currentCompany;

  Future<void> init(Box<Company> companyBox, Box<dynamic> settingsBox) async {
    if (_isInitialized) return;
    
    try {
      _companyBox = companyBox;
      _settingsBox = settingsBox;
      
      await _loadSelectedCompany();
      _isInitialized = true;
      notifyListeners();
    } catch (e) {
      debugPrint('Error initializing CompanyProvider: $e');
      rethrow;
    }
  }

  Future<void> _loadSelectedCompany() async {
    try {
      final companyId = _settingsBox.get(_selectedCompanyKey);
      if (companyId == null) return;
      
      try {
        _currentCompany = _companyBox.values.firstWhere(
          (c) => c.key.toString() == companyId.toString(),
        );
        notifyListeners();
      } catch (e) {
        _currentCompany = null;
      }
    } catch (e) {
      debugPrint('Error loading selected company: $e');
    }
  }

  Future<void> setSelectedCompany(Company company) async {
    await _settingsBox.put(_selectedCompanyKey, company.key);
    _currentCompany = company;
    notifyListeners();
  }

  Future<void> clearSelectedCompany() async {
    await _settingsBox.delete(_selectedCompanyKey);
    _currentCompany = null;
    notifyListeners();
  }

  Future<List<Company>> getCompanies() async {
    return _companyBox.values.toList();
  }

  Future<Company> createCompany(Company company) async {
    await _companyBox.add(company);
    return company;
  }

  Future<void> updateCompany(Company company) async {
    await company.save();
    if (_currentCompany?.key == company.key) {
      _currentCompany = company;
      notifyListeners();
    }
  }

  Future<void> deleteCompany(Company company) async {
    if (_currentCompany?.key == company.key) {
      await clearSelectedCompany();
    }
    await company.delete();
  }
}
