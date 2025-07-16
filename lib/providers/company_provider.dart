import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import '../models/company.dart';

class CompanyProvider extends ChangeNotifier {
  static const String _selectedCompanyKey = 'selected_company_id';
  late final Box<Company> _companyBox;
  late final Box<dynamic> _settingsBox;
  bool _isInitialized = false;
  final ValueNotifier<Company?> _currentCompanyNotifier = ValueNotifier<Company?>(null);

  ValueNotifier<Company?> get currentCompanyNotifier => _currentCompanyNotifier;

  Company? get currentCompany => _currentCompanyNotifier.value;

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
        final company = _companyBox.values.firstWhere(
          (c) => c.key.toString() == companyId.toString(),
        );
        _currentCompanyNotifier.value = company;
        notifyListeners();
      } catch (e) {
        _currentCompanyNotifier.value = null;
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error loading selected company: $e');
    }
  }

  Future<void> setSelectedCompany(Company company) async {
    await _settingsBox.put(_selectedCompanyKey, company.key);
    _currentCompanyNotifier.value = company;
    notifyListeners();
  }

  Future<void> clearSelectedCompany() async {
    await _settingsBox.delete(_selectedCompanyKey);
    _currentCompanyNotifier.value = null;
    notifyListeners();
  }

  void setCurrentCompany(Company company) {
    _currentCompanyNotifier.value = company;
    _settingsBox.put(_selectedCompanyKey, company.key);
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
    if (_currentCompanyNotifier.value?.key == company.key) {
      _currentCompanyNotifier.value = company;
      notifyListeners();
    }
  }

  Future<void> deleteCompany(Company company) async {
    if (_currentCompanyNotifier.value?.key == company.key) {
      await clearSelectedCompany();
    }
    await company.delete();
  }
}
